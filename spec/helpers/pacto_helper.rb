require 'pacto'
require 'pacto/rspec'
require 'pacto_server'
require 'goliath/test_helper'

def test_env_number
  ENV['TEST_ENV_NUMBER'].to_i
end

def pacto_port
  @pacto_port ||= 9900 + test_env_number
end

COVERAGE_FILE = "reports/api_coverage#{test_env_number}.yaml"
PACTO_SERVER = "http://identity.api.rackspacecloud.dev:#{pacto_port}" unless ENV['NO_PACTO']

RSpec.configure do |c|
  c.include Goliath::TestHelper
  c.before(:each)  { Pacto.clear! }
  c.after(:each) { save_coverage }
end

def generate?
  ENV['PACTO_GENERATE'] == 'true'
end

def save_coverage
  data = YAML::load(File.read(COVERAGE_FILE)) if File.exists?(COVERAGE_FILE)
  data ||= {}
  validations = Pacto::ValidationRegistry.instance.validations
  data[example.full_description] = validations.reject{|v| v.contract.nil?}.map{|v| v.contract.name }
  File.open(COVERAGE_FILE, 'w') {|f| f.write data.to_yaml }
end
