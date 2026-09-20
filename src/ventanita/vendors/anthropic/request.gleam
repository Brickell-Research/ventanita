//// The body of a Messages API request.

import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import ventanita/vendors/anthropic/message.{type Message}
import ventanita/vendors/anthropic/tool.{type Tool}

pub type Request {
  Request(
    model: String,
    max_tokens: Int,
    system: Option(String),
    messages: List(Message),
    tools: List(Tool),
  )
}

pub fn new(model: String, max_tokens: Int) -> Request {
  Request(
    model: model,
    max_tokens: max_tokens,
    system: None,
    messages: [],
    tools: [],
  )
}

pub fn to_json(req: Request) -> Json {
  let system = case req.system {
    Some(system) -> [#("system", json.string(system))]
    None -> []
  }
  let tools = case req.tools {
    [] -> []
    tools -> [#("tools", json.array(tools, tool.to_json))]
  }
  json.object(
    list.flatten([
      [
        #("model", json.string(req.model)),
        #("max_tokens", json.int(req.max_tokens)),
      ],
      system,
      [#("messages", json.array(req.messages, message.to_json))],
      tools,
    ]),
  )
}
