import gleam/result
import ventanita/agent/context.{type Context}
import ventanita/vendors/anthropic/client
import ventanita/vendors/anthropic/error
import ventanita/vendors/anthropic/message
import ventanita/vendors/anthropic/models
import ventanita/vendors/anthropic/request.{type Request}
import ventanita/vendors/anthropic/response

pub fn execute_turn(
  context: Context,
  prompt: String,
) -> Result(String, String) {
  use reply <- result.try(
    client.send(context.config.anthropic_api_key, make_request(context, prompt))
    |> result.map_error(error.to_string),
  )

  Ok(response.text(reply))
}

fn make_request(context: Context, prompt: String) -> Request {
  request.Request(
    ..request.new(
      models.to_string(context.config.model),
      context.config.max_tokens,
    ),
    messages: [message.user(prompt)],
  )
}
