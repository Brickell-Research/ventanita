import gleam/json
import simplifile
import ventanita/anthropic/message
import ventanita/anthropic/response

fn fixture(name: String) -> String {
  let assert Ok(body) = simplifile.read("test/fixtures/" <> name <> ".json")
  body
}

pub fn parse_text_response_test() {
  let assert Ok(resp) = response.from_json(fixture("text_response"))

  assert response.text(resp) == "Hello there"
  assert resp.stop_reason == response.EndTurn
  assert resp.usage == response.Usage(10, 4)
}

pub fn parse_tool_use_response_test() {
  let assert Ok(resp) = response.from_json(fixture("tool_use_response"))
  assert resp.stop_reason == response.ToolUseRequested

  let assert [
    message.Text("Checking"),
    message.ToolUse("toolu_1", "get_time", input),
  ] = resp.content
  // The input survives a decode/encode round trip so it can be echoed back.
  assert json.to_string(input)
    == json.to_string(
      json.object([
        #(
          "n",
          json.preprocessed_array([
            json.int(1),
            json.float(2.5),
            json.bool(True),
            json.null(),
          ]),
        ),
        #("tz", json.string("UTC")),
      ]),
    )
}

pub fn parse_skips_unknown_blocks_test() {
  let assert Ok(resp) = response.from_json(fixture("thinking_response"))

  assert resp.content == [message.Text("Answer")]
}
