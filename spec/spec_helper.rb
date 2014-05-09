$:.unshift File.expand_path('../pacto', File.dirname(__FILE__))
require 'polytrix'
require 'polytrix/rspec'
require 'helpers/pacto_helper'
require 'pacto/extensions/matchers'
require 'pacto/extensions/loaders/simple_loader'
require 'matrix_formatter'

Polytrix.implementors = Dir['sdks/*'].map{ |sdk| Polytrix::Implementor.new :name => File.basename(sdk), :language => 'ruby' }

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

