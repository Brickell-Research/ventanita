//// Tool definitions offered to the model.

import gleam/json.{type Json}

pub type Tool {
  /// `input_schema` is a JSON Schema object describing the tool's input.
  Tool(name: String, description: String, input_schema: Json)
}

pub fn to_json(tool: Tool) -> Json {
  json.object([
    #("name", json.string(tool.name)),
    #("description", json.string(tool.description)),
    #("input_schema", tool.input_schema),
  ])
}
