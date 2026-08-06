# Buzz LYPES

This fork keeps the official `block/buzz` history available as `upstream` and
uses `lypes/main` as the LYPES integration branch.

## Current LYPES delta

- Cross-owner managed-agent mentions now use the upstream implementation from
  [block/buzz#4913](https://github.com/block/buzz/pull/4913). It supersedes the
  fork's original patch based on
  [block/buzz#2893](https://github.com/block/buzz/pull/2893) and scopes remote
  agents to the current channel and their configured access policy.
- Long-running agent turns publish one durable progress update after the
  configured threshold, independently of ephemeral typing indicators.
- LYPES desktop builds keep their own app identifier, updater policy, deep-link
  scheme, macOS build script, and Windows workflow.

The upstream mention fix covers discovery and routing. It does not by itself
solve every cross-device instance-configuration or duplicate-local-offer case
tracked by [block/buzz#3753](https://github.com/block/buzz/issues/3753).

## Remotes and branches

```text
origin    git@github.com:LYPES-Agency/buzz.git
upstream  git@github.com:block/buzz.git

main        clean fork baseline
lypes/main  LYPES integration and build branch
```

Update the LYPES branch without rewriting its published history:

```bash
git fetch upstream main
git switch lypes/main
git merge upstream/main
just desktop-test
just desktop-check
just desktop-build
git push origin lypes/main
```

When upstream replaces another LYPES-specific behavior, remove the local patch
only after verifying the resulting tree and the real team scenario.

## Build

The LYPES build has a separate macOS application identifier and product name,
so it can be installed alongside the official Buzz app. It also disables the
official updater and uses the `buzz-lypes://` deep-link scheme to avoid taking
ownership of the official app's `buzz://` links.

Build for the current Apple Silicon machine:

```bash
./scripts/build-lypes-desktop.sh
```

Build for Intel macOS:

```bash
./scripts/build-lypes-desktop.sh x86_64-apple-darwin
```

Opt into the much larger local Mesh LLM build only when it is actually needed:

```bash
BUZZ_LYPES_MESH=1 ./scripts/build-lypes-desktop.sh
```

The script packages real release sidecars for agents and produces an unsigned
`.app` and `.dmg` under:

```text
target/lypes/<target>/release/bundle/
```

Unsigned macOS builds are suitable for local testing. Distributing them to
other Macs without Gatekeeper warnings requires a LYPES Apple Developer
certificate and notarization.

### Windows 11

Every push to `lypes/main` automatically builds a 64-bit Windows 11 NSIS
installer in the `Buzz LYPES Windows` GitHub Actions workflow. The artifact
contains the installer and its SHA-256 checksum and remains available for 30
days.

List the latest builds and download one from the command line:

```bash
gh run list \
  --repo LYPES-Agency/buzz \
  --workflow lypes-windows.yml \
  --branch lypes/main

gh run download <run-id> \
  --repo LYPES-Agency/buzz \
  --name <artifact-name> \
  --dir target/lypes/windows
```

The Windows package uses the LYPES product name and identifier and can be
installed without replacing official Buzz. It targets Intel/AMD 64-bit Windows
11 machines; Windows on ARM is not currently packaged.

The installer is currently unsigned. Windows SmartScreen may therefore require
the employee to choose **More info** and then **Run anyway**. Removing that
warning requires a LYPES Authenticode code-signing certificate.

## Mac Mini deployment

The operational installation lives on the LYPES Mac Mini, separate from any
official Buzz installation:

```text
/Users/feliperico/Applications/Buzz LYPES.app
```

The current package is an Apple Silicon (`arm64`) build. After producing a new
artifact, copy the `.dmg` to the Mac Mini, verify its SHA-256 checksum, mount it,
and replace only the `Buzz LYPES.app` bundle. Do not overwrite `Buzz.app`.

## Validation

Before using a new build:

```bash
just desktop-test
just desktop-check
just desktop-build
```

Then verify with two community members:

1. Member A starts an agent and sets access to everyone.
2. The agent and Member B both join the same channel.
3. Member B selects the remote agent from `@` autocomplete.
4. The sent event carries the agent pubkey and the agent responds.
5. Member B's machine does not start another local copy of that agent.
