require 'crosstest'

Crosstest.validate 'Create server', suite: 'Compute', scenario: 'create server' do |challenge|
  detected_services = challenge.spy_data[:pacto][:detected_services]
  expect(detected_services).to include('Cloud Servers - Create server'), "The 'Cloud servers - Create server' service was not called"
end
