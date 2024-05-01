# 2. Use native_ssh rather than private keys

Date: 2024-05-01

## Status

Accepted

## Context

Perforce is moving its VM estate from simple public-key authorization to an ssh-authorization managed service called [smallstep](https://smallstep.com/sso-ssh/).  The simple public key authorization is where (1) a common `~/.ssh/id_rsa-acceptance` private key is shared amongst all engineers; and (2) servers contain this key's public footprint in their `authorized_hosts` file.  This approach will no longer work with servers managed by smallstep.  Additionally, the smallstep approach does not mean that can replace the old key with some new smallstep variant.  In fact, the smallstep authentication process is more complicated using proxy commands, triggering browser logins, etc.  Once a users `~/.ssh/config` is configured for smallstep, then users can easily ssh to managed servers on the command-line and vscode.  For more information about smallstep see the [References section](#references).

Although, my command-line ssh connected fine to the new smallstep server, my bolt `inventory.yaml` stopped working.  Fortunately, bolt contains a configuration parameter called [native-ssh](https://www.puppet.com/docs/bolt/latest/experimental_features#native-ssh-transport) which will use the "native" ssh configuration present on the user's system and this allows my bolt to connect to the new managed servers.

## Decision

Therefore I decided to refactor my `inventory.yml` to use this new `native-ssh` parameter.

## Consequences

This approach has only advantages, as far as I can tell.  The bolt `inventory.yml` is much simpler.  As long as the user has `~/.ssh/config` configured and can ssh onto all required servers, then bolt will work in the same way as the command-line.  There is no longer a requirement to define a path to a private key--which might be different for different servers.  The following diff shows how much neater the new configuration is:

```diff
➜  vmfloaty_bolt git:(development) ✗ git diff generate_inventory.rb 
diff --git a/generate_inventory.rb b/generate_inventory.rb
index 054b618..0fd5431 100755
--- a/generate_inventory.rb
+++ b/generate_inventory.rb
@@ -48,15 +48,11 @@ class InventoryManager
         'config' => {
           'transport' => 'ssh',
           'ssh' => {
-            'batch-mode' => true,
-            'cleanup' => true,
-            'connect-timeout' => 10,
-            'disconnect-timeout' => 5,
+            'native-ssh' => true,
             'load-config' => true,
             'login-shell' => 'bash',
             'tty' => false,
             'host-key-check' => false,
-            'private-key' => '~/.ssh/id_rsa-acceptance',
             'run-as' => 'root',
             'user' => 'root'
           }
➜  vmfloaty_bolt git:(development) ✗ 
```

## References

[^1] [How to get access to IT SysOps Managed Infrastructure via SSH](https://perforce.atlassian.net/wiki/spaces/BTO/pages/431259707/How+to+get+access+to+IT+SysOps+Managed+Infrastructure+via+SSH)
[^2] [SSH Authentication via Smallstep and Azure AD](https://perforce.atlassian.net/wiki/spaces/RE/pages/366686227/SSH+Authentication+via+Smallstep+and+Azure+AD)
[^3] [Backend Docs for Smallstep with Azure AD-based Authentication](https://perforce.atlassian.net/wiki/spaces/RE/pages/366686435/Backend+Docs+for+Smallstep+with+Azure+AD-based+Authentication)
[^4] [Install step](https://smallstep.com/docs/step-cli/installation/#macos)
[^5] [puppetlabs/step-perforce-plugins](https://github.com/puppetlabs/step-perforce-plugins)
