///|
priv struct ManifestPlan {
  current : Version
  updated : String
}

///|
fn config_field(ast : @moon_config.Ast, key : StringView) -> @moon_config.Ast? {
  guard ast is Obj(entries, ..) else { return None }
  for entry in entries {
    let (entry_key, value) = entry
    if entry_key[:] == key {
      return Some(value)
    }
  }
  None
}

///|
fn source_offset(source : String, char_offset : Int) -> Int raise SyncError {
  if char_offset == source[:].char_length() {
    return source.length()
  }
  match source[:].offset_of_nth_char(char_offset) {
    Some(offset) => offset
    None => raise SyncError("invalid source location from moon_config")
  }
}

///|
fn replace_char_range(
  source : String,
  start_char : Int,
  end_char : Int,
  replacement : String,
) -> String raise SyncError {
  let start = source_offset(source, start_char)
  let end = source_offset(source, end_char)
  let result = StringBuilder(size_hint=source.length() + replacement.length())
  result.write_substring(source, 0, start)
  result.write_string(replacement)
  result.write_substring(source, end, source.length() - end)
  result.to_string()
}

///|
fn insert_version_after_name(
  source : String,
  name_ast : @moon_config.Ast,
  target : Version,
) -> String raise SyncError {
  guard name_ast is Str(_, loc~) else {
    raise SyncError("moon_config returned a non-string module name")
  }
  let name_end = source_offset(source, loc.end.cnum)
  let suffix = source[name_end:]
  match suffix.find("\n") {
    Some(relative_newline) => {
      let insertion = name_end + relative_newline + 1
      let newline = if insertion >= 2 && source[insertion - 2] == '\r' {
        "\r\n"
      } else {
        "\n"
      }
      replace_char_range(
        source,
        source[:].char_length() - source[insertion:].char_length(),
        source[:].char_length() - source[insertion:].char_length(),
        "version = \"\{target.to_string()}\"\{newline}",
      )
    }
    None => "\{source}\nversion = \"\{target.to_string()}\"\n"
  }
}

///|
fn plan_moon_mod(
  path : StringView,
  source : String,
  target : Version,
) -> ManifestPlan raise SyncError {
  let (ast, parse_reports) = @moon_config.parse_moon_mod(
    source,
    name=path.to_owned(),
  )
  let validation_reports = @moon_config.validate_moon_mod(ast)
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
  guard config_field(ast, "name") is Some(name_ast) else {
    raise SyncError("invalid `\{path}`: missing module name")
  }
  match config_field(ast, "version") {
    Some(Str(version, loc~)) => {
      let current = parse_current_version(version)
      {
        current,
        updated: replace_char_range(
          source,
          loc.start.cnum,
          loc.end.cnum,
          "\"\{target.to_string()}\"",
        ),
      }
    }
    Some(_) => raise SyncError("invalid `\{path}`: version must be a string")
    None =>
      {
        current: { major: 0, minor: 0, patch: 0, },
        updated: insert_version_after_name(source, name_ast, target),
      }
  }
}
