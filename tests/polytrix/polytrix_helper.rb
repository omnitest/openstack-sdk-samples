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

Polytrix.configuration.default_validator_callback = proc{ |challenge|
  result = challenge[:result]
  expect(result.execution_result.exitstatus).to eq(0)
  detected_services = challenge.spy_data[:pacto][:detected_services]
  expect(detected_services).to_not be_empty
}
