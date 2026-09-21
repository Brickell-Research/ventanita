//// Command line trigger: `gleam run -- "your prompt"`. Prints the reply to
//// stdout; on failure prints to stderr and exits non-zero so cron jobs and
//// CI actions can tell.

import argv
import gleam/io
import gleam/string
import gleam/time/duration
import gleam/time/timestamp
import ventanita/agent
import ventanita/ui

pub fn main() -> Nil {
  case argv.load().arguments {
    [] -> fail("usage: ventanita <prompt>")
    args -> run(string.join(args, " "))
  }
}

fn run(prompt: String) -> Nil {
  let start = timestamp.system_time()
  case agent.execute(prompt) {
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
