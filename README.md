# Generate bolt inventory from vmfloaty

## Description

This project illustrates how to generate a bolt inventory from a list of vmfloaty VMs.

This repo is both a module and a bolt project so code can be created and also validated using the pdk and bolt.  For example, ``pdk new class``, ``pdk validate -a``, ``/opt/puppetlabs/bin/bolt plan new --pp``, etc.

## Design Decisions

<!-- adrlog -->

* [ADR-0001](doc/adr/0001-automatically-generate-an-ssh-config-file.md) - Automatically generate an ssh config file
* [ADR-0002](doc/adr/0002-use-native-ssh-rather-than-private-keys.md) - Use native_ssh rather than private keys
* [ADR-0003](doc/adr/0003-use-short-hostname-for-bolt-inventory-listing.md) - use short hostname for bolt inventory listing

<!-- adrlogstop -->

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
floaty get redhat-8-x86_64 --service vmpooler
floaty get redhat-8-x86_64 --service vmpooler

# verify existence of the VMs
floaty list --active --json --service vmpooler | jq '.'
 
# generate the bolt inventory from the above vmfloaty inventory
bundle exec ruby generate_inventory.rb 

# verify contents of bolt inventory: it should be a valid bolt inventory file
cat inventory.yaml

# verify contents of the ``.ssh_config``: it should contain valid ssh config for the VMs
cat .ssh_config

# copy the output from below and add it to your ~/.ssh/config (only do this once)
echo "Include ${PWD}/.ssh_config"
```

NOTE:  Anytime you either add or remove vmfloaty VMs, then re-run the ``bundle exec ruby generate_inventory.rb``.  This will ensure the bolt ``inventory.yaml`` and ``.ssh_config`` are consistent with the actual vmfloaty inventory.

## Usage

Before proceeding, verify that vscode ``Remote Explorer`` includes the list of new vmfloaty VMs.

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
  "primary_host": "VMFLOATY_HOSTNAME",

  "console_password": "<SOME_PASSWORD>",
  "dns_alt_names": [ "puppet", "puppet.lab1.puppet.vm", "VMFLOATY_HOSTNAME" ],
  "version": "2021.7.4"
}
➜  peadm_test 

# install the primary
/opt/puppetlabs/bin/bolt plan run peadm::install --inventory inventory.yaml --modulepath ~/modules --params @params.json
```

## Appendix

### Sample vmfloaty inventory json, bolt inventory.yaml, and ssh config

```bash
➜  vmfloaty_bolt git:(development) floaty list --active --json --service vmpooler | jq '.'
{
  "fresh-tragedy": {
    "template": "redhat-8-x86_64-pooled",
    "lifetime": 12,
    "running": 3.02,
    "remaining": 8.98,
    "start_time": "2023-09-18T13:53:32+00:00",
    "end_time": "2023-09-19T01:53:32+00:00",
    "state": "running",
    "ip": "",
    "fqdn": "fresh-tragedy.delivery.puppetlabs.net",
    "host": "pix-jj30-u20.ops.puppetlabs.net",
    "migrated": "true"
  },
  "hanoverian-vasa": {
    "template": "redhat-8-x86_64-pooled",
    "lifetime": 12,
    "running": 3.02,
    "remaining": 8.98,
    "start_time": "2023-09-18T13:53:34+00:00",
    "end_time": "2023-09-19T01:53:34+00:00",
    "state": "running",
    "ip": "",
    "fqdn": "hanoverian-vasa.delivery.puppetlabs.net",
    "host": "pix-jj29-u22.ops.puppetlabs.net",
    "migrated": "true"
  },
  "barbed-might": {
    "template": "redhat-8-x86_64-pooled",
    "lifetime": 12,
    "running": 0.92,
    "remaining": 11.08,
    "start_time": "2023-09-18T15:59:19+00:00",
    "end_time": "2023-09-19T03:59:19+00:00",
    "state": "running",
    "ip": "",
    "fqdn": "barbed-might.delivery.puppetlabs.net",
    "host": "pix-jj28-u21.ops.puppetlabs.net"
  }
}
➜  vmfloaty_bolt git:(development) cat inventory.yaml 
---
targets:
- name: hanoverian-vasa.delivery.puppetlabs.net
  uri: hanoverian-vasa.delivery.puppetlabs.net
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
- name: barbed-might.delivery.puppetlabs.net
  uri: barbed-might.delivery.puppetlabs.net
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
- name: fresh-tragedy.delivery.puppetlabs.net
  uri: fresh-tragedy.delivery.puppetlabs.net
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
➜  vmfloaty_bolt git:(development) cat .ssh_config 
Host >>>>>vmfloaty_VMs<<<<<
Host hanoverian-vasa.delivery.puppetlabs.net
  User root
  IdentityFile <PRIVATE_KEY>
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
Host barbed-might.delivery.puppetlabs.net
  User root
  IdentityFile <PRIVATE_KEY>
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
Host fresh-tragedy.delivery.puppetlabs.net
  User root
  IdentityFile <PRIVATE_KEY>
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
➜  vmfloaty_bolt git:(development) 
```
