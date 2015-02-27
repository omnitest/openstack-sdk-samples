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

#### Adding SDKs

The `omnitest.yaml` file defines the SDKs that should be tested. It's basically just a short YAML file that defines a list of projects that contain OpenStack code samples and their git repos.

Here's the first two entries:

```yaml
---
  projects:
   fog:
    basedir: 'sdks/fog'
    git:
      repo: 'https://github.com/omnitest/fog-samples'
      to: 'sdks/fog'
   gophercloud:
    basedir: 'sdks/gophercloud'
    git:
      repo: 'https://github.com/omnitest/gophercloud-examples'
      to: 'sdks/gophercloud'
```

Once a project has been added you can fetch it via the `omnitest clone` command.

#### Configuring SDKs

Omnitest uses [Psychic](https://github.com/omnitest/psychic) to run tasks and code samples in the project. Psychic tries to guess the best way to handle a task or to run a code sample by following conventions for each programming language, but you may need to put a `psychic.yaml` file in the project to help Psychic determine how to run a certain tasks, find sample code for scenarios, or map input parameters to the input style used by the code sample.

If the project follows common conventions and uses names for code samples that are similar to the names of the scenario then the project may not need a `psychic.yaml` at all. Other projects only need a very brief `psychic.yaml`, like gophercloud:

```yaml
---
options:
  execution_strategy: tokens
tasks:
  bootstrap: go get github.com/rackspace/gophercloud
  run_script: go run {{script_file}}
```

However, some projects don't have code samples that are easily mapped to scenarios. The php-opencloud project has matching names for many scenarios, but some samples have names that differ and need to be mapped manually:

```yaml
---
tasks:
  bootstrap: |-
    #!/bin/bash
    wget --timestamping https://getcomposer.org/installer
    php installer
    php composer.phar update --working-dir .. --no-dev
  run_script: php {{script_file}}
scripts:
  upload file: ObjectStore/upload-object.php
  change metadata:  ObjectStore/update-object-metadata.php
  get file: ObjectStore/get-object.php
  create networked server: Compute/create_server_with_network.php
  create keypair: Compute/create_new_keypair.php
  create load balancer: LoadBalancer/create-lb.php
  secure load balancer: LoadBalancer/blacklist-ip-range.php
  setup ssl: LoadBalancer/ssl-termination.php
  delete load balancer: LoadBalancer/delete-lb.php
options:
  execution_strategy: tokens
```

The pkgcloud project requires complex input for each scenario. It uses positional arguments rather than a key/value based system for input (like environment variables or token substitution) that is more easily driven by the test suite. So the pkgcloud `psychic.yaml` defines the exact order of scenario:

```yaml
---
options:
  # parameter_mode: arguments
scripts:
  create network: compute/extensions/networksv2/createNetwork.js {{cidr}} {{network_label}} rackspace {{RAX_USERNAME}} {{RAX_REGION}}
  create server: compute/createServer.js {{server_name}} {{server_flavor}} {{server_image}} rackspace {{RAX_USERNAME}} {{RAX_REGION}}
  delete server: compute/deleteServer.js {{server_name}} rackspace {{RAX_USERNAME}} {{RAX_REGION}}
  delete  network: compute/extensions/networksv2/deleteNetwork.js {{network_label}} rackspace {{RAX_USERNAME}} {{RAX_REGION}}
  attach volume: compute/attachVolume.js {{server_name}} {{volume_name}} rackspace {{RAX_USERNAME}} {{RAX_REGION}}
  detach volume: compute/extensions/volume-attachments/detachVolume.js {{server_name}} {{volume_name}} rackspace {{RAX_USERNAME}} {{RAX_REGION}}
  create container: storage/createContainer.js {{container_name}} rackspace {{RAX_USERNAME}} {{RAX_REGION}}
  upload file: storage/uploadFile.js {{container_name}} {{remote_file}} {{local_file}} rackspace {{RAX_USERNAME}} {{RAX_REGION}}
  # This appears to be hardcoded...
  upload directory: storage/syncFolder.js rackspace {{RAX_USERNAME}} {{RAX_REGION}}
  get file: storage/downloadFile.js {{container_name}} {{remote_file}} rackspace {{RAX_USERNAME}} {{RAX_REGION}}
  delete container: storage/deleteContainer.js {{container_name}} rackspace {{RAX_USERNAME}} {{RAX_REGION}}
  create load balancer: loadbalancer/createLoadBalancer.js {{loadbalancer_name}} rackspace {{RAX_USERNAME}} {{RAX_REGION}}
  secure load balancer: loadbalancer/addAccessList.js {{loadbalancer_name}} {{access_list_json}} rackspace {{RAX_USERNAME}} {{RAX_REGION}}
  throttle connections: loadbalancer/updateConnectionThrottle.js {{loadbalancer_name}} rackspace {{RAX_USERNAME}} {{RAX_REGION}}
  setup ssl: loadbalancer/enableSSL.js {{loadbalancer_name}} {{keyfile}} {{certificate_file}} {{intermediate_file}} rackspace {{RAX_USERNAME}} {{RAX_REGION}}
  delete load balancer: loadbalancer/deleteLoadBalancer.js {{loadbalancer_name}} rackspace {{RAX_USERNAME}} {{RAX_REGION}}
```

#### Adding scenarios

It's very easy to add a new scenario that you want to track for all SDKs. You simply add it to the `skeptic.yaml` file in this repo. Omnitest uses [Skeptic](https://github.com/omnitest/skeptic) to test each of the projects. Skeptic can be used as a standalone tool for testing code samples in a single project, Omnitest just adds the cross-project reporting.

The `skeptic.yaml` file a list of suites and scenarios, as well as any input parameters that should be passed to the scenarios. You can use ERB to dynamically generate a value for the input parameters.

Here's a snippet:

```yaml
  suites:
    Identity:
      env:
        user: test_user_<%= ENV['SKEPTIC_SEED'] %>
        email: test_<%= ENV['SKEPTIC_SEED'] %>@example.com
        SECONDARY_USER: test_user_<%= ENV['SKEPTIC_SEED'] %>
        SECONDARY_EMAIL: test_<%= ENV['SKEPTIC_SEED'] %>@example.com
      samples:
        - authenticate token
        - add user
        - list users
        - reset api key
        - delete user
    Network:
      env:
        cidr: 192.0.2.0/24
        network_label: test_network_<%= ENV['SKEPTIC_SEED'] %>
        server_name: test_networked_server_<%= ENV['SKEPTIC_SEED'] %>
      samples:
        - create network
        - create networked server # re-use create server?
        - delete server # basically a duplicate of delete server
        - delete network
```

#### Adding validations

Skeptic runs the code sample (via Psychic) and captures the results. Skeptic captures the exit code, stdout, and stderr by default, but this suite also uses a Skeptic plugin that captures all of the service requests being sent to OpenStack. It is captured via [Pacto](https://github.com/thoughtworks/pacto), which maps all the requests to the OpenStack services that were defined in Swagger.

You can validate the result of any given scenario by adding validator callbacks in the `tests/omnitest/*.rb` files. The validator callbacks are scoped by regular expressions to suites and/or scenarios. A single validator may apply to multiple scenarios, and a single scenario may have multiple validators. The validators make it easy to ensure a given scenario called a particular service. They also have full access to all of the service requests that were made and could use Pacto for more detailed assertions to check specific details about the request.

Here's a simple validator callback that ensure a particular service was called:

```rb
require 'omnitest'

Omnitest.validate 'Create server', suite: 'Compute', scenario: 'create server' do |challenge|
  detected_services = challenge.spy_data[:pacto][:detected_services]
  expect(detected_services).to include('Cloud Servers - Create server'), "The 'Cloud servers - Create server' service was not called"
end
```

#### Other ideas

- [Babushka](https://babushka.me)-like syntax for defining test dependencies, so tests that assume a resource already exists can be more easily run in isolation
- Teardown at the end of the suite to delete any cloud resources created by the tests. Perhaps automatic teardown that detects "create requests" that were detected while tests were running and sends a corresponding "delete request" once testing is complete.
- Enhanced definitions of input parameters, perhaps marking restricting code samples to only known parameters and/or marking some parameters as required, so it is easier to do a quick static analysis and see if a code sample appears compatible with the suite before attempting to execute it.
