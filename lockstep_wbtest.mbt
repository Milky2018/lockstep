///|
test "target versions use strict major.minor.patch syntax" {
  let version = parse_target_version("12.34.56")
  assert_eq(version.major, 12)
  assert_eq(version.minor, 34)
  assert_eq(version.patch, 56)
  for
    invalid in [
      "1.2", "1.2.3.4", "v1.2.3", "01.2.3", "1.02.3", "1.2.03", "1.2.3-beta.1", "1.2.3+build.4",
      "-1.2.3",
    ] {
    try parse_target_version(invalid) catch {
      SyncError(_) => ()
    } noraise {
      _ => fail("expected target version to be rejected: \{invalid}")
    }
  }
}

///|
test "current versions accept valid SemVer suffixes" {
  let prerelease = parse_current_version("1.2.3-beta.1")
  let build = parse_current_version("1.2.3+build.4")
  let both = parse_current_version("1.2.3-rc.1+build.4")
  for version in [prerelease, build, both] {
    assert_eq(version.major, 1)
    assert_eq(version.minor, 2)
    assert_eq(version.patch, 3)
  }
  for invalid in ["bad", "01.2.3", "1.2.3-", "1.2.3+", "1.2.3-01"] {
    try parse_current_version(invalid) catch {
      SyncError(_) => ()
    } noraise {
      _ => fail("expected current version to be rejected: \{invalid}")
    }
  }
}

///|
test "version comparison uses the numeric core" {
  let target = parse_target_version("0.2.0")
  assert_true(parse_current_version("0.1.9") < target)
  assert_false(parse_current_version("0.2.0-beta.1") < target)
  assert_true(target < parse_current_version("0.2.1"))
  assert_true(target < parse_current_version("1.0.0"))
}

///|
test "workspace members preserve their explicit order" {
  let members = workspace_members(
    "moon.work",
    (
      #|members = [
      #|  "./lib",
      #|  "../app",
      #|]
      #|
    ),
  )
  assert_eq(members.length(), 2)
  assert_eq(members[0], "./lib")
  assert_eq(members[1], "../app")
}

///|
test "manifest patch replaces only the version literal" {
  let source =
    #|// Unicode before the location: 中文 😀
    #|name = "alice/core"
    #|
    #|version = "0.1.0" // keep this comment
    #|
    #|description = "keep 0.1.0 here"
    #|
  let plan = plan_moon_mod(
    "core/moon.mod",
    source,
    parse_target_version("0.2.0"),
  )
  assert_eq(plan.current.major, 0)
  assert_eq(plan.current.minor, 1)
  assert_eq(plan.current.patch, 0)
  assert_eq(
    plan.updated,
    (
      #|// Unicode before the location: 中文 😀
      #|name = "alice/core"
      #|
      #|version = "0.2.0" // keep this comment
      #|
      #|description = "keep 0.1.0 here"
      #|
    ),
  )
}

///|
test "manifest patch inserts a missing version after name" {
  let source =
    #|name = "alice/core" // keep this comment
    #|
    #|description = "library"
    #|
  let plan = plan_moon_mod(
    "core/moon.mod",
    source,
    parse_target_version("0.2.0"),
  )
  assert_eq(plan.current.major, 0)
  assert_eq(plan.current.minor, 0)
  assert_eq(plan.current.patch, 0)
  assert_eq(
    plan.updated,
    (
      #|name = "alice/core" // keep this comment
      #|version = "0.2.0"
      #|
      #|description = "library"
      #|
    ),
  )
}

///|
test "manifest patch preserves CRLF line endings" {
  let source = "name = \"alice/core\"\r\nversion = \"0.1.0\"\r\n"
  let plan = plan_moon_mod(
    "core/moon.mod",
    source,
    parse_target_version("0.2.0"),
  )
  assert_eq(plan.updated, "name = \"alice/core\"\r\nversion = \"0.2.0\"\r\n")
}

///|
test "manifest patch preserves module imports" {
  let source =
    #|name = "alice/app"
    #|version = "0.1.0"
    #|import {
    #|  "alice/lib@0.1.0",
    #|}
    #|
  let plan = plan_moon_mod(
    "app/moon.mod",
    source,
    parse_target_version("0.2.0"),
  )
  assert_eq(
    plan.updated,
    (
      #|name = "alice/app"
      #|version = "0.2.0"
      #|import {
      #|  "alice/lib@0.1.0",
      #|}
      #|
    ),
  )
}
