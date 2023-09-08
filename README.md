# Generate bolt inventory from vmfloaty

## Description

This project illustrates how to generate a bolt inventory from a list of vmfloaty VMs.

This repo is both a module and a bolt project so code can be created and also validated using the pdk and bolt.  For example, ``pdk new class``, ``pdk validate -a``, ``/opt/puppetlabs/bin/bolt plan new --pp``, etc.

## Pre-requisites

Assumes:

* [vmfloaty](https://github.com/puppetlabs/vmfloaty/blob/main/README.md#example-workflow) is installed and configured.
* [direnv](https://direnv.net/docs/installation.html) is installed
* [rbenv](https://github.com/rbenv/rbenv) is installed and configured.  Ensure that ``rbenv versions`` includes the version specified in the ``.ruby-version`` file; otherwise install it with ``rbenv install <version>``
* [jq](https://jqlang.github.io/jq/) is installed.  This is an optional pre-requisite that formats json output and can be removed from the manual commands below if desired.
* Private key ``~/.ssh/id_rsa-acceptance`` is present and valid, i.e., associated public sshkey is configured on target VMs.

Note also:

* Because of some dependency conflicts, ruby version for this should be kept at ``2.7.0`` until these conflicts are resolved.  The ``.ruby-version`` ensures the correct ruby version is used.

## Setup

The following must be performed before using bolt against the vmfloaty VMs:

```bash
# verify that the rbenv and ruby versions match
rbenv version
ruby --version

# install vmfloaty gem and dependencies
bundle install

# ensure BUNDLE_BIN directory (.direnv/bin) is on the local PATH
cp .envrc.sample .envrc
direnv allow # this only needs to be done once; thereafter, the environment will be loaded automatically

# verify floaty on the local PATH: should return something like /User/../.direnv/bin/floaty
which floaty

# generate a couple floaty VMs
floaty get redhat-8-x86_64
floaty get redhat-8-x86_64

# verify existence of the VMs
floaty list --active --json | jq '.'
 
# save the floaty inventory and verify inventory.json contents
mkdir -p inventory.d/vmfloaty
floaty list --active --json | jq '.' > inventory.d/vmfloaty/inventory.json 
cat inventory.d/vmfloaty/inventory.json 

# generate the bolt inventory from the above vmfloaty inventory
bundle exec ruby generate_inventory.rb 

# verify contents of bolt inventory: it should be a valid bolt inventory file
cat inventory.yaml
```

## Usage

### Verify that bolt works as expected

Bolt should now be available for use against the vmfloaty VMs.  For example the following simple commands should work as expected:

```bash
# verify inventory: it should list all the expected vmfloaty VMs
/opt/puppetlabs/bin/bolt inventory show

# verify connectivity: bolt should run a command against all the VMs successfully
/opt/puppetlabs/bin/bolt command run "hostname -f" --targets=all

# verify basic puppet code will apply on target
/opt/puppetlabs/bin/bolt plan run vmfloaty::hello --targets=all --verbose
```

### Create a new bolt project

```bash
# create a new directory to test puppet code against your new inventory of vmfloaty VM's
mkdir /tmp/peadm_test
cd /tmp/peadm_test

# initialize the bolt project
/opt/puppetlabs/bin/bolt project init peadm_test

# re-use the vmfloaty bolt inventory, i.e., sym link inventory.yaml => <vmfloaty_bolt directory>/inventory.yaml
rm -f inventory.yaml  # remove the default inventory.yaml created by bolt project init
ln -s <FULL_PATH>/vmfloaty_bolt/inventory.yaml inventory.yaml

# verify inventory.yaml is valid: sym link ok? bolt inventory show working?
ls -la
/opt/puppetlabs/bin/bolt inventory show

# add a module that you wish to use, e.g., puppetlabs-peadm as in
➜  peadm_test cat bolt-project.yaml 
---
name: peadm_test
modules:
  - puppetlabs-peadm
➜  peadm_test 

# install the module and its dependencies
/opt/puppetlabs/bin/bolt module install

# notice the new plans that are now available, e.g., ``peadm::install``
/opt/puppetlabs/bin/bolt plan show
```

If you want to continue using the ``pupppetlabs-peadm`` then continue on; otherwise stop and use your own choice of modules.

Refer to the [peadm usage documentation](https://github.com/puppetlabs/puppetlabs-peadm/blob/main/documentation/install.md#usage);

```bash
# create a simple "standard" primary only using the peadm, e.g.,
➜  peadm_test cat params.json 
{
  "primary_host": "<ONE OF THE VMFLOATY HOSTNAMES>",

  "console_password": "<SOME_PASSWORD>",
  "dns_alt_names": [ "puppet", "puppet.lab1.puppet.vm", "rangy-tremor.delivery.puppetlabs.net" ],
  "version": "2021.7.4"
}
➜  peadm_test 

# install the primary
/opt/puppetlabs/bin/bolt plan run peadm::install --inventory inventory.yaml --modulepath ~/modules --params @params.json
```

## Appendix

### Troubleshooting

#### Ruby not using the version specified in ``.ruby-version``

If ``bundle install`` (or other ruby commands even ``floaty``) fails with an error something like below with ``...because current Ruby version is = 2.6.10...``, then the command line may not be picking up the ruby version defined by ``rbenv`` in the ``.ruby-version`` file of ``2.7.0``:

```bash
➜  vmfloaty_bolt git:(development) ✗ bundle install
Your RubyGems version (3.0.3.1) has a bug that prevents `required_ruby_version` from working for Bundler. Any scripts that use `gem install bundler` will break as soon as Bundler drops support for your Ruby version. Please upgrade RubyGems to avoid future breakage and silence this warning by running `gem update --system 3.2.3`
Fetching gem metadata from https://rubygems.org/.........
Resolving dependencies...
Could not find compatible versions

Because voxpupuli-puppet-lint-plugins >= 5.0.0 depends on Ruby >= 2.7.0
  and Gemfile depends on voxpupuli-puppet-lint-plugins ~> 5.0,
  Ruby >= 2.7.0 is required.
So, because current Ruby version is = 2.6.10,
  version solving has failed.
➜  vmfloaty_bolt git:(development) ✗ 
```

One solution may be to re-initialize rbenv on the command-line, e.g., ``eval "$(rbenv init - zsh)"``.  For example,

```bash
➜  vmfloaty_bolt git:(development) ✗ ruby -v
ruby 2.6.10p210 (2022-04-12 revision 67958) [universal.arm64e-darwin22]
➜  vmfloaty_bolt git:(development) ✗ eval "$(rbenv init - zsh)"
➜  vmfloaty_bolt git:(development) ✗ ruby -v
ruby 2.7.0p0 (2019-12-25 revision 647ee6f091) [x86_64-darwin22]
➜  vmfloaty_bolt git:(development) ✗ bundle install
Fetching gem metadata from https://rubygems.org/.........
Resolving dependencies...
Fetching rake 13.0.6
Installing rake 13.0.6
Fetching public_suffix 5.0.3
Fetching awesome_print 1.9.2
...
...
```

### Sample vmfloaty inventory.json and equivalent bolt inventory.yaml

```bash
# show the sample files
  parse_vmfloaty_list_into_bolt_inventory git:(development) ✗ tree sample
sample
├── inventory.d
│   └── vmfloaty
│       └── inventory.json
└── inventory.yaml

3 directories, 2 files

# cat the sample vmfloaty inventory.json
➜  parse_vmfloaty_list_into_bolt_inventory git:(development) ✗ cat sample/inventory.d/vmfloaty/inventory.json 
{
  "beguiling-pap": {
    "template": "redhat-8-x86_64-pooled",
    "lifetime": 12,
    "running": 4.12,
    "remaining": 7.88,
    "start_time": "2023-09-07T15:52:55+00:00",
    "end_time": "2023-09-08T03:52:55+00:00",
    "state": "running",
    "ip": "",
    "fqdn": "beguiling-pap.delivery.puppetlabs.net",
    "host": "pix-jj27-u22.ops.puppetlabs.net"
  },
  "wild-poignancy": {
    "template": "redhat-8-x86_64-pooled",
    "lifetime": 12,
    "running": 1.33,
    "remaining": 10.67,
    "start_time": "2023-09-07T18:40:13+00:00",
    "end_time": "2023-09-08T06:40:13+00:00",
    "state": "running",
    "ip": "",
    "fqdn": "wild-poignancy.delivery.puppetlabs.net",
    "host": "pix-jj29-u19.ops.puppetlabs.net"
  }
}

# cat the equivalent bolt inventory.yaml
➜  parse_vmfloaty_list_into_bolt_inventory git:(development) ✗ cat sample/inventory.yaml 
---
targets:
- name: beguiling-pap.delivery.puppetlabs.net
  uri: beguiling-pap.delivery.puppetlabs.net
  alias: []
  config:
    transport: ssh
    ssh:
      batch-mode: true
      cleanup: true
      connect-timeout: 10
      disconnect-timeout: 5
      load-config: true
      login-shell: bash
      tty: false
      host-key-check: false
      private-key: "~/.ssh/id_rsa-acceptance"
      run-as: root
      user: root
- name: wild-poignancy.delivery.puppetlabs.net
  uri: wild-poignancy.delivery.puppetlabs.net
  alias: []
  config:
    transport: ssh
    ssh:
      batch-mode: true
      cleanup: true
      connect-timeout: 10
      disconnect-timeout: 5
      load-config: true
      login-shell: bash
      tty: false
      host-key-check: false
      private-key: "~/.ssh/id_rsa-acceptance"
      run-as: root
      user: root
➜  parse_vmfloaty_list_into_bolt_inventory git:(development) ✗ 
```
