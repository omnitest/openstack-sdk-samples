# OpenStack SDK tests

The polytrix-openstack repo contains a suite of tests that use [Polytrix](https://github.com/rackerlabs/polytrix) and [Pacto](https://github.com/thoughtworks/pacto) to test several OpenStack SDKs.

## Pre-requisites

In order to run the tests you'll need a machine with the necessary pre-requisites installed. The `packer/` folder contains scripts that can be used to create machine images for running tests on Linux. If you want to test locally on OSX or Windows you'll have to manually install the pre-requisites.

### Languages

The test suite itself uses Python (for converting WADL to Swagger) and Ruby (for driving tests).

In addition, you'll need tools installed for each of the target languages being tested:
- Ruby
- Python
- Java
- Node
- PHP
- Go
- .NET

You only need to install the developer tools for the language itself - the test suite will take care of installing project dependencies.

### Infrastructure

The test suite assumes that you have setup the ".dev" pseudo-TLD that always resolves to local host. This is used to proxy requests via a Pacto server so they can be intercepted for testing and monitoring purposes.

This can be easily achieved with [dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) on [OSX](http://passingcuriosity.com/2013/dnsmasq-dev-osx/) or Linux. The [Windows alternatives](http://serverfault.com/questions/539591/how-to-resolve-all-dev-domains-to-localhost-on-windows) are a bit trickier.

## Usage

### CI Behavior

The CI server is setup to run `./scripts/bootstrap` and then `./scripts/cibuild`. You can always re-create the CI behavior by running those two scripts. The instructions below are useful for running a subset of tests.

### Bootstrapping the framework

The `./scripts/bootstrap` script will setup the framework and SDKs for testing. It's commented so please read that script even if you'd prefer to run the commands yourself.

### Running commands on a subset of tests

Most polytrix commands are in the format:
`bundle exec polytrix <action> [TEST_ID|REGEXP|all]`

If you run the command with no argument after the `<action>`, or with "all" then it will invoke the action on each test. If you pass an argument it will be used as a regular expression to match against Test IDs, which are a unique value derived from the test suite, scenario, and SDK names. The `list` and `show` actions can be used to view available Test IDs.

For example:
  - `bundle exec polytrix test` or `bundle exec polytrix test` will run all tests
  - `bundle exec polytrix compute-create_server-fog` will that one specific test
  - `bundle exec polytrix fog` will run all tests for the Fog SDK
  - `bundle exec polytrix "(fog|pyrax)"` will run all tests for either Fog or Pyrax

### Preparing to test

The command `bundle exec polytrix clone` will fetch all the code samples for SDKs from their respective repos.

The command `bundle exec polytrix bootstrap` will install the project dependencies for each SDK though the applicable dependency manager (e.g. bundler, pip or maven).

### Running tests

The command `bundle exec polytrix test` will run all tests. You can also run a subset tests (see "Running commands on a subset of tests").

### Viewing results

The command `bundle exec polytrix list` will give an overview of the test results. The default behavior is to print a colorized table to the console, but you can use the `--format` option to have it format the results as Markdown, YAML, or JSON.

TODO: Image

The command `bundle exec polytrix show` will give a detailed report of test results.

TODO: Image

The command `bundle exec polytrix report dashboard` will generate an HTML report in `reports/dashboard.html` with a table giving an overview of results and links to detailed test results for each test. It will also generate a `reports/pacto.html` report that has an overview of the services detected during testing by the Pacto spy.

TODO: Image(s)

## Adding tests

### Adding SDKs

The SDKs to be tested `polytrix.yml` under the **implementors** section. The definitions of each implementor usually just contains the name and the location of a git repo containing code samples:

```yaml
  implementors:
   fog:
    basedir: 'sdks/fog'
    git:
      repo: 'https://github.com/maxlinc/fog-samples'
      to: 'sdks/fog'
   gophercloud:
    basedir: 'sdks/gophercloud/acceptance'
    git:
      repo: 'https://github.com/maxlinc/gophercloud'
      branch: 'polytrix'
      to: 'sdks/gophercloud'
```

See the Polytrix documentation for additional documentation on configuring implementors.

### Adding test suites/scenarios

The test suites and scenarios that are shared across all SDKs are also defined in `polytrix.yml`, under the **suites** section.

This is a list of tests that should be part of a compliance test suite, and may include options to drive input to tests (via environment variables by defualt):

```yaml
  suites:
    Identity:
      env:
        SECONDARY_USER: test_user_<%= ENV['POLYTRIX_SEED'] %>
        SECONDARY_EMAIL: test_<%= ENV['POLYTRIX_SEED'] %>@example.com
      samples:
        - authenticate token
        - add user
        - list users
        - reset api key
        - delete user
```

### Adding test validations

You can add new test validations by modifying or adding a file under `tests/polytrix`. The validations are defined in Ruby and make use of the [RSpec Expectations](https://relishapp.com/rspec/rspec-expectations/docs) API.

A single validation can be used by multiple tests. The validations are scoped using strings or regular expressions that are matched against the test suite and scenario names to see if they are applicable. A simple definition of a test validation looks like this:

```ruby
Polytrix.validate 'Create server', suite: 'Compute', scenario: 'create server' do |results|
  detected_services = results.spy_data[:pacto][:detected_services]
  expect(detected_services).to include 'Cloud Servers - Create server'
end
```

That expectation uses data captured by the [Pacto](https://github.com/thoughtworks/pacto) spy to make sure the create server code samples are calling the "Cloud Servers - Create Server" service. The names of services should match up with the names used on http://api.rackspace.com/.
