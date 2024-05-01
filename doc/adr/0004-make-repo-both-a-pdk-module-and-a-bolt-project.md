# 4. Make repo both a pdk module and a bolt project

Date: 2024-05-01

## Status

Accepted

## Context

This repo uses bolt to connect to vmfloaty VM's.  As a result, creating a plan is very easy using bolt with something like `/opt/puppetlabs/bin/bolt plan new --pp`.  Yet bolt plans are not, of course, the only way to codefy useful behaviours in a project like this; puppet manifest like classes, defines, etc., are also very useful.  Given this then, the `pdk` is a natural fit alongside bolt.  For example with the `pdk` it is easy to validate the code with `pdk validate -a` or create new classes with `pdk new class...`.

## Decision

Therefore, I decided to make this repo not only a bolt project but also a pdk module.

## Consequences

This repo is both a module and a bolt project so code can be created and also validated using the pdk and bolt.  For example, ``pdk new class``, ``pdk validate -a``, ``/opt/puppetlabs/bin/bolt plan new --pp``, etc.
