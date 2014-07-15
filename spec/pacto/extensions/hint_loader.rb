require 'multi_json'
require 'yaml'
require 'pacto'

class Pacto::Extensions::HintLoader
  include Pacto::Logger

  def load(file)
    @data = YAML.load(File.read(file))
  end

  def hints_from_file(file)
    load(file)
    @data['hints'].each do | group_name, group_definition |
      services = group_definition.delete('services') || {}
      services.each_pair do | service_name, hint_data|
        hint_data = group_definition.merge hint_data
        add_hint group_name, service_name, hint_data
      end
    end
  end

  private

  def slugify(path)
    path.downcase.gsub(' ', '_')
  end

  def add_hint group_name, service_name, hint_data
    target_file = File.join(slugify(group_name), "#{slugify(service_name)}.json")
    service_signature = "#{hint_data['http_method'].upcase} #{hint_data['uriTemplate']}"
    logger.debug "Building contract for '#{service_signature}' as '#{group_name} - #{service_name}' on #{hint_data['server']}"
    # FIXME: What about scheme?
    host = "https://#{hint_data['server']}"
    Pacto::Generator.configuration.hint "#{group_name} :: #{service_name}", {
      host: host,
      http_method: hint_data['http_method'],
      path: convert_template(hint_data['path']),
      target_file: target_file
    }
  end

  def convert_template path
    Addressable::Template.new(path) if path
    # path.gsub(/{(\w+)}/, ':\1') if path
  end
end
