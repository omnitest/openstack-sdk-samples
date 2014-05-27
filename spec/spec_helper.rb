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


Dir['spec/polytrix/runners/middleware/*.rb'].each do |middleware|
  file = middleware.gsub('spec/', '').gsub('.rb','')
  require file
end

Polytrix.configure do |c|
  c.test_manifest = 'polytrix.yml'
  Dir['sdks/*'].each { |sdk|
    name = File.basename(sdk)
    lang = infer_lang name
    c.implementor :name => name, :language => lang
  }
  # Mimic isn't really ready
  # c.middleware.insert 0, Polytrix::Runners::Middleware::Mimic, {}
  c.middleware.insert 0, Polytrix::Runners::Middleware::Pacto, {}
  c.default_doc_template = 'doc-src/_scenario.rst'
end

RSpec.configure do |c|
  c.matrix_implementors = Polytrix.implementors.map(&:name)
end

# Will have a better system for this in the future
pacto_expectations = YAML::load(File.read("pacto_expectations.yml"))
pacto_coverage = Hashie::Mash.new

Polytrix.configuration.default_validator_callback = proc{ |challenge|
  result = challenge[:result]
  expect(result.execution_result.exitstatus).to eq(0)

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
