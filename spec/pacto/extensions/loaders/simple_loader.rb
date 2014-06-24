require 'multi_json'
require 'yaml'
require 'pacto'
require_relative 'yaml_or_json_loader'

class Pacto::Extensions::Loaders::URIMapLoader < Pacto::Extensions::Loaders::YamlOrJsonLoader
  include Pacto::Logger

  def load(file)
    @data = super
  end

  def build_from_file(file, _)
    load(file)
    contracts = []
    @data['services'].each do | group_name, service_group |
      service_group['servers'].each do | server |
        if service_group['services']
          service_group['services'].each_pair do | service_name, service_definition|
            contract = build_simple_contract service_definition, group_name, service_name, server, file
            contracts << contract
          end
        end
      end
    end
    contracts
  end

  private
  def build_simple_contract service_definition, group_name, service_name, server, file
    service_signature = "#{service_definition['method'].upcase} #{service_definition['uriTemplate']}"
    logger.debug "Building contract for '#{service_signature}' as '#{group_name} - #{service_name}' on #{server}"
    # FIXME: What about scheme?
    host = "https://#{server}"
    request_clause = Pacto::RequestClause.new({
      'host'   => host,
      'http_method' => service_definition['method'],
      'headers' => [], #not supporting this yet, probably needs conversion
      'path' => convert_template(service_definition['uriTemplate']),
      'schema' => service_definition['requestSchema'] || {}
    })
    response_clause = Pacto::ResponseClause.new({
      'status' => service_definition['responseStatusCode'] || 200,
      'headers' => [], #not supporting this yet, probably needs conversion
      'schema' => service_definition['responseSchema'] || {}
    })
    Pacto::Contract.new({
      :request  => request_clause,
      :response => response_clause,
      :file     => file,
      :name     => service_name
    })
  end

  def convert_template path
    Addressable::Template.new(path) if path
    # path.gsub(/{(\w+)}/, ':\1') if path
  end
end

Pacto.contract_factory.add_factory :uri_map, Pacto::Extensions::Loaders::URIMapLoader.new
# Usage:
# Pacto.load_contracts 'pacto/rackspace_uri_map.yaml', nil, :uri_map
