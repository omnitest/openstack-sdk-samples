$:.unshift File.expand_path('pacto', File.dirname(__FILE__))
require 'yaml'
require 'polytrix'
require 'polytrix/rspec'
require 'helpers/pacto_helper'
require 'pacto/extensions/matchers'
require 'pacto/extensions/hint_loader'

Dir['spec/polytrix/runners/middleware/*.rb'].each do |middleware|
  file = middleware.gsub('spec/', '').gsub('.rb','')
  require file
end

Polytrix.configure do |c|
  c.test_manifest = 'polytrix_tests.yml'
  c.implementor name: 'fog', basedir: 'sdks/fog', git: { repo: 'https://github.com/maxlinc/fog-samples', to: 'sdks/fog' }
  c.implementor name: 'gophercloud', basedir: 'sdks/gophercloud/acceptance', git: { repo: 'https://github.com/maxlinc/gophercloud', branch: 'polytrix', to: 'sdks/gophercloud' }
  c.implementor name: 'jclouds', basedir: 'sdks/jclouds/rackspace', git: { repo: 'https://github.com/maxlinc/jclouds-examples', branch: 'polytrix', to: 'sdks/jclouds' }
  c.implementor name: 'openstack.net', basedir: 'sdks/openstack.net' # Need git repo w/ samples
  c.implementor name: 'php-opencloud', basedir: 'sdks/php-opencloud/samples', git: { repo: 'https://github.com/maxlinc/php-opencloud', branch: 'polytrix', to: 'sdks/php-opencloud' }
  c.implementor name: 'pkgcloud', basedir: 'sdks/pkgcloud/lib/providers/rackspace/', git: { repo: 'https://github.com/maxlinc/pkgcloud-integration-tests/', branch: 'polytrix', to: 'sdks/pkgcloud' }
  c.implementor name: 'pyrax', basedir: 'sdks/pyrax/samples', git: { repo: 'https://github.com/maxlinc/pyrax', branch: 'local_config_file', to: 'sdks/pyrax' }

  # Mimic isn't really ready
  # c.middleware.insert 0, Polytrix::Runners::Middleware::Mimic, {}
  c.middleware.insert 0, Polytrix::Runners::Middleware::Pacto, {}
  c.default_doc_template = 'doc-src/_scenario.rst'
end

Polytrix.validate suite: 'Compute', sample: 'create server' do |challenge|
  detected_services = challenge.plugin_data[:pacto][:detected_services]
  expect(detected_services).to include 'Create Server'
end
