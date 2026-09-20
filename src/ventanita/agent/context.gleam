import envoy
import gleam/result
import ventanita/agent/config.{type AgentConfig, AgentConfig}
import ventanita/vendors/anthropic/models

pub type Context {
  Context(history: List(String), config: AgentConfig)
}

pub fn new_context() -> Result(Context, String) {
  use api_key <- result.try(
    envoy.get("ANTHROPIC_API_KEY")
    |> result.replace_error("ANTHROPIC_API_KEY is not set"),
  )
  let config =
    AgentConfig(
      max_tokens: 1024,
      anthropic_api_key: api_key,
      model: models.Haiku4pt5,
    )

  Ok(Context(history: [], config: config))
}
