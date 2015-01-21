$:.unshift File.expand_path('../../', File.dirname(__FILE__))
require 'yaml'
require 'crosstest'
require 'pacto/extensions/matchers'

Dir['tests/crosstest/spies/*.rb'].each do |middleware|
  file = middleware.gsub('tests/crosstest/', '').gsub('.rb','')
  require file
end

Crosstest.configure do |c|
  # Mimic isn't really ready
  # c.register_spy Crosstest::Skeptic::Spies::Mimic
  c.register_spy Crosstest::Skeptic::Spies::Pacto
end

Crosstest.configuration.default_validator_callback = proc{ |challenge|
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
