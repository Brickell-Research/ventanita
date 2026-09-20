import gleam/json
import ventanita/anthropic/message

pub fn tool_use_to_json_test() {
  let input = json.object([#("tz", json.string("UTC"))])
  let encoded =
    message.to_json(
      message.Message(message.Assistant, [
        message.ToolUse("toolu_1", "get_time", input),
      ]),
    )

  assert json.to_string(encoded)
    == json.to_string(
      json.object([
        #("role", json.string("assistant")),
        #(
          "content",
          json.preprocessed_array([
            json.object([
              #("type", json.string("tool_use")),
              #("id", json.string("toolu_1")),
              #("name", json.string("get_time")),
              #("input", input),
            ]),
          ]),
        ),
      ]),
    )
}

pub fn tool_result_to_json_test() {
  let encoded =
    message.to_json(
      message.Message(message.User, [
        message.ToolResult("toolu_1", "boom", True),
      ]),
    )

  assert json.to_string(encoded)
    == json.to_string(
      json.object([
        #("role", json.string("user")),
        #(
          "content",
          json.preprocessed_array([
            json.object([
              #("type", json.string("tool_result")),
              #("tool_use_id", json.string("toolu_1")),
              #("content", json.string("boom")),
              #("is_error", json.bool(True)),
            ]),
          ]),
        ),
      ]),
    )
}
