$: << Dir.pwd
require_relative 'pacto/summary_report'
require 'pacto/pacto_server'
require 'goliath/test_helper'
require 'celluloid/autostart'

module Polytrix
  module Spies
    class PactoActor
      include Singleton
      include Goliath::TestHelper
      include Celluloid
      include Celluloid::Logger
      include Celluloid::Notifications

      # finalizer :stop_server

      def initialize(server_options)
        @time_to_stop = Celluloid::Condition.new
        @started = Celluloid::Condition.new
        @stopped = Celluloid::Condition.new
        start_server
      end

      def start_server
        async.run_server
        @started.wait
      end

      def run_server
        Celluloid::Future.new {
          info "Server is starting..."
          with_pacto do |uri| # stenographer_log_file: File.expand_path('pacto_stenographer.log', env.basedir) do
            info "Server started on #{uri}"
            @started.signal
            @time_to_stop.wait
            info "Stopping..."
          end
        }

        # value = future.value
        # @stopped.signal
        # value
      end

      def stop_server
        info "Server is stopping..."
        @time_to_stop.signal
        # @stopped.wait
        # info "Server stopped"
      end

      private

      def with_pacto(extra_opts = {})
        opts = default_opts.merge(extra_opts)
        result = nil
        puts "Starting Pacto on port #{pacto_port}"
        with_api(PactoServer, opts) do
          EM::Synchrony.defer do
            yield
          end
        end
        result
      end

      def default_opts
        {
          stdout: true,
          log_file: 'pacto.log',
          config: 'pacto/config/pacto_server.rb',
          live: true,
          generate: generate?,
          verbose: true,
          validate: true,
          directory: File.join(Dir.pwd, 'pacto', 'contracts'),
          port: pacto_port
        }
     end
    end

    class Pacto < Polytrix::Spy
      report :dashboard, DashboardReport

      def initialize(app, server_options)
        @app   = app
        @server = Celluloid::Actor[:pacto_server] ||= PactoActor.supervise_as(:pacto_server, server_options)

        # FIXME: Ideal would be to start a Pacto server once
        # @pacto_server = server(PactoServer, server_options.delete(:port) || 9901, server_options)
        # puts "Started Pacto middleware on port #{@pacto_server.port}"
      end

      def call(env)
        # FIXME: Ideal (continued) and clear the Pacto investigation results before each test...
        # with_pacto stenographer_log_file: File.expand_path('pacto_stenographer.log', env.basedir) do
          @app.call(env)
        # end
        # Hacky - need better Pacto API
        contracts = ::Pacto::InvestigationRegistry.instance.investigations.map(&:contract)
        ::Pacto::InvestigationRegistry.instance.investigations.clear
        # Unknown services aren't captured in detected services
        detected_services = contracts.compact.map(&:name)
        puts "Services detected: #{detected_services.join ','}"
        env[:spy_data][:pacto] = {
          :detected_services => detected_services
        }
        # ...
      end
    end
  end
end
