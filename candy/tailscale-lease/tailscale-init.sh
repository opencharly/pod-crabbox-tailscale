#!/bin/sh
# /usr/local/bin/crabbox-tailscale-init — this variant's direct-mode entrypoint.
#
# The base image's PID 1 is `sshd -D` and this variant declares no systemd init,
# so nothing follows the `multi-user.target.wants` link the candy writes:
# enabling `tailscaled.service` is a FILESYSTEM fact, and the daemon never
# started (opencharly/pod-crabbox-tailscale#2).
#
# It starts the daemon through the ONE shared starter the gate also runs, then
# hands over to the base entrypoint UNCHANGED — the inherited `/crabbox` contract
# (inputs, sshd on 2222, readiness hook) is exactly what the base provides.
set -eu

/usr/local/libexec/crabbox/tailscaled-start &

exec /usr/local/bin/crabbox-lease-init
