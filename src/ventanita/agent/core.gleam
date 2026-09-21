//// A single turn: build a request from the context, send it, run any tools
//// the model asks for, and repeat until it answers. The whole exchange is
//// then folded back into the context.

import gleam/bool
import gleam/json
import gleam/list
import gleam/option.{Some}
import gleam/result
import ventanita/agent/context.{type Context}
import ventanita/agent/tool
import ventanita/anthropic/client
import ventanita/anthropic/error.{type Error}
import ventanita/anthropic/message.{type Block, type Message}
import ventanita/anthropic/models
import ventanita/anthropic/request.{type Request}
import ventanita/anthropic/response
import ventanita/ui

pub type Turn {
  Turn(reply: String, context: Context)
}

pub fn execute_turn(context: Context, prompt: String) -> Result(Turn, Error) {
  step(context, [message.user(prompt)], context.config.max_steps)
}

/// `pending` is this turn's exchange so far; it only joins the history once
/// the turn completes, so a failed turn leaves the context untouched.
fn step(
  context: Context,
  pending: List(Message),
  steps_left: Int,
) -> Result(Turn, Error) {
  use <- bool.guard(steps_left <= 0, Error(error.TooManySteps))
  let step_number = context.config.max_steps - steps_left + 1
  use reply <- result.try(client.send(
    context.config.anthropic_api_key,
    make_request(context, pending),
  ))
  let pending =
    list.append(pending, [message.Message(message.Assistant, reply.content)])

  case reply.stop_reason {
    response.ToolUseRequested -> {
      let results =
        message.Message(
          message.User,
          run_tools(context, reply.content, step_number),
        )
      step(context, list.append(pending, [results]), steps_left - 1)
    }
    _ ->
      Ok(Turn(
        reply: response.text(reply),
        context: context.append(context, pending),
      ))
  }
}

/// Answers every tool call in `content`. Failures become error results the
/// model can see, rather than crashing the turn. Each call is shown
/// to the person watching the run.
pub fn run_tools(
  context: Context,
  content: List(Block),
  step: Int,
) -> List(Block) {
  let tools = available_tools(context)
  list.filter_map(content, fn(block) {
    case block {
      message.ToolUse(id, name, input) -> {
        ui.tool_call(step, name, json.to_string(input))
        Ok(case tool.call(tools, name, input) {
          Ok(output) -> message.ToolResult(id, output, False)
          Error(reason) -> message.ToolResult(id, reason, True)
        })
      }
      _ -> Error(Nil)
    }
  })
}

fn available_tools(context: Context) -> List(tool.Tool) {
  tool.available(context.config.tools, context.config.allowed_access)
}

/// The conversation so far plus this turn's pending messages. Public so the
/// mapping from context to wire format can be tested without a network call.
pub fn make_request(context: Context, pending: List(Message)) -> Request {
  request.Request(
    ..request.new(
      models.to_string(context.config.model),
      context.config.max_tokens,
    ),
    system: Some(context.config.system_prompt),
    messages: context.append(context, pending).history,
    tools: list.map(available_tools(context), tool.to_wire),
  )
}
