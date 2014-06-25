$:.unshift File.expand_path('pacto', File.dirname(__FILE__))
require 'yaml'
require 'polytrix'
require 'polytrix/rspec'
require 'helpers/pacto_helper'
require 'pacto/extensions/matchers'
require 'pacto/extensions/loaders/simple_loader'

Dir['spec/polytrix/runners/middleware/*.rb'].each do |middleware|
  file = middleware.gsub('spec/', '').gsub('.rb','')
  require file
end

Polytrix.configure do |c|
  c.test_manifest = 'polytrix_tests.yml'
  c.implementor 'sdks/fog'
  c.implementor 'sdks/gophercloud/acceptance'
  c.implementor 'sdks/jclouds/rackspace'
  c.implementor 'sdks/openstack.net'
  c.implementor 'sdks/php-opencloud/samples'
  c.implementor 'sdks/pkgcloud/lib/providers/rackspace/'
  c.implementor 'sdks/pyrax'

  # Mimic isn't really ready
  # c.middleware.insert 0, Polytrix::Runners::Middleware::Mimic, {}
  c.middleware.insert 0, Polytrix::Runners::Middleware::Pacto, {}
  c.default_doc_template = 'doc-src/_scenario.rst'
end
