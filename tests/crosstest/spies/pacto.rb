$: << Dir.pwd
require_relative 'pacto/dashboard_report'
require 'pacto/server'
require 'pacto/test_helper'
require 'celluloid/autostart'

# Celluloid.task_class = Celluloid::TaskThread

EventMachine.error_handler{ |e|
  puts "Error raised during event loop: #{e.message}"
}

module Crosstest
  module Skeptic
    module Spies
      class PactoWatcher
        include Celluloid
        include Celluloid::Logger
        trap_exit :actor_died

        def initialize
          @pacto = PactoActor.new_link({port: pacto_port})
        end

        def start
          @pacto.start_server
        end

        def stop
          @pacto.stop_server
          @pacto.terminate
        end

        def actor_died(actor, reason)
          warn "Oh no! #{actor.inspect} has died because of a #{reason.class}" if reason
        end
      end

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
            stub: false,
            live: true,
            generate: generate?,
            verbose: true,
            validate: true,
            directory: File.join(Dir.pwd, 'pacto', 'swagger'),
            format: 'swagger',
            port: pacto_port,
            strip_dev: true,
            strip_port: true,
            pacto_logger: Crosstest.logger,
            pacto_log_level: log_level
          }
       end

        def log_level
          ENV.fetch('PACTO_LOG_LEVEL', 'debug').downcase.to_sym
        end
      end

      class Pacto < Crosstest::Skeptic::Spy
        report :dashboard, DashboardReport

        def initialize(app, server_options = {})
          @app   = app
          @pacto_controller = Crosstest::Skeptic::Spies::PactoWatcher.new
          # @server = Celluloid::Actor[:pacto_server] ||= PactoActor.supervise_as(:pacto_server, {port: pacto_port})
          # @crash_handler.link @server.actors.first
        end

        def call(env)
          @pacto_controller.start
          @app.call(env)
          # Hacky - need better Pacto API
          investigations = ::Pacto::InvestigationRegistry.instance.investigations.dup
          ::Pacto::InvestigationRegistry.instance.investigations.clear
          # Unknown services aren't captured in detected services
          detected_services = investigations.map(&:contract).compact.map(&:name)
          puts "Services detected: #{detected_services.join ','}"
          env[:spy_data][:pacto] = {
            detected_services: detected_services,
            investigations: investigations.map do | investigation |
              investigation_to_hash(investigation)
            end
          }
          # ...
        ensure
          @pacto_controller.stop
        end

        private

        def investigation_to_hash(investigation)
          # TODO: This belongs in Pacto - should be serializable as JSON/YAML
          request = ::Pacto::PactoRequest.new(investigation.request.to_hash) # Need to fix WebMock adapter requests to be mutable
          response = investigation.response
          contract = investigation.contract.nil? ? nil : investigation.contract.name
          omit_large_body(request)
          omit_large_body(response)
          Hashie::Mash.new({
            request: request.to_hash,
            response: response.to_hash,
            contract: contract,
            citations: investigation.citations
          }).to_hash
        end

        def omit_large_body(object)
          return if object.body.nil? || object.body.empty?
          object.body = object.body.force_encoding('utf-8') # JSON/YAML should be UTF-8 encoded

          content_type = object.content_type || 'application/octet-stream'
          if object.content_type.match(/image|octet-stream|audio/) || object.body.bytesize >= 15000
            chksum = Digest::MD5.hexdigest(object.body)
            object.body = "(Omitted large or binary data (md5: #{chksum})"
          end
        end
      end
    end
  end
end
