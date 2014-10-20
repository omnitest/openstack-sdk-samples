$:.unshift File.expand_path('../../', File.dirname(__FILE__))
require 'yaml'
require 'polytrix'
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

def test_env_number
  (Thread.current[:test_env_number] || ENV['TEST_ENV_NUMBER']).to_i
end

def pacto_port
  9900 + test_env_number
end

def generate?
  ENV['PACTO_GENERATE'] == 'true'
end
