# A sample Gemfile
source "https://rubygems.org"

gem "rake"
gem "polytrix", :git => "https://github.com/rackerlabs/polytrix.git"
gem "psychic-runner", :git => "https://github.com/polytrix/psychic-runner"
gem "fog"
gem 'celluloid'
gem "pacto", '= 0.4.0.rc1'
gem "pacto-server", '= 0.4.0.rc1'

# group :plugins do
#   gem 'vagrant-rackspace', path: '../vagrant-rackspace'
#   gem 'vagrant', path: '../vagrant'
# end

platform :mswin do
  # https://github.com/eventmachine/eventmachine/pull/497
  gem 'eventmachine', :git => 'https://github.com/eventmachine/eventmachine.git', :branch => 'master'

  # mixlib-shellout dependencies that are specified for 32 but not 64 bit gems
  gem "win32-process", "~> 0.7.1"
  gem "windows-pr", "~> 1.2.2"
end
