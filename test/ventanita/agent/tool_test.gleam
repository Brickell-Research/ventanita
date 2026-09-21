import gleam/dynamic/decode
import gleam/json
import gleam/string
import ventanita/agent/tool

fn shout() -> tool.Tool {
  tool.new(
    name: "shout",
    description: "Uppercases text",
    access: tool.ReadOnly,
    input_schema: json.object([#("type", json.string("object"))]),
    decoder: {
      use text <- decode.field("text", decode.string)
      decode.success(text)
    },
    handler: fn(text) { Ok(string.uppercase(text)) },
  )
}

pub fn new_decodes_input_for_handler_test() {
  let input = json.object([#("text", json.string("hi"))])

  assert tool.call([shout()], "shout", input) == Ok("HI")
}

pub fn new_rejects_invalid_input_test() {
  let assert Error(reason) = tool.call([shout()], "shout", json.object([]))

  assert string.starts_with(reason, "invalid input")
}

pub fn call_unknown_tool_test() {
  assert tool.call([shout()], "other", json.object([]))
    == Error("unknown tool: other")
}

pub fn available_filters_by_access_test() {
  let write = tool.Tool(..shout(), name: "write", access: tool.Mutating)

  assert tool.available([shout(), write], [tool.ReadOnly]) == [shout()]
  assert tool.available([shout(), write], []) == []
}
