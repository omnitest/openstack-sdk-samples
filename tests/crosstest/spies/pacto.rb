$: << Dir.pwd
require 'pacto'
require 'pacto/server'
require_relative 'pacto/dashboard_report'

::Pacto.validate!
::Pacto.load_contracts('pacto/swagger', 'https://{server}', :swagger)
WebMock.allow_net_connect!

module Crosstest
  class Skeptic
    module Spies
      class Pacto < Crosstest::Skeptic::Spy
        report :dashboard, DashboardReport

        def initialize(app, server_options = {})
          @app   = app
        end

        def pacto_options(port, scenario)
          {
            port: port,
            strip_dev: true,
            pacto_logger: scenario.logger,
            spy: scenario.logger.debug?,
          }
        end

        def call(scenario)
          test_env_number = scenario.vars['TEST_ENV_NUMBER']
          port = 9900 + test_env_number.to_i
          scenario.vars['OS_AUTH_URL'] = "http://identity.api.rackspacecloud.dev:#{port}/v2.0"
          supervisor = ::Pacto::Server::HTTP.supervise("0.0.0.0", port, pacto_options(port, scenario))
          # supervisor = Reel::Server::HTTP.supervise("0.0.0.0", port, spy: scenario.logger.debug?) do |connection|
          #   # Support multiple keep-alive requests per connection
          #   connection.each_request do |request|
          #     ::Pacto::Reel::RequestHandler.new.handle_request(request, port)
          #   end
          # end

          @app.call(scenario)
          # Hacky - need better Pacto API
          investigations = ::Pacto::InvestigationRegistry.instance.investigations.dup
          ::Pacto::InvestigationRegistry.instance.investigations.clear
          # Unknown services aren't captured in detected services
          detected_services = investigations.map(&:contract).compact.map(&:name)
          Crosstest.logger.info "Services detected: #{detected_services.join ','}"
          scenario.spy_data[:pacto] = {
            detected_services: detected_services,
            investigations: investigations.map do | investigation |
              investigation_to_hash(investigation)
            end
          }
        ensure
          supervisor.terminate unless supervisor.nil?
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
          if content_type.match(/image|octet-stream|audio/) || object.body.bytesize >= 15000
            chksum = Digest::MD5.hexdigest(object.body)
            object.body = "(Omitted large or binary data (md5: #{chksum})"
          end
        end
      end
    end
  end
end
