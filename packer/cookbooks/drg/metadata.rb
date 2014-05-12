name              "drg"
maintainer        "Rackspace US, Inc"
maintainer_email  "sdk-support@rackspace.com"
license           "MIT"
description       "Installs tools required for testing Rackspace SDKS."
version           "0.0.1"

depends 'apt'
depends 'python'
depends 'rbenv'
depends 'golang'
depends 'nodejs'
depends 'php'
depends 'java'
depends 'groovy'
depends 'maven'
depends 'dnsmasq'
depends 'ssh_known_hosts'
depends 'users'
depends 'sudo'
depends 'mono'

recipe "drg", "Installs tools required for testing Rackspace SDKS."

%w{ ubuntu }.each do |os|
  supports os
end
