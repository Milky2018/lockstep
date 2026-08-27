///|
pub(all) struct SyncSummary {
  module_count : Int
  changed : Bool
}

///|
priv struct ManifestSnapshot {
  path : String
  original : Bytes
  updated : String
}

///|
fn workspace_members(
  path : StringView,
  source : String,
) -> Array[String] raise SyncError {
  let (ast, parse_reports) = @moon_config.parse_moon_work(
    source,
    name=path.to_owned(),
  )
  let validation_reports = @moon_config.validate_moon_work(ast)
  if !parse_reports.is_empty() || !validation_reports.is_empty() {
    let message = StringBuilder()
    message <+ "invalid `\{path}`"
    for report in parse_reports {
      message <+ "\n\{report}"
    }
    for report in validation_reports {
      message <+ "\n\{report}"
    }
    raise SyncError(message.to_string())
  }
  guard config_field(ast, "members") is Some(Arr(entries, ..)) else {
    raise SyncError("invalid `\{path}`: missing workspace members")
  }
  let members = []
  for entry in entries {
    guard entry is Str(member_entry, ..) else {
      raise SyncError("invalid `\{path}`: workspace member must be a string")
    }
    members.push(member_entry)
  }
  if members.is_empty() {
    raise SyncError(
      "invalid `\{path}`: workspace must contain at least one member",
    )
  }
  members
}

///|
fn join_path(base : String, child : String) -> String {
  let child_path : @path.Path = child
  if child_path.is_absolute() {
    child_path.to_string()
  } else {
    let base_path : @path.Path = base
    base_path.join(child_path).to_string()
  }
}

///|
async fn read_manifest(path : String) -> (Bytes, String) {
  try {
    let data = @fs.read_file(path)
    (data.binary(), data.text())
  } catch {
    error => raise SyncError("failed to read `\{path}`: \{error}")
  }
}

///|
async fn collect_snapshots(
  root : String,
  members : ArrayView[String],
  target : Version,
) -> Array[ManifestSnapshot] {
  let snapshots = []
  let seen : Set[String] = Set([])
  for member_entry in members {
    let member_path = @fs.realpath(join_path(root, member_entry)) catch {
      error =>
        raise SyncError(
          "failed to resolve workspace member `\{member_entry}`: \{error}",
        )
    }
    if seen.contains(member_path) {
      raise SyncError("duplicate workspace member `\{member_entry}`")
    }
    seen.add(member_path)
    let manifest_path = join_path(member_path, "moon.mod")
    if !@fs.exists(manifest_path) {
      let legacy_path = join_path(member_path, "moon.mod.json")
      if @fs.exists(legacy_path) {
        raise SyncError(
          "workspace member `\{member_entry}` uses unsupported `moon.mod.json`",
        )
      }
      raise SyncError(
        "workspace member `\{member_entry}` does not contain `moon.mod`",
      )
    }
    let (original, source) = read_manifest(manifest_path)
    let plan = plan_moon_mod(manifest_path, source, target)
    if target < plan.current {
      raise SyncError(
        "target version `\{target.to_string()}` is lower than `\{plan.current.to_string()}` in `\{manifest_path}`",
      )
    }
    snapshots.push({ path: manifest_path, original, updated: plan.updated, })
  }
  snapshots
}

///|
async fn restore_snapshots(
  snapshots : ArrayView[ManifestSnapshot],
) -> String? noraise {
  let failures = []
  for snapshot in snapshots {
    try @fs.write_file(snapshot.path, snapshot.original) catch {
      error => failures.push("`\{snapshot.path}`: \{error}")
    } noraise {
      _ => ()
    }
  }
  if failures.is_empty() {
    None
  } else {
    Some(failures.join("; "))
  }
}

///|
async fn apply_and_sync(
  root : String,
  snapshots : ArrayView[ManifestSnapshot],
) -> Bool {
  try {
    for snapshot in snapshots {
      if snapshot.updated != @fs.read_file(snapshot.path).text() {
        @fs.write_file(snapshot.path, snapshot.updated)
      }
    }
    let (exit_code, output) = @process.collect_output_merged(
      "moon",
      ["-q", "work", "sync"],
      cwd=root,
      extra_env={ "MOON_WORK": join_path(root, "moon.work") },
    )
    if exit_code != 0 {
      let detail = output.text().trim()
      if detail.is_empty() {
        raise SyncError("`moon work sync` failed with exit code \{exit_code}")
      }
      raise SyncError(
        "`moon work sync` failed with exit code \{exit_code}:\n\{detail}",
      )
    }
    let mut changed = false
    for snapshot in snapshots {
      if @fs.read_file(snapshot.path).binary() != snapshot.original {
        changed = true
      }
    }
    changed
  } catch {
    error =>
      match restore_snapshots(snapshots) {
        Some(rollback_error) =>
          raise SyncError(
            "synchronization failed: \{error}; rollback failed: \{rollback_error}",
          )
        None => raise error
      }
  }
}

///|
/// Synchronize every module in the workspace rooted at `root` to `target`.
pub async fn synchronize(root : StringView, target : StringView) -> SyncSummary {
  let target_version = parse_target_version(target)
  let canonical_root = @fs.realpath(root) catch {
    error =>
      raise SyncError("failed to resolve workspace root `\{root}`: \{error}")
  }
  let work_path = join_path(canonical_root, "moon.work")
  if !@fs.exists(work_path) {
    raise SyncError(
      "workspace root does not contain `moon.work`: `\{canonical_root}`",
    )
  }
  let work_source = @fs.read_file(work_path).text() catch {
    error => raise SyncError("failed to read `\{work_path}`: \{error}")
  }
  let members = workspace_members(work_path, work_source)
  let snapshots = collect_snapshots(canonical_root, members, target_version)
  let changed = apply_and_sync(canonical_root, snapshots)
  { module_count: snapshots.length(), changed, }
}
