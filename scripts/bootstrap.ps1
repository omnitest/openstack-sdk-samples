# Make sure we have bundler, which is used to install the Ruby dependencies of the test framework
gem install bundler --no-ri --no-rdoc

# If using rbenv make sure the shims are update so `which bundle` is successful
# rbenv rehash

# Install the test framework dependencies
bundle update

# Install wadl2swagger
virtualenv polytrix_venv
.\polytrix_venv\Scripts\activate
pip install --upgrade wadl2swagger

# Fetch Swagger definition for all services
# Fetch WADL files
wadlcrawler http://api.rackspace.com/wadls/
# Remove the WADL files we don't need
rm wadls/email-apps-*.wadl # We're not testing mailgun
rm wadls/cloud_monitoring.wadl # This still needs to be cleaned up before it's convertable
# Convert the WADL files to Swagger
$wadls = ls wadls/*.wadl
wadl2swagger $wadls --swagger-dir pacto/swagger/

# Fetch the code samples for each SDK
bundle exec polytrix clone
# Install the dependencies for each SDK
bundle exec polytrix bootstrap
