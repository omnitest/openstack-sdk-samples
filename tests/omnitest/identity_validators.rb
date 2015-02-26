require 'omnitest'

Omnitest.validate 'Identity Authenticate Token', suite: 'Identity', scenario: 'authenticate token' do |challenge|
  detected_services = challenge.spy_data[:pacto][:detected_services]
  expect(detected_services).to include 'Cloud Identity - Authenticate for Admin API'
end
