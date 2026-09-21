//// The runtime entry point. Anything that can produce a prompt (the CLI, a
//// cron job, a CI action, an eval harness) triggers the agent by calling
//// `execute`.

import gleam/result
import ventanita/agent/context
import ventanita/agent/core
import ventanita/anthropic/error

pub fn execute(prompt: String) -> Result(String, String) {
  use ctx <- result.try(context.new_context())

  core.execute_turn(ctx, prompt)
  |> result.map(fn(turn) { turn.reply })
  |> result.map_error(error.to_string)
}
