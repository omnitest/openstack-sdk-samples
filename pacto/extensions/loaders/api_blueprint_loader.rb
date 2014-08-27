require 'multi_json'
require 'yaml'
require 'jsonpath'
require 'pacto'

module Pacto
  module Extensions
    module Loaders
      class APIBlueprintLoader < YamlOrJsonLoader
        def self.load(file)
          data = super
          contracts = []
          resources = JsonPath.on(data, '$..resources[(@.uriTemplate)]')
          resources.each do |resource|
            resource['actions'].each do |action|
              contract = load_action(action, resource, file)
              Pacto.contract_registry.register(contract)
              contracts << contract
            end
          end
          Pacto::ContractList.new contracts
        end

        private

        def self.load_action(action, resource, file)
          # contract_definition = File.read(contract_path)
          # definition = JSON.parse(contract_definition)
          # schema.validate definition
          # request = RequestClause.new(host, definition['request'])
          # response = ResponseClause.new(definition['response'])
          # Contract.new(request, response, contract_path, definition['name'])

          # FIXME: Host info not available in blueprint.
          host = 'http://localhost'
          request_clause = RequestClause.new(host, {
            'method' => action['method'],
            'headers' => [], #not supporting this yet, probably needs conversion
            'path' => resource['uriTemplate']
          })
          response = action['examples'].first['responses'].first
          response_clause = ResponseClause.new({
            'status' => response['name'],
            'headers' => [], #not supporting this yet, probably needs conversion
            'body' => schema_from(response)
          })
          Contract.new(request_clause, response_clause, file, resource['name'])
        end

        def self.schema_from(response)
          schema = response['schema']
          if schema.nil? or schema.empty?
            {}
          else
            MultiJson.load schema
          end
        end
      end
    end
  end
end

# contracts = Pacto::Extensions::Loaders::APIBlueprintLoader.load('pacto/blueprints/otter.json')