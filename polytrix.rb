$:.unshift File.expand_path('pacto', File.dirname(__FILE__))
require 'yaml'
require 'polytrix'
require 'polytrix/rspec'
require 'helpers/pacto_helper'
require 'pacto/extensions/matchers'
require 'pacto/extensions/loaders/simple_loader'

# Quick hack for a demo, need a better way to detect language later
def infer_lang(sdk_name)
  {
    'fog' => 'ruby',
    'gophercloud' => 'go',
    'jclouds' => 'java',
    'openstack.net' => 'c', # should be c#, but see https://github.com/tripit/slate/issues/29
    'php-opencloud' => 'php',
    'pyrax' => 'python',
    'pkgcloud' => 'javascript'
  }[sdk_name]
end


Dir['spec/polytrix/runners/middleware/*.rb'].each do |middleware|
  file = middleware.gsub('spec/', '').gsub('.rb','')
  require file
end

Polytrix.configure do |c|
  c.test_manifest = 'polytrix_tests.yml'
  Dir['sdks/*'].each { |sdk|
    c.implementor sdk
  }
  # Mimic isn't really ready
  # c.middleware.insert 0, Polytrix::Runners::Middleware::Mimic, {}
  c.middleware.insert 0, Polytrix::Runners::Middleware::Pacto, {}
  c.default_doc_template = 'doc-src/_scenario.rst'
end
