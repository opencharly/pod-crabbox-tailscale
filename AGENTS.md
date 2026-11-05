# AGENTS.md — pod-crabbox-tailscale

The **tailnet-joinable lease image** for the Crabbox `containerd` provider: the
`pod-crabbox-tailscale` image (`charly.yml`) and the `tailscale-lease` candy
(`candy/tailscale-lease/`) it composes on top of `opencharly/pod-crabbox`. This
repo owns exactly the tailscale delta — the package, the enabled unit and the
TSI GSO drop-in. The lease contract belongs to the base repo; a change to it
lands there, not here.

Canonical files:

- `charly.yml` — the image: `base: crabbox.pod-crabbox` at a pinned tag,
  `user: root`.
- `candy/tailscale-lease/charly.yml` — the package, the plan steps and the
  `check:` steps.
- `.github/workflows/image.yml` — the image build; it triggers on
  `tag-on-merge` **completion** (`workflow_run`), never on `push: tags`
  (`opencharly/.github#277`: tag-on-merge mints tags through the REST API, which
  emits no push event).
- `.github/workflows/tag-on-merge.yml` — the org's CalVer tag + `CHANGELOG/`
  dispatcher, installed by the org bootstrap.
- `README.md` — user overview only; never agent guidance.

## Load these skills first (R0)

- `/charly-image:image` — the `candy:` image entry (base, user, entrypoint).
- `/charly-image:layer` — the candy body: `distro:` packages, plan step verbs,
  and the `check:` surface.
- `/charly-distros:cachyos` — the CachyOS base and Arch package semantics.
- `/charly-check:check` — the check verbs, the ADE requirement, and the R10 gate.
- `/charly-internals:git-workflow` — before any git/PR action.

## What is unique here

- **The image tag IS the git tag.** `.github/workflows/image.yml` passes the
  newest `v*` tag (minus its `v`) to `charly box build --tag`, which uses a
  supplied tag verbatim. `defaults.tag: auto` is only the LOCAL-build fallback;
  the CI caller always supplies the tag.
- **The base is a pinned import, never copied.** `import: crabbox:
  @github.com/opencharly/pod-crabbox:v2026.307.1828` with `base:
  crabbox.pod-crabbox` builds the base when needed; `--push` publishes only the
  requested box (opencharly/plugin-build#49), so this repo's token never needs
  write access to the base package.
- **Both binaries are asserted, separately.** `tailscale` (CLI) and
  `tailscaled` (daemon) are two checks. The daemon is the load-bearing one: a
  lease whose consumer `exec`s it fails before login when only the CLI shipped.
- **`tailscaled.service` ships from the package.** The candy enables it and
  writes a drop-in; it does not author the unit.
- **The drop-in is a GSO toggle, not a network mode.** `TS_DEBUG_DISABLE_UDP_GSO=1`
  is needed by a libkrun TSI lease and harmless elsewhere; do not make it
  conditional on anything the image cannot observe.
- **Joining a tailnet is runtime.** `tailscale up --authkey=…` is never baked
  into the image and has no build-scope check.

## Build / validate / test

- `charly box validate` at the repo root — the structural check on the image and
  its candy.
- `charly box generate pod-crabbox-tailscale` — inspect the emitted Containerfile
  and the baked `ai.opencharly.description` plan.
- `charly box build pod-crabbox-tailscale` — the local image build.
- `charly check box pod-crabbox-tailscale` — the build-scope `check:` steps.
- The PR image build (`.github/workflows/image.yml`, `pull_request` path) builds
  the image and publishes nothing; the merge-time `workflow_run` path publishes
  `ghcr.io/opencharly/pod-crabbox-tailscale:<git-tag>`.

## Modify this repo

- A package may be added only from a named source (the base candy, an existing
  `layer-*`/`pod-*` repo's Arch section, the provider's docs, or the Arch package
  index). Record the source in a comment.
- Every claim in the plan needs a deterministic `check:`. A package that merely
  installs without a probe is not proof.
- `charly check box` runs only build-context `check:` steps; a claim that needs a
  running daemon belongs in a deploy-context bed, not here.

## Landing

- PR-only. Every change lands through a pull request; the org-required
  `charly/pr-validator` validates the diff and body and arms native auto-merge on
  PASS. Direct pushes to `main` are blocked.
- History lives in `CHANGELOG/` (written by `tag-on-merge` at merge time); the PR
  body IS the changelog.
- The authoritative rulebook is the umbrella `AGENTS.md` in
  `opencharly/opencharly`. Do not restate its rules here.
