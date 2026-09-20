//// The state a run of the agent carries between turns: static settings and
//// the conversation so far.

import envoy
import gleam/list
import gleam/result
import ventanita/anthropic/message.{type Message}
import ventanita/anthropic/models.{type Model}

pub type Config {
  Config(max_tokens: Int, anthropic_api_key: String, model: Model)
}

pub type Context {
  Context(history: List(Message), config: Config)
}

pub fn new_context() -> Result(Context, String) {
  use api_key <- result.try(
    envoy.get("ANTHROPIC_API_KEY")
    |> result.replace_error("ANTHROPIC_API_KEY is not set"),
  )
  let config =
    Config(
      max_tokens: 1024,
      anthropic_api_key: api_key,
      model: models.Haiku4pt5,
    )

  Ok(Context(history: [], config:))
}

/// Records a completed exchange so the next turn can see it.
pub fn append(context: Context, messages: List(Message)) -> Context {
  Context(..context, history: list.append(context.history, messages))
}
