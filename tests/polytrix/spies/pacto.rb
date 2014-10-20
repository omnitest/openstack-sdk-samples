$: << Dir.pwd
require_relative 'pacto/dashboard_report'
require 'pacto/server'
require 'pacto/test_helper'
require 'celluloid/autostart'

module Polytrix
  module Spies
    class PactoActor
      include Singleton
      include ::Pacto::TestHelper
      include Celluloid
      include Celluloid::Logger
      include Celluloid::Notifications

      # finalizer :stop_server

      def initialize(server_options)
        @time_to_stop = Celluloid::Condition.new
        @started = Celluloid::Condition.new
        @stopped = Celluloid::Condition.new
        @server_options = server_options
        start_server
      end

      def start_server
        async.run_server
        @started.wait
      end

      def run_server
        Celluloid::Future.new {
          info "Server is starting..."
          opts = default_opts.merge(@server_options)
          with_pacto(opts) do |uri|
            info "Server started on #{uri}"
            @started.signal
            @time_to_stop.wait
            info "Stopping..."
          end
        }
      end

      def stop_server
        info "Server is stopping..."
        @time_to_stop.signal
      end

      private

      def default_opts
        {
          stdout: true,
          log_file: 'pacto.log',
          live: true,
          generlessate: generate?,
          verbose: true,
          validate: true,
          directory: File.join(Dir.pwd, 'pacto', 'swagger'),
          format: 'swagger',
          port: pacto_port,
          strip_dev: true,
          strip_port: true
        }
     end
    end

    class Pacto < Polytrix::Spy
      report :dashboard, DashboardReport

      def initialize(app, server_options = {})
        @app   = app
        @server = Celluloid::Actor[:pacto_server] ||= PactoActor.supervise_as(:pacto_server, {port: pacto_port})
      end

      def call(env)
        @app.call(env)
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
