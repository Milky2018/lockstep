// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "Milky2018/lockstep"

version = "0.1.1"

readme = "README.md"

repository = "https://github.com/Milky2018/lockstep"

license = "Apache-2.0"

keywords = [ "bump", "version", "lockstep" ]

preferred_target = "wasm"

supported_targets = "wasm+native"

description = "Synchronize module versions and internal dependencies in a MoonBit workspace."

import {
  "moonbitlang/moon_config@0.3.15",
  "moonbitlang/async@0.21.2",
  "moonbitlang/x@0.5.1",
}
