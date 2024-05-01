# 3. use short hostname for bolt inventory listing

Date: 2024-05-01

## Status

Accepted

## Context

A typical command in bolt specifies the `--targets` or the hosts on which to run a specific set of commands.  For example, `bolt plan run vmfloaty::test --targets=flaxen-green.vmpooler-prod.puppet.net` will run the `vmfloaty::test` plan on the host `flaxen-green.vmpooler-prod.puppet.net`.  Since this hostname is not only hard to remember but a bit cumbersome to type out, I'd like to shorten the target in the bolt inventory.  

One way to do this is to associate a "name", like `flaxen-green` alongside the required "uri" of `flaxen-green.vmpooler-prod.puppet.net`

## Decision

Therefore, I decided to change `generate_inventory.rb` so that it always creates a short `name` for each target in the bolt inventory.

## Consequences

Now this:

```bash
bolt plan run vmfloaty::test --targets=flaxen-green.vmpooler-prod.puppet.net
```

becomes this:

```bash
bolt plan run vmfloaty::test --targets=flaxen-green
```
