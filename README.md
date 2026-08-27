# Lockstep

Lockstep synchronizes the versions of every MoonBit module listed in a
workspace's `moon.work`.

## Usage

Run Lockstep from the directory that directly contains `moon.work`:

```sh
lockstep 0.2.0
```

Lockstep updates every member's `moon.mod`, then runs `moon work sync` to align
workspace dependency versions. The target must use exact `MAJOR.MINOR.PATCH`
syntax and cannot be lower than any member's current version.

The command preserves manifest comments and formatting. If a normally reported
write or `moon work sync` failure occurs, all member manifests are restored to
their original bytes.

## Scope

- Supports the wasm and native backends; wasm is the preferred target.
- Supports `moon.mod`; legacy `moon.mod.json` members are rejected.
- Does not build, test, publish, commit, or tag the workspace.
