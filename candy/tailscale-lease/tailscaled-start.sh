#!/bin/sh
# /usr/local/libexec/crabbox/tailscaled-start — the ONE definition of how this
# image starts its daemon.
#
# WHY A HELPER AND NOT AN INLINE INVOCATION: the entrypoint starts the daemon and
# the gate must prove the daemon starts, but a check that repeats the command can
# drift from it — round 1 caught exactly that, a check running
# `tailscaled --tun=userspace-networking` with /tmp paths while the entrypoint
# shipped a different invocation with different paths. The shipped command was
# therefore never executed by any gate. Both callers now run THIS file, so the
# proof and the behaviour cannot diverge.
#
# `--tun=userspace-networking` is REQUIRED, not a convenience: a lease container
# has no /dev/net/tun unless its consumer attaches one, and plain `tailscaled`
# exits on a TUN-less venue — which is the failure this image exists to avoid.
# Userspace networking is also the mode a TSI (libkrun) venue needs.
set -eu

export TS_DEBUG_DISABLE_UDP_GSO=1

mkdir -p /var/lib/tailscale /run/tailscale

exec /usr/bin/tailscaled --tun=userspace-networking \
    --state=/var/lib/tailscale/tailscaled.state \
    --socket=/run/tailscale/tailscaled.sock
