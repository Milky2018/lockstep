///|
async fn write_error(message : String) -> Unit {
  @stdio.stderr.write("lockstep: \{message}\n")
}

///|
async fn main {
  let command = @argparse.Command(
    "lockstep",
    about="Synchronize MoonBit workspace module versions.",
    version="0.1.0",
    positionals=[
      PositionArg(
        "target_version",
        about="Target MAJOR.MINOR.PATCH version.",
        num_args=@argparse.ValueRange::single(),
      ),
    ],
  )
  let matches = command.parse() catch {
    error => {
      write_error("\{error}")
      @sys.exit(2)
      abort("unreachable")
    }
  }
  let target = matches.values["target_version"][0]
  guard @env.current_dir() is Some(root) else {
    write_error("failed to determine the current directory")
    @sys.exit(1)
    return
  }
  try synchronize(root, target) catch {
    SyncError(message) => {
      write_error(message)
      @sys.exit(1)
    }
    error => {
      write_error("unexpected error: \{error}")
      @sys.exit(1)
    }
  } noraise {
    summary =>
      if summary.changed {
        println("Synchronized \{summary.module_count} modules to \{target}")
      } else {
        println("Workspace is already synchronized at \{target}")
      }
  }
}
