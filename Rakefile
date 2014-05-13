require 'polytrix'
require 'rspec/core/rake_task'

Dir.glob('tasks/*.rake').each { |r| import r }

# Don't fail quickly, because we may want to publish results even if
# some tests are failing.
RSpec::Core::RakeTask.new('spec') do |t|
  t.fail_on_error = false
end

task :spec => :check_setup
task :default => :spec
