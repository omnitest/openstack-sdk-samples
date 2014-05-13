require 'polytrix'
require 'rspec/core/rake_task'

Dir.glob('tasks/*.rake').each { |r| import r }

RSpec::Core::RakeTask.new('spec')
task :spec => :check_setup
task :default => :spec
