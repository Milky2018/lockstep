---
name: lockstep
description: Synchronizes every MoonBit module in a moon.work workspace to one exact version and aligns internal workspace dependencies. Use when an agent needs to release or converge a MoonBit multi-module workspace on a single MAJOR.MINOR.PATCH version.
---

# Lockstep

Use Lockstep to synchronize the versions of all modules explicitly listed in a
MoonBit workspace's `moon.work`.

## Quick start

Run from the directory that directly contains `moon.work`:

```sh
moonx Milky2018/lockstep 0.2.0
```

Replace `0.2.0` with the user-requested target version. The target must use
exact `MAJOR.MINOR.PATCH` syntax and cannot be lower than any member's current
version.

## Installed usage

For repeated use, install the executable and invoke it directly:

```sh
moon install Milky2018/lockstep
lockstep 0.2.0
```

The binary is installed to `~/.moon/bin/lockstep` by default.

## Agent workflow

1. Confirm that the current directory directly contains `moon.work`.
2. Obtain an explicit target version from the user; do not infer a bump level.
3. Run Lockstep once for the complete workspace. Do not select a subset of
   members.
4. Report the command's success, no-op, or error output accurately.

Lockstep updates each member's `moon.mod`, then runs `moon work sync` to align
workspace dependency versions. It preserves manifest formatting and restores
the original manifests after normally reported synchronization failures.

Lockstep does not build, test, publish, commit, tag, or push the workspace. Do
not claim those steps were completed unless they were requested and performed
separately.
