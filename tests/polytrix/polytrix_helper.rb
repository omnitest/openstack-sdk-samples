$:.unshift File.expand_path('../../', File.dirname(__FILE__))
require 'yaml'
require 'polytrix'
require 'helpers/pacto_helper'
require 'pacto/extensions/matchers'

Dir['tests/polytrix/spies/*.rb'].each do |middleware|
  file = middleware.gsub('tests/polytrix/', '').gsub('.rb','')
  require file
end

Polytrix.configure do |c|
  # Mimic isn't really ready
  # c.register_spy Polytrix::Spies::Mimic
  c.register_spy Polytrix::Spies::Pacto
  c.default_doc_template = 'doc-src/_scenario.rst'
end

Polytrix.validate 'Compute creates a server', suite: 'Compute', sample: 'create server' do |challenge|
  detected_services = challenge.spy_data[:pacto][:detected_services]
  expect(detected_services).to include 'Create Server'
end

# Will have a better system for this in the future
pacto_expectations = YAML::load(File.read("pacto_expectations.yml"))
# pacto_coverage = Hashie::Mash.new

Polytrix.configuration.default_validator_callback = proc{ |challenge|
  result = challenge[:result]
  expect(result.execution_result.exitstatus).to eq(0)

  # expected_services = begin
  #   challenge[:spy_data]['pacto']['expected_services'] || []
  # rescue
  #   []
  # end
  expected_services = pacto_expectations[challenge.name] || []

  detected_services = begin
    challenge[:spy_data]['pacto']['detected_services'] || []
  rescue
    []
  end

  expected_services.each do |service|
    expect(Pacto).to have_validated_service 'ignored_namespace', service
    # expect(detected_services).to include service
  end

  # pacto_coverage[challenge.name] ||= Hashie::Mash.new
  # pacto_coverage[challenge.name][example.description] = detected_services.uniq

  # File.open("reports/pacto_coverage.yml", 'wb') do |f| f.write YAML::dump pacto_coverage.to_hash end
}
