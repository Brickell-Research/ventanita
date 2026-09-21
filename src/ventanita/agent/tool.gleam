//// The interface every agent tool implements.
////
//// A tool declares what it is (name, description, input schema), what it may
//// do (`Access`), and how to run it. The agent only offers, and will only
//// run, tools that are both registered in the context and permitted by its
//// `allowed_access`; anything else is rejected as an unknown tool.

import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/list
import gleam/result
import gleam/string
import ventanita/anthropic/tool as wire

/// What a tool is allowed to touch.
pub type Access {
  /// Observes the world without changing it.
  ReadOnly
  /// Has side effects (writes files, sends requests, ...).
  Mutating
}

pub type Tool {
  Tool(
    name: String,
    description: String,
    access: Access,
    input_schema: Json,
    /// Type-erased so tools with different input types share one list. `Ok`
    /// is text for the model; `Error` is a message the model can react to.
    run: fn(Json) -> Result(String, String),
  )
}

/// Builds a tool whose handler receives already-decoded, typed input. Input
/// that fails to decode never reaches the handler.
pub fn new(
  name name: String,
  description description: String,
  access access: Access,
  input_schema input_schema: Json,
  decoder decoder: Decoder(input),
  handler handler: fn(input) -> Result(String, String),
) -> Tool {
  Tool(name:, description:, access:, input_schema:, run: fn(raw) {
    json.parse(json.to_string(raw), decoder)
    |> result.map_error(fn(e) { "invalid input: " <> string.inspect(e) })
    |> result.try(handler)
  })
}

/// The tools the agent may use: registered and permitted.
pub fn available(tools: List(Tool), allowed: List(Access)) -> List(Tool) {
  list.filter(tools, fn(tool) { list.contains(allowed, tool.access) })
}

/// Runs the named tool. Names not in `tools` are refused.
pub fn call(
  tools: List(Tool),
  name: String,
  input: Json,
) -> Result(String, String) {
  case list.find(tools, fn(tool) { tool.name == name }) {
    Ok(tool) -> tool.run(input)
    Error(Nil) -> Error("unknown tool: " <> name)
  }
}

pub fn to_wire(tool: Tool) -> wire.Tool {
  wire.Tool(tool.name, tool.description, tool.input_schema)
}
