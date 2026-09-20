import gleam/json
import gleeunit/should
import simplifile
import ventanita/vendors/anthropic/message
import ventanita/vendors/anthropic/response

fn fixture(name: String) -> String {
  let assert Ok(body) = simplifile.read("test/fixtures/" <> name <> ".json")
  body
}

pub fn parse_text_response_test() {
  let assert Ok(resp) = response.from_json(fixture("text_response"))

  should.equal(response.text(resp), "Hello there")
  should.equal(resp.stop_reason, response.EndTurn)
  should.equal(resp.usage, response.Usage(10, 4))
}

pub fn parse_tool_use_response_test() {
  let assert Ok(resp) = response.from_json(fixture("tool_use_response"))
  should.equal(resp.stop_reason, response.ToolUseRequested)

  let assert [
    message.Text("Checking"),
    message.ToolUse("toolu_1", "get_time", input),
  ] = resp.content
  // The input survives a decode/encode round trip so it can be echoed back.
  json.to_string(input)
  |> should.equal(
    json.to_string(
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
    ),
  )
}

pub fn parse_skips_unknown_blocks_test() {
  let assert Ok(resp) = response.from_json(fixture("thinking_response"))

  should.equal(resp.content, [message.Text("Answer")])
}
