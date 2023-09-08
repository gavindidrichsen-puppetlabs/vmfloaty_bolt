# @summary A plan to install puppet and verify on target nodes
# @param targets The targets to run on.
plan vmfloaty::hello (
  TargetSpec $targets = 'localhost'
) {
  apply_prep($targets)
  apply($targets) {
    notify { 'Hello World!': }
    include vmfloaty::greeter
  }
}
