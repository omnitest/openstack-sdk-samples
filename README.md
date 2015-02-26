# OpenStack SDK tests

The openstack-sdk-samples repo contains a suite of tests that use [Omnitest](https://github.com/omnitest/omnitest) to test code samples for OpenStack SDKs.It generates two reports:
- A matrix showing which code samples are implemented and working for each SDK
- A matrix showing which OpenStack APIs were called by each SDK as part of the tests

## Pre-requisites

Since the suite tests SDKs written in several languages you'll need the tools for the languages themselves insteadd. The suite will generally take care of project level dependencies but assumes you have already installed system-level dependencies. For example, it assumes you already have Ruby installed but will install the Ruby gem for Fog via bundler.

The suite also uses a DNS trick in order to more easily route all of the requests through a "spy" server to capture the OpenStack API calls being made for testing and reporting purposes. It does this by routing the ".dev" pseudo top level domain to localhost, where a reverse proxy will intercept the requests and forward them to the real OpenStack service. This can be easily achieved with [dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) on [OSX](http://passingcuriosity.com/2013/dnsmasq-dev-osx/) or Linux. The [Windows alternatives](http://serverfault.com/questions/539591/how-to-resolve-all-dev-domains-to-localhost-on-windows) are a bit trickier.

The [omnitest-images] repo contains a [packer](https://www.packer.io/) project for building machine images containing all of the prerequisites.

### Setup

You can run the test suite locally or import it into Jenkins with the [Jenkins Job Builder](http://ci.openstack.org/jenkins-job-builder/) configuration in this repo.

#### Manual

The `./scripts/bootstrap` script will prepare the local environment for testing. That script:
- Install the omnitest gem that drives the test suite
- Fetches OpenStack WADLs and converts them to Swagger
- Clones the SDKs defined in `omnitest.yaml`
- Installs the dependencies for each SDK by running the SDK's bootstrap task

#### Jenkins

You can import the suite into Jenkins using [Jenkins Job Builder](http://ci.openstack.org/jenkins-job-builder/). This uses two files:
- Jenkins configuration: You can use `jenkins_jobs.local.ini` for testing on a local Jenkins server. You'll need to provider your own for a remote server.
- Job definitions: The `jenkins_jobs.yaml` file defines the job(s) to be created in Jenkins

You can install on a local Jenkins server by running: `jenkins-jobs --conf jenkins_jobs.local.ini update jenkins_jobs.yaml`

### Testing

The `omnitest` framework provides three executables:
- `omnitask`: Runs a task in each SDK, used to bootstrap the projects
- `omnitest`: Runs tests against each SDK and stores the results
- `omnidoc`: Generates documentation from the code samples in each SDK and/or the test results

#### Full suite

You can run any of these commands to see a help message that shows the available subcommands.

Jenkins uses `./scripts/cibuild` to run the test suite. It runs:
- `bundle exec omnitest test`: This runs all tests in all SDKs
- `bundle exec omnidoc dashboard`: This generates the test results dashboard

#### Isolated testing

The omnitest command gives you a lot of flexibility to run subsets of tests. Most omnitest commands accept two optional arguments:
`omnitest test [PROJECT|REGEXP|all] [SCENARIO|REGEXP|all]`

The first argument selects which projects you want to test, and the second selects which scenarios. Both arguments are optional and default to "all" if omitted. The argument can be either the name of a specific project or scenario, or a regular expression. So you could:

- Execute all Fog samples: `omnitest test fog`
- Execute a single Fog sample: `omnitest test 'create server'`
- Run all compute tests in Fog and pkgcloud: `omnitest test '(fog|pkgcloud) Compute'

### Reports

The omnitest framework provides two sets of reports: command-line and HTML. The command-line reports are useful when you're checking locally and want to quickly check the subset of results. The HTML reports are useful for generating and reviewing a full test report, including when running tests via Jenkins.

The reports are based on information that is stored by omnitest. This data is persisted and aggregated, so you can test each SDK individually and then generate a report that combines all of the results. You can use the `omnitest clear` command if you want to delete the persisted test results and start fresh.

#### Command-line

##### List

The `omnitest list` command gives an overview of the persisted test results. It takes two optional arguments for filtering projects or scenarios, just like other omnitest commands.

You can optionally use the `--source` command to add a column showing a path to the code sample associated with the test (relative to the SDK)

![omnitest list](https://cloud.githubusercontent.com/assets/896878/6403568/ffe956c0-bddd-11e4-9d7e-5d16622350ab.png)

##### Show

The `omnitest show` command displays more detailed results for one or more scenarios. Again, it takes two optional arguments to filter the projects and/or scenarios displayed.

![omnitest show](https://cloud.githubusercontent.com/assets/896878/6403585/325a6f7c-bdde-11e4-9e8e-548b7e8157eb.png)

#### HTML

The `omnidoc` command can produce several reports. The main reports used for this suite are generated by `omnidoc dashboard`. It will produces a `./reports/dashboard.html` and related files.

##### Scenario Matrix

The default panel in `reports/dashboard.html` displays an overview of the results of testing each scenario. It is essentially an HTML version of the `omnitest list` command-line report:

![Scenario Matrix](https://cloud.githubusercontent.com/assets/896878/6403740/84242978-bddf-11e4-9c0c-cf8c474fff39.png)

##### Scenario Details

If you click on the result for any scenario it will bring you to a more detailed report, similar to the `omnitest show` command-line report:

![Scenario Details](https://cloud.githubusercontent.com/assets/896878/6403771/bf6dd3ee-bddf-11e4-9285-71a12619f86b.png)

##### API Matrix

The dashboard also contains a second panel labeled "services". This is a matrix where the rows are OpenStack APIs rather than test scenarios. It shows whether a given API is supported by the SDK or was detected to be used while running a test scenario:

![API Matrix](https://cloud.githubusercontent.com/assets/896878/6403839/35010fc2-bde0-11e4-8564-da35e019c0c8.png)


### Contributing

TODO
- Adding SDKs
- Adding scenarios
- Adding assertions
- Adding reports
- Backlog
