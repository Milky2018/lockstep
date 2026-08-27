# Lockstep

Lockstep keeps the versions of MoonBit modules in one workspace aligned as a single release unit.

## Language

**Release Group**:
All modules explicitly listed in one `moon.work`; they form an indivisible release unit and share one version.
_Avoid_: Selected modules, module subset, independent module versions

**Workspace Root**:
The directory that directly contains the `moon.work` defining a Release Group; Lockstep operations are initiated from this directory.
_Avoid_: Ancestor workspace, inferred workspace, module directory

**Target Version**:
The `MAJOR.MINOR.PATCH` version explicitly supplied for every module in a Release Group; it must not be lower than any member's current version. Pre-release versions, build metadata, ranges, prefixes, and inferred increments are outside this concept.
_Avoid_: Version bump, inferred version, automatic increment

**Workspace Dependency**:
A versioned dependency from one member of a Release Group to another; its requested version must match the Target Version.
_Avoid_: External dependency, registry dependency

**Member Manifest**:
The `moon.mod` file of a Release Group member; it is the source of that module's identity and current version. An omitted version represents `0.0.0`.
_Avoid_: `moon.mod.json`, package manifest

**Synchronization**:
The all-or-nothing convergence of every module and Workspace Dependency in a Release Group to the Target Version, regardless of differing starting versions. A normally reported failure leaves all member manifests unchanged.
_Avoid_: Partial update, best-effort update
