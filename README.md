# pod-crabbox-tailscale

The **tailnet-joinable CachyOS lease image** for the Crabbox `containerd`
provider — the base [`pod-crabbox`](https://github.com/opencharly/pod-crabbox)
lease contract with the `tailscale` CLI and the `tailscaled` daemon.

## What it provides

Every lease contract property of the base image is inherited unchanged:

| Property | Value |
|---|---|
| Base | `pod-crabbox` (CachyOS), pinned at `v2026.307.1828` |
| SSH | `sshd` on **2222**, public-key only, user `crabbox` |
| Sudo | `crabbox` has passwordless sudo |
| Inputs | read-only `/crabbox`: `authorized_keys`, `lease.env`, `bootstrap.sh` |
| Readiness | `/usr/local/libexec/crabbox/ready` — polled over SSH until exit 0 |
| PID 1 | `/usr/local/bin/crabbox-lease-init` → `exec sshd -D` |

This variant adds the tailnet surface:

| Property | Value |
|---|---|
| CLI | `/usr/bin/tailscale` |
| Daemon | `/usr/bin/tailscaled` — the binary a lease's consumer `exec`s |
| Unit | `tailscaled.service`, enabled at boot |
| TSI workaround | `/etc/systemd/system/tailscaled.service.d/10-tsi-gso.conf` sets `TS_DEBUG_DISABLE_UDP_GSO=1` |

## Why the daemon binary is the point

The plan row is explicit: a lease without `tailscaled` fails
`exec /usr/bin/tailscaled: no such file or directory` before any login. Arch's
`tailscale` package ships both binaries, so this image installs the package and
asserts each path separately.

The drop-in is the libkrunfw TSI workaround. TSI proxies guest socket syscalls
through the VMM; tailscaled's UDP GSO batching deadlocks on that path, and
forcing GSO off is the documented remedy (`CONTAINERD-IMAGES.md` §2,
`LIBKRUN.md` §7). The setting only disables GSO, so a non-TSI lease is
unaffected.

## How to use it

The daemon is baked and its unit is enabled; **joining a tailnet is a runtime
action**, not an image property:

```sh
ssh crabbox@<lease>
# direct mode starts `sshd -D`, so start the daemon explicitly:
sudo tailscaled &
# or, under a systemd lease:
sudo systemctl start tailscaled.service
sudo tailscale up --authkey=tskey-…
tailscale status
```

## Layout

- `charly.yml` — the `pod-crabbox-tailscale` image (pinned base + root entrypoint).
- `candy/tailscale-lease/` — the package, the drop-in, and the `check:` steps.
- `.github/workflows/tag-on-merge.yml` — CalVer tag + `CHANGELOG/` on merge.
- `.github/workflows/image.yml` — builds on `pull_request` and publishes at the
  merge tag, so the image tag equals the git tag.
- `CHANGELOG/` — per-CalVer history.

## Related

- [`opencharly/pod-crabbox`](https://github.com/opencharly/pod-crabbox) — the lease
  base image this one imports.
- [`opencharly/layer-tailscale`](https://github.com/opencharly/layer-tailscale) —
  the Tailscale layer candy the package and unit come from.
- [`CONTAINERD-IMAGES.md`](https://github.com/opencharly/opencharly/blob/main/CONTAINERD-IMAGES.md)
  §2 — the lease-image contract and this image's row.
