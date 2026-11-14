# scripts

Small commands for the RHEL box Gaetan works from (Platform Runbook, Phase 3).
They use the AWS profile `platform` (Identity Center); no AWS key.

| Command          | Does                                              |
|------------------|---------------------------------------------------|
| `platform-start` | Starts `platform-aws-01`, waits until SSH answers |
| `platform-stop`  | Stops `platform-aws-01`, waits until stopped      |

The host also stops by itself at 23:00 Europe/Brussels (`tofu/platform`,
`scheduler.tf`) and, from Phase 4, after 60 minutes idle.

Install:

```sh
install -m 755 scripts/platform-start scripts/platform-stop ~/.local/bin/
```
