require 'pacto'

def token_map
  if File.readable? '.tokens.json'
    MultiJson.load(File.read '.tokens.json')
  else
    {}
  end
end

config[:port] = port
contracts_path = options[:directory] || File.expand_path('contracts', Dir.pwd)
Pacto.configure do |pacto_config|
  pacto_config.logger = logger
  pacto_config.contracts_path = contracts_path
  pacto_config.strict_matchers = options[:strict]
  pacto_config.generator_options = {
    :schema_version => :draft3,
    :token_map => token_map
  }
end

if options[:generate]
  Pacto.generate!
  logger.info 'Pacto generation mode enabled'
end

if options[:validate]
  Pacto.validate! if options[:validate]
  # Dir["#{contracts_path}/*"].each do |host_dir|
  #   host = File.basename host_dir
  #   Pacto.load_contracts(host_dir, "https://#{host}")
  # end
  contracts = Pacto::Extensions::Loaders::URIMapLoader.load(File.absolute_path('pacto/rackspace_uri_map.yaml'))
end

if options[:live]
#  WebMock.reset!
  WebMock.allow_net_connect!
end
