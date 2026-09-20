import gleam/json
import gleam/option.{Some}
import gleeunit/should
import ventanita/vendors/anthropic/message
import ventanita/vendors/anthropic/request
import ventanita/vendors/anthropic/tool

pub fn to_json_test() {
  let req =
    request.Request(
      ..request.new("claude-sonnet-5", 256),
      system: Some("Be brief."),
      messages: [message.user("hi")],
    )

  let expected =
    json.object([
      #("model", json.string("claude-sonnet-5")),
      #("max_tokens", json.int(256)),
      #("system", json.string("Be brief.")),
      #(
        "messages",
        json.preprocessed_array([
          json.object([
            #("role", json.string("user")),
            #(
              "content",
              json.preprocessed_array([
                json.object([
                  #("type", json.string("text")),
                  #("text", json.string("hi")),
                ]),
              ]),
            ),
          ]),
        ]),
      ),
    ])

  request.to_json(req)
  |> json.to_string
  |> should.equal(json.to_string(expected))
}

pub fn to_json_with_tool_test() {
  let schema = json.object([#("type", json.string("object"))])
  let get_time =
    tool.Tool(
      name: "get_time",
      description: "Current time",
      input_schema: schema,
    )
  let req = request.Request(..request.new("m", 1), tools: [get_time])

  let expected =
    json.object([
      #("model", json.string("m")),
      #("max_tokens", json.int(1)),
      #("messages", json.preprocessed_array([])),
      #(
        "tools",
        json.preprocessed_array([
          json.object([
            #("name", json.string("get_time")),
            #("description", json.string("Current time")),
            #("input_schema", schema),
          ]),
        ]),
      ),
    ])

  request.to_json(req)
  |> json.to_string
  |> should.equal(json.to_string(expected))
}
