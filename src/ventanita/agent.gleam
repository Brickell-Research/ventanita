//// The runtime entry point. Anything that can produce a prompt (the CLI, a
//// cron job, a CI action, an eval harness) triggers the agent by calling
//// `execute`.

import gleam/result
import ventanita/agent/context
import ventanita/agent/core.{type Turn}
import ventanita/anthropic/error

/// Runs one turn. The `Turn` carries the reply plus usage for diagnostics.
pub fn execute(prompt: String) -> Result(Turn, String) {
  use ctx <- result.try(context.new_context())

  core.execute_turn(ctx, prompt)
  |> result.map_error(error.to_string)
}
