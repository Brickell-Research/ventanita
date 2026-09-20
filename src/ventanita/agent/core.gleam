//// A single turn: build a request from the context, send it, and fold the
//// exchange back into the context.

import gleam/result
import ventanita/agent/context.{type Context}
import ventanita/anthropic/client
import ventanita/anthropic/error.{type Error}
import ventanita/anthropic/message
import ventanita/anthropic/models
import ventanita/anthropic/request.{type Request}
import ventanita/anthropic/response

pub type Turn {
  Turn(reply: String, context: Context)
}

pub fn execute_turn(context: Context, prompt: String) -> Result(Turn, Error) {
  let asked = message.user(prompt)
  use reply <- result.try(client.send(
    context.config.anthropic_api_key,
    make_request(context, asked),
  ))
  let answered = message.Message(message.Assistant, reply.content)

  Ok(Turn(
    reply: response.text(reply),
    context: context.append(context, [asked, answered]),
  ))
}

/// The conversation so far plus the new message. Public so the mapping from
/// context to wire format can be tested without a network call.
pub fn make_request(context: Context, asked: message.Message) -> Request {
  request.Request(
    ..request.new(
      models.to_string(context.config.model),
      context.config.max_tokens,
    ),
    messages: context.append(context, [asked]).history,
  )
}
