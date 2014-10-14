require 'polytrix'

Polytrix.validate 'Create server', suite: 'Compute', scenario: 'create server' do |challenge|
  detected_services = challenge.spy_data[:pacto][:detected_services]
  expect(detected_services).to include 'os-compute-2 - Create server'
end
