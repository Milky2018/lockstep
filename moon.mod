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

version = "0.1.0"

readme = "README.md"

repository = ""

license = "Apache-2.0"

keywords = [ ]

preferred_target = "wasm"

description = ""

import {
  "moonbitlang/moon_config@0.3.14",
  "moonbitlang/async@0.21.1",
  "moonbitlang/x@0.5.1",
}
