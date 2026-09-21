//// Command line trigger: `gleam run -- [--allow-writes] "your prompt"`.
//// Prints the reply to stdout; on failure prints to stderr and exits
//// non-zero so cron jobs and CI actions can tell. Tools that change things
//// are off unless `--allow-writes` is given.

import argv
import gleam/io
import gleam/list
import gleam/string
import gleam/time/duration
import gleam/time/timestamp
import ventanita/agent
import ventanita/agent/tool.{type Access}
import ventanita/ui

pub fn main() -> Nil {
  case parse(argv.load().arguments) {
    Ok(#(prompt, access)) -> run(prompt, access)
    Error(reason) -> fail(reason)
  }
}

/// Splits the arguments into the prompt and the access the run is granted.
pub fn parse(args: List(String)) -> Result(#(String, List(Access)), String) {
  let #(flags, words) =
    list.partition(args, fn(arg) { arg == "--allow-writes" })
  let access = case flags {
    [] -> [tool.ReadOnly]
    _ -> [tool.ReadOnly, tool.Mutating]
  }
  case words {
    [] -> Error("usage: ventanita [--allow-writes] <prompt>")
    _ -> Ok(#(string.join(words, " "), access))
  }
}

fn run(prompt: String, access: List(Access)) -> Nil {
  let start = timestamp.system_time()
  case agent.execute(prompt, access) {
    Ok(turn) -> {
      let elapsed = timestamp.difference(start, timestamp.system_time())
      ui.section("diagnostics")
      ui.usage(turn.usage, turn.steps, duration.to_seconds(elapsed))
      ui.section("output")
      io.println(turn.reply)
    }
    Error(reason) -> fail("error: " <> reason)
  }
}

fn fail(message: String) -> Nil {
  io.println_error(message)
  halt(1)
}

@external(erlang, "erlang", "halt")
fn halt(status: Int) -> Nil
