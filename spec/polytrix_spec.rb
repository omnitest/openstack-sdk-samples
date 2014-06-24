require 'polytrix'
require 'rspec'
require_relative '../polytrix.rb'

RSpec.shared_examples 'polytrix' do
  Polytrix::RSpec.shared_examples(self)
end

Polytrix.load_tests
