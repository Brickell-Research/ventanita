import gleam/http/response
import gleam/json
import gleam/option.{Some}
import gleeunit/should
import ventanita/anthropic

fn ok(body: String) {
  response.new(200) |> response.set_body(body)
}

pub fn encode_request_test() {
  let req =
    anthropic.Request(
      ..anthropic.request("claude-sonnet-5", 256),
      system: Some("Be brief."),
      messages: [anthropic.user("hi")],
    )

  anthropic.encode_request(req)
  |> json.to_string
  |> should.equal(
    "{\"model\":\"claude-sonnet-5\",\"max_tokens\":256,\"system\":\"Be brief.\",\"messages\":[{\"role\":\"user\",\"content\":[{\"type\":\"text\",\"text\":\"hi\"}]}]}",
  )
}

pub fn encode_request_with_tool_test() {
  let tool =
    anthropic.Tool(
      name: "get_time",
      description: "Current time",
      input_schema: json.object([#("type", json.string("object"))]),
    )
  let req = anthropic.Request(..anthropic.request("m", 1), tools: [tool])

  anthropic.encode_request(req)
  |> json.to_string
  |> should.equal(
    "{\"model\":\"m\",\"max_tokens\":1,\"messages\":[],\"tools\":[{\"name\":\"get_time\",\"description\":\"Current time\",\"input_schema\":{\"type\":\"object\"}}]}",
  )
}

pub fn build_request_test() {
  let req = anthropic.build_request("sk-test", anthropic.request("m", 1))

  should.equal(req.host, "api.anthropic.com")
  should.equal(req.path, "/v1/messages")
  should.equal(req.headers, [
    #("x-api-key", "sk-test"),
    #("anthropic-version", "2023-06-01"),
    #("content-type", "application/json"),
  ])
}

pub fn parse_text_response_test() {
  let body =
    "{\"id\":\"msg_1\",\"type\":\"message\",\"role\":\"assistant\",\"model\":\"claude-sonnet-5\",\"content\":[{\"type\":\"text\",\"text\":\"Hello\"},{\"type\":\"text\",\"text\":\" there\"}],\"stop_reason\":\"end_turn\",\"stop_sequence\":null,\"usage\":{\"input_tokens\":10,\"output_tokens\":4}}"

  let assert Ok(resp) = anthropic.parse_response(ok(body))

  should.equal(anthropic.text(resp), "Hello there")
  should.equal(resp.stop_reason, anthropic.EndTurn)
  should.equal(resp.usage, anthropic.Usage(10, 4))
}

pub fn parse_tool_use_response_test() {
  let body =
    "{\"id\":\"msg_2\",\"model\":\"m\",\"content\":[{\"type\":\"text\",\"text\":\"Checking\"},{\"type\":\"tool_use\",\"id\":\"toolu_1\",\"name\":\"get_time\",\"input\":{\"tz\":\"UTC\",\"n\":[1,2.5,true,null]}}],\"stop_reason\":\"tool_use\",\"usage\":{\"input_tokens\":1,\"output_tokens\":2}}"

  let assert Ok(resp) = anthropic.parse_response(ok(body))
  should.equal(resp.stop_reason, anthropic.ToolUseRequested)

  let assert [
    anthropic.Text("Checking"),
    anthropic.ToolUse("toolu_1", "get_time", input),
  ] = resp.content
  // The input survives a decode/encode round trip so it can be echoed back.
  json.to_string(input)
  |> should.equal("{\"n\":[1,2.5,true,null],\"tz\":\"UTC\"}")
}

pub fn parse_api_error_test() {
  let body =
    "{\"type\":\"error\",\"error\":{\"type\":\"rate_limit_error\",\"message\":\"slow down\"}}"

  response.new(429)
  |> response.set_body(body)
  |> anthropic.parse_response
  |> should.equal(Error(anthropic.Api(429, "rate_limit_error", "slow down")))
}

pub fn parse_non_json_error_test() {
  response.new(502)
  |> response.set_body("<html>bad gateway</html>")
  |> anthropic.parse_response
  |> should.equal(
    Error(anthropic.Api(502, "unknown", "<html>bad gateway</html>")),
  )
}

pub fn parse_skips_unknown_blocks_test() {
  let body =
    "{\"id\":\"msg_3\",\"model\":\"m\",\"content\":[{\"type\":\"thinking\",\"thinking\":\"hmm\",\"signature\":\"x\"},{\"type\":\"text\",\"text\":\"Answer\"}],\"stop_reason\":\"end_turn\",\"usage\":{\"input_tokens\":1,\"output_tokens\":1}}"

  let assert Ok(resp) = anthropic.parse_response(ok(body))

  should.equal(resp.content, [anthropic.Text("Answer")])
}
