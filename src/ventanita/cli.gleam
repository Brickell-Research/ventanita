//// Command line trigger: `gleam run -- "your prompt"`. Prints the reply to
//// stdout; on failure prints to stderr and exits non-zero so cron jobs and
//// CI actions can tell.

import argv
import gleam/io
import gleam/string
import ventanita/agent

pub fn main() -> Nil {
  case argv.load().arguments {
    [] -> fail("usage: ventanita <prompt>")
    args ->
      case agent.execute(string.join(args, " ")) {
        Ok(reply) -> io.println(reply)
        Error(reason) -> fail("error: " <> reason)
      }
  }
}

fn fail(message: String) -> Nil {
  io.println_error(message)
  halt(1)
}

@external(erlang, "erlang", "halt")
fn halt(status: Int) -> Nil
