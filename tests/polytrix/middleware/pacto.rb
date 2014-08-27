require 'pacto/pacto_server'
require 'goliath/test_helper'

module Polytrix
  module Runners
    module Middleware
      class Pacto
        include Goliath::TestHelper

        def initialize(app, server_options)
          @app   = app
          # FIXM: Ideal would be to start a Pacto server once
          # @pacto_server = server(PactoServer, server_options.delete(:port) || 9901, server_options)
          # puts "Started Pacto middleware on port #{@pacto_server.port}"
        end

        def call(env)
          # FIXME: Ideal (continued) and clear the Pacto investigation results before each test...
          with_pacto stenographer_log_file: File.expand_path('pacto_stenographer.log', env.basedir) do
            @app.call(env)
          end
          # Hacky - need better Pacto API
          contracts = ::Pacto::InvestigationRegistry.instance.investigations.map(&:contract)
          # Unknown services aren't captured in detected services
          detected_services = contracts.compact.map(&:name)
          puts "Services detected: #{detected_services.join ','}"
          env[:plugin_data][:pacto] = {
            :detected_services => detected_services
          }
          # ...
        end

        private

        def with_pacto(extra_opts = {})
          opts = default_opts.merge(extra_opts)
          result = nil
          puts "Starting Pacto on port #{pacto_port}"
          with_api(PactoServer, opts) do
            EM::Synchrony.defer do
              result = yield
              EM.stop
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
    end
  end
end
