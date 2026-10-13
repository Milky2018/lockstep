///|
pub(all) suberror SyncError {
  SyncError(String)
}

///|
priv struct Version {
  major : Int32
  minor : Int32
  patch : Int32
} derive(Eq, Compare)

///|
fn Version::to_string(self : Version) -> String {
  "\{self.major}.\{self.minor}.\{self.patch}"
}

///|
fn[T] invalid_version(
  kind : StringView,
  input : StringView,
) -> T raise SyncError {
  raise SyncError("invalid \{kind} version `\{input}`")
}

///|
fn parse_numeric_component(
  kind : StringView,
  input : StringView,
  component : StringView,
) -> Int32 raise SyncError {
  if component.is_empty() ||
    (component.length() > 1 && component[0] == '0') ||
    !component.all(char => char is ('0'..<='9')) {
    return invalid_version(kind, input)
  }
  (@string.from_str(component) : Int32) catch {
    _ => invalid_version(kind, input)
  }
}

///|
fn valid_identifier(
  identifier : StringView,
  numeric_leading_zero~ : Bool,
) -> Bool {
  if identifier.is_empty() {
    return false
  }
  let mut numeric = true
  for char in identifier {
    if !(char is ('0'..<='9' | 'a'..<='z' | 'A'..<='Z' | '-')) {
      return false
    }
    if !(char is ('0'..<='9')) {
      numeric = false
    }
  }
  !(numeric_leading_zero &&
  numeric &&
  identifier.length() > 1 &&
  identifier[0] == '0')
}

///|
fn valid_identifiers(value : StringView, numeric_leading_zero~ : Bool) -> Bool {
  for identifier in value.split(".") {
    if !valid_identifier(identifier, numeric_leading_zero~) {
      return false
    }
  }
  true
}

///|
fn parse_semver_core(
  kind : StringView,
  input : StringView,
  allow_suffix~ : Bool,
) -> Version raise SyncError {
  let (without_build, build) = match input.split_once("+") {
    Some((core, build)) => (core, Some(build))
    None => (input, None)
  }
  if build is Some(value) &&
    (
      !allow_suffix ||
      value.contains("+") ||
      !valid_identifiers(value, numeric_leading_zero=false)
    ) {
    return invalid_version(kind, input)
  }
  let (core, prerelease) = match without_build.split_once("-") {
    Some((core, prerelease)) => (core, Some(prerelease))
    None => (without_build, None)
  }
  if prerelease is Some(value) &&
    (!allow_suffix || !valid_identifiers(value, numeric_leading_zero=true)) {
    return invalid_version(kind, input)
  }
  let parts = core.split(".").to_array()
  if parts.length() != 3 {
    return invalid_version(kind, input)
  }
  {
    major: parse_numeric_component(kind, input, parts[0]),
    minor: parse_numeric_component(kind, input, parts[1]),
    patch: parse_numeric_component(kind, input, parts[2]),
  }
}

///|
fn parse_target_version(input : StringView) -> Version raise SyncError {
  parse_semver_core("target", input, allow_suffix=false)
}

///|
fn parse_current_version(input : StringView) -> Version raise SyncError {
  parse_semver_core("current", input, allow_suffix=true)
}
