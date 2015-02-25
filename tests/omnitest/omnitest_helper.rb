$:.unshift File.expand_path('../../', File.dirname(__FILE__))
require 'yaml'
require 'omnitest'
require 'pacto/extensions/matchers'

Dir['tests/omnitest/spies/*.rb'].each do |middleware|
  file = middleware.gsub('tests/omnitest/', '').gsub('.rb','')
  require file
end

ENV.each_pair do |key, value|
  # All the SDKs use RAX_* environment variables, except
  # Gophercloud which uses RS_*
  if key =~ /RAX/
    ENV[key.gsub('RAX', 'RS')] = value
  end
end

Crosstest.configure do |c|
  # Mimic isn't really ready
  # c.skeptic.register_spy Crosstest::Skeptic::Spies::Mimic
  c.skeptic.register_spy Crosstest::Skeptic::Spies::Pacto
  c.skeptic.default_validator_callback = proc{ |challenge|
    result = challenge.result
    expect(result.execution_result.exitstatus).to eq(0)
    detected_services = challenge.spy_data[:pacto][:detected_services]
    expect(detected_services).to_not be_empty
  }
end

def generate?
  ENV['PACTO_GENERATE'] == 'true'
end
