require 'polytrix'

Polytrix.validate 'Identity Authenticate Token', suite: 'Compute', sample: 'create server' do |challenge|
  detected_services = challenge.plugin_data[:pacto][:detected_services]
  expect(detected_services).to include 'os-compute-2 - Create server'
end
