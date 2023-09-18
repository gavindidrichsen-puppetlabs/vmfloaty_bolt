# 1. Automatically generate an ssh config file

Date: 2023-09-18

## Status

Accepted

## Context

The motivation for this decision is the following use case: As a developer using vscode, I want to have instant ssh access to the vmfloaty VMs using my vscode remote ssh connector.

## Decision

Therefore, (1) the application will generate a local ssh config file for the current list of vmfloaty VMs, and (2) the user will update the global ssh config.  For example, one way of proceeding is as follows:

* Generate the local ``.ssh_config`` by the executing the ``generate_inventory.rb`` 
* Add an ``Include </full/path/to/.ssh_config`` to ``~/.ssh/config``.

## Consequences

One consequence of the above is easier management of vscode remote server lists:  this list will not only include the current set of vfloaty VMs but also dynamically update, after re-running ``generate_inventory.rb``, if new VMs are added or removed.
