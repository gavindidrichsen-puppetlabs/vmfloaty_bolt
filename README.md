# Generate bolt inventory from vmfloaty

## Outstanding

* Codefy the selection, download, and verification of pdk release from jenkins build machine, i.e., <http://builds.delivery.puppetlabs.net/pdk/3.0.0.0/artifacts/el/8/products/x86_64/>

## Description

This project illustrates how to generate a bolt inventory from a list of vmfloaty VMs.

## Pre-requisites

Assumes:

* [vmfloaty](https://github.com/puppetlabs/vmfloaty/blob/main/README.md#example-workflow) is installed and configured.
* [direnv](https://direnv.net/docs/installation.html) is installed
* [rbenv](https://github.com/rbenv/rbenv) is installed and configured.  Ensure that ``rbenv versions`` includes the version specified in the ``.ruby-version`` file; otherwise install it with ``rbenv install <version>``
* [jq]() is installed.  This is an optional pre-requisite that formats json output and can be removed from the manual commands below if desired.

Note also:

* Because of some dependency conflicts, ruby version for this should be kept at ``2.7.0`` until these conflicts are resolved.  The ``.ruby-version`` ensures the correct ruby version is used.

## Setup

The following must be performed before using bolt against the vmfloaty VMs:

* bundle install has been performed
* ssh config of ????  See my ssh config setup
* ``bundle exec generate_inventory.rb`` has been run
* rbenv installed; current ``.ruby-version`` set to 3.2.0.  If not installed on system then ``rbenv install 3.2.0``

```bash
# install vmfloaty gem and dependencies
bundle install

# ensure BUNDLE_BIN directory (.direnv/bin) is on the local PATH
direnv allow # this only needs to be done once; thereafter, the environment will be loaded automatically

# verify floaty on the local PATH: should return something like /User/../.direnv/bin/floaty
which floaty

# generate a couple floaty VMs
floaty get redhat-8-x86_64
floaty get redhat-8-x86_64

# verify existence of the VMs
floaty list --active --json | jq '.'
 
# save the floaty inventory and very contents
mkdir -p inventory.d/vmfloaty
floaty list --active --json | jq '.' > inventory.d/vmfloaty/inventory.json 
cat inventory.d/vmfloaty/inventory.json 

# initialize the current directory as a bolt project, e.g.,
/opt/puppetlabs/bin/bolt project init vmfloaty
 
# generate the bolt inventory from the above vmfloaty inventory
bundle exec ruby generate_inventory.rb 

# verify contents of bolt inventory: it should be a valid bolt inventory file
cat inventory.yaml
```

## Usage

Bolt should now be available for use against the vmfloaty VMs.  For example the following simple commands should work as expected:

```bash
# verify inventory: it should list all the expected vmfloaty VMs
/opt/puppetlabs/bin/bolt inventory show

# verify connectivity: bolt should run a command against all the VMs successfully
/opt/puppetlabs/bin/bolt command run "hostname -f" --targets=all

# verify basic puppet code will apply on target
/opt/puppetlabs/bin/bolt plan run vmfloaty::hello --targets=all --verbose
```

## Appendix

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
