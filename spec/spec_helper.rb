$:.unshift File.expand_path('../pacto', File.dirname(__FILE__))
require 'yaml'
require 'polytrix'
require 'polytrix/rspec'
require 'helpers/pacto_helper'
require 'pacto/extensions/matchers'
require 'pacto/extensions/loaders/simple_loader'
require 'matrix_formatter'

# Quick hack for a demo, need a better way to detect language later
def infer_lang(sdk_name)
  {
    'fog' => 'ruby',
    'gophercloud' => 'go',
    'jclouds' => 'java',
    'openstack.net' => 'c', # should be c#, but see https://github.com/tripit/slate/issues/29
    'php-opencloud' => 'php',
    'pyrax' => 'python',
    'pkgcloud' => 'javascript'
  }[sdk_name]
end

Polytrix.implementors = Dir['sdks/*'].map{ |sdk|
  name = File.basename(sdk)
  lang = infer_lang name
  Polytrix::Implementor.new :name => name, :language => lang
}

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
  c.include Polytrix::RSpec::Helper
end

require 'polytrix/runners/middleware/pacto'
Polytrix.configure do |c|
  c.middleware.insert 0, Polytrix::Runners::Middleware::Pacto, {}
end

RSpec.configure do |c|
  c.matrix_implementors = Polytrix.implementors.map(&:name)
  c.treat_symbols_as_metadata_keys_with_true_values = true
  c.include Polytrix::RSpec::Helper
end

# Will have a better system for this in the future
pacto_expectations = YAML::load(File.read("pacto_expectations.yml"))
pacto_coverage = Hashie::Mash.new

Polytrix.default_validator_callback = proc{ |challenge|
  result = challenge[:result]
  expect(result.process.exitstatus).to eq(0)

  # expected_services = begin
  #   challenge[:plugin_data]['pacto']['expected_services'] || []
  # rescue
  #   []
  # end
  expected_services = pacto_expectations[challenge.name] || []

  detected_services = begin
    challenge[:plugin_data]['pacto']['detected_services'] || []
  rescue
    []
  end

  expected_services.each do |service|
    expect(Pacto).to have_validated_service 'ignored_namespace', service
    # expect(detected_services).to include service
  end

  pacto_coverage[challenge.name] ||= Hashie::Mash.new
  pacto_coverage[challenge.name][example.description] = detected_services.uniq

  File.open("reports/pacto_coverage.yml", 'wb') do |f| f.write YAML::dump pacto_coverage.to_hash end
}
