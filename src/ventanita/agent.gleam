import gleam/result
import ventanita/agent/context
import ventanita/agent/core
import ventanita/anthropic/error

pub fn execute() -> Result(String, String) {
  use ctx <- result.try(context.new_context())

  core.execute_turn(ctx, "say hello like a pirate")
  |> result.map(fn(turn) { turn.reply })
  |> result.map_error(error.to_string)
}
