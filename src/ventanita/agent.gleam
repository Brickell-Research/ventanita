import gleam/result
import ventanita/agent/context.{new_context}
import ventanita/agent/core.{execute_turn}

pub fn execute() -> Result(String, String) {
  use context <- result.try(new_context())

  execute_turn(context, "say hello like a pirate")
}
