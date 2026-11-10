#!/bin/sh
# /usr/local/bin/crabbox-tailscale-init — this variant's direct-mode entrypoint.
#
# WHY IT EXISTS. The base image's PID 1 is `sshd -D`, and this variant declares
# no systemd init, so nothing ever follows the `multi-user.target.wants` link
# the candy writes. Enabling `tailscaled.service` is a FILESYSTEM fact; with no
# systemd as PID 1 the daemon never starts, and a consumer that expects a mesh
# on a lease in this image's declared mode has no daemon to join with
# (opencharly/pod-crabbox-tailscale#2).
#
# WHAT IT DOES, in order:
#   1. exports the TSI workaround into the DAEMON'S OWN environment. The systemd
#      drop-in the candy writes only reaches a unit started by systemd; this
#      entrypoint starts the daemon directly, so the variable is set here. Both
#      paths must carry it — the drop-in for a systemd venue, this export for
#      the direct venue this image declares.
#   2. starts `tailscaled` in the background, with an explicit state and socket
#      path so it does not depend on a directory systemd would have created.
#   3. hands over to the base entrypoint UNCHANGED, which applies the read-only
#      `/crabbox` inputs and `exec`s sshd. The inherited lease contract is
#      exactly what the base provides — this script adds a daemon, nothing else.
#
# The daemon starts BEFORE the inputs are applied on purpose: it needs no lease
# input, and a consumer polling `tailscale status` must not race the SSH
# listener coming up.
set -eu

export TS_DEBUG_DISABLE_UDP_GSO=1

mkdir -p /var/lib/tailscale /run/tailscale

/usr/bin/tailscaled \
    --state=/var/lib/tailscale/tailscaled.state \
    --socket=/run/tailscale/tailscaled.sock &

exec /usr/local/bin/crabbox-lease-init
