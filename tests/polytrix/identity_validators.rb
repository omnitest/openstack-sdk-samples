require 'polytrix'

Polytrix.validate 'Identity Authenticate Token', suite: 'Identity', sample: 'authenticate token' do |challenge|
  detected_services = challenge.plugin_data[:pacto][:detected_services]
  expect(detected_services).to include 'identity-admin :: Authenticate for Admin API'
end
