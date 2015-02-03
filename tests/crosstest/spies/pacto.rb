$: << Dir.pwd
require 'pacto'
require 'reel'
require_relative 'pacto/dashboard_report'

::Pacto.validate!
::Pacto.load_contracts('pacto/swagger', 'https://{server}', :swagger)
WebMock.allow_net_connect!

module Pacto
  module Reel
    class RequestHandler
      def handle_request(reel_request)
        pacto_request =  Pacto::PactoRequest.new(
          headers: reel_request.headers, body: reel_request.read,
          method: reel_request.method, uri: Addressable::URI.heuristic_parse(reel_request.uri)
        )

        prepare_to_forward(pacto_request)
        pacto_response = forward(pacto_request)
        prepare_to_respond(pacto_response)

        puts 'responding'
        reel_response = ::Reel::Response.new(pacto_response.status, pacto_response.headers, pacto_response.body)
        reel_request.respond(reel_response)
      end

      def prepare_to_forward(pacto_request)
        host = pacto_request.uri.site || pacto_request.headers['Host']
        host.gsub!('.dev', '.com')
        scheme, host = host.split('://')
        host, scheme = scheme, host if host.nil?
        host, _port = host.split(':')
        scheme ||= 'https'
        pacto_request.uri = Addressable::URI.heuristic_parse("#{scheme}://#{host}#{pacto_request.uri.to_s}")
        pacto_request.headers.delete_if { |k, _v| %w(host content-length transfer-encoding).include? k.downcase }
      end

      def forward(pacto_request)
        puts 'forwarding'
        Pacto::Consumer::FaradayDriver.new.execute(pacto_request)
      end

      def prepare_to_respond(pacto_response)
        pacto_response.headers.delete_if { |k, _v| %w(connection content-encoding content-length transfer-encoding).include? k.downcase }
      end
    end
  end
end


# Celluloid.task_class = Celluloid::TaskThread

module Crosstest
  class Skeptic
    module Spies
      class Pacto < Crosstest::Skeptic::Spy
        report :dashboard, DashboardReport

        def initialize(app, server_options = {})
          @app   = app
        end

        def call(scenario)
          test_env_number = scenario.vars['TEST_ENV_NUMBER']
          port = 9900 + test_env_number.to_i
          scenario.vars['OS_AUTH_URL'] = "http://identity.api.rackspacecloud.dev:#{port}/v2.0"
          supervisor = Reel::Server::HTTP.supervise("0.0.0.0", port, spy: scenario.logger.debug?) do |connection|
            # Support multiple keep-alive requests per connection
            connection.each_request do |request|
              ::Pacto::Reel::RequestHandler.new.handle_request(request)
            end
          end

          @app.call(scenario)
          # Hacky - need better Pacto API
          investigations = ::Pacto::InvestigationRegistry.instance.investigations.dup
          ::Pacto::InvestigationRegistry.instance.investigations.clear
          # Unknown services aren't captured in detected services
          detected_services = investigations.map(&:contract).compact.map(&:name)
          puts "Services detected: #{detected_services.join ','}"
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
          if object.content_type.match(/image|octet-stream|audio/) || object.body.bytesize >= 15000
            chksum = Digest::MD5.hexdigest(object.body)
            object.body = "(Omitted large or binary data (md5: #{chksum})"
          end
        end
      end
    end
  end
end
