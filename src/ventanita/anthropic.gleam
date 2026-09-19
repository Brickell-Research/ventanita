//// Minimal, non-streaming client for the Anthropic Messages API.
////
//// Request building and response parsing are pure so they can be tested
//// without network access; `send` glues them to `gleam_httpc`.

import gleam/dict
import gleam/dynamic/decode.{type Decoder}
import gleam/http
import gleam/http/request.{type Request as HttpRequest}
import gleam/http/response.{type Response as HttpResponse}
import gleam/httpc
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

const api_version = "2023-06-01"

const timeout_ms = 120_000

pub type Role {
  User
  Assistant
}

pub type Block {
  Text(text: String)
  ToolUse(id: String, name: String, input: Json)
  ToolResult(tool_use_id: String, content: String, is_error: Bool)
}

pub type Message {
  Message(role: Role, content: List(Block))
}

pub type Tool {
  /// `input_schema` is a JSON Schema object describing the tool's input.
  Tool(name: String, description: String, input_schema: Json)
}

pub type Request {
  Request(
    model: String,
    max_tokens: Int,
    system: Option(String),
    messages: List(Message),
    tools: List(Tool),
  )
}

pub type StopReason {
  EndTurn
  MaxTokens
  StopSequence
  ToolUseRequested
  Other(String)
}

pub type Usage {
  Usage(input_tokens: Int, output_tokens: Int)
}

pub type Response {
  Response(
    id: String,
    model: String,
    content: List(Block),
    stop_reason: StopReason,
    usage: Usage,
  )
}

pub type Error {
  Http(httpc.HttpError)
  /// The API answered with a non-2xx status.
  Api(status: Int, kind: String, message: String)
  Decode(json.DecodeError)
}

// HELPERS --------------------------------------------------------------------

pub fn request(model: String, max_tokens: Int) -> Request {
  Request(
    model: model,
    max_tokens: max_tokens,
    system: None,
    messages: [],
    tools: [],
  )
}

pub fn user(text: String) -> Message {
  Message(User, [Text(text)])
}

/// The concatenated text blocks of a response, ignoring tool calls.
pub fn text(response: Response) -> String {
  response.content
  |> list.filter_map(fn(block) {
    case block {
      Text(text) -> Ok(text)
      _ -> Error(Nil)
    }
  })
  |> string.concat
}

// SENDING --------------------------------------------------------------------

pub fn send(api_key: String, req: Request) -> Result(Response, Error) {
  httpc.configure()
  |> httpc.timeout(timeout_ms)
  |> httpc.dispatch(build_request(api_key, req))
  |> result.map_error(Http)
  |> result.try(parse_response)
}

pub fn build_request(api_key: String, req: Request) -> HttpRequest(String) {
  request.new()
  |> request.set_method(http.Post)
  |> request.set_scheme(http.Https)
  |> request.set_host("api.anthropic.com")
  |> request.set_path("/v1/messages")
  |> request.set_header("x-api-key", api_key)
  |> request.set_header("anthropic-version", api_version)
  |> request.set_header("content-type", "application/json")
  |> request.set_body(json.to_string(encode_request(req)))
}

pub fn parse_response(
  response: HttpResponse(String),
) -> Result(Response, Error) {
  case response.status >= 200 && response.status < 300 {
    True ->
      json.parse(response.body, response_decoder())
      |> result.map_error(Decode)
    False -> Error(parse_api_error(response.status, response.body))
  }
}

fn parse_api_error(status: Int, body: String) -> Error {
  let decoder = {
    use kind <- decode.subfield(["error", "type"], decode.string)
    use message <- decode.subfield(["error", "message"], decode.string)
    decode.success(Api(status, kind, message))
  }
  // Fall back to the raw body for non-standard errors (e.g. a proxy page).
  json.parse(body, decoder) |> result.unwrap(Api(status, "unknown", body))
}

// ENCODING -------------------------------------------------------------------

pub fn encode_request(req: Request) -> Json {
  let system = case req.system {
    Some(system) -> [#("system", json.string(system))]
    None -> []
  }
  let tools = case req.tools {
    [] -> []
    tools -> [#("tools", json.array(tools, encode_tool))]
  }
  json.object(
    list.flatten([
      [
        #("model", json.string(req.model)),
        #("max_tokens", json.int(req.max_tokens)),
      ],
      system,
      [#("messages", json.array(req.messages, encode_message))],
      tools,
    ]),
  )
}

fn encode_message(message: Message) -> Json {
  let role = case message.role {
    User -> "user"
    Assistant -> "assistant"
  }
  json.object([
    #("role", json.string(role)),
    #("content", json.array(message.content, encode_block)),
  ])
}

fn encode_block(block: Block) -> Json {
  case block {
    Text(text) ->
      json.object([#("type", json.string("text")), #("text", json.string(text))])
    ToolUse(id, name, input) ->
      json.object([
        #("type", json.string("tool_use")),
        #("id", json.string(id)),
        #("name", json.string(name)),
        #("input", input),
      ])
    ToolResult(tool_use_id, content, is_error) ->
      json.object([
        #("type", json.string("tool_result")),
        #("tool_use_id", json.string(tool_use_id)),
        #("content", json.string(content)),
        #("is_error", json.bool(is_error)),
      ])
  }
}

fn encode_tool(tool: Tool) -> Json {
  json.object([
    #("name", json.string(tool.name)),
    #("description", json.string(tool.description)),
    #("input_schema", tool.input_schema),
  ])
}

// DECODING -------------------------------------------------------------------

fn response_decoder() -> Decoder(Response) {
  use id <- decode.field("id", decode.string)
  use model <- decode.field("model", decode.string)
  use content <- decode.field(
    "content",
    // Block types we don't model (e.g. `thinking`) are skipped, not fatal.
    decode.list(block_decoder()) |> decode.map(option.values),
  )
  use stop_reason <- decode.field("stop_reason", stop_reason_decoder())
  use usage <- decode.field("usage", usage_decoder())
  decode.success(Response(id:, model:, content:, stop_reason:, usage:))
}

fn block_decoder() -> Decoder(Option(Block)) {
  use kind <- decode.field("type", decode.string)
  case kind {
    "text" -> {
      use text <- decode.field("text", decode.string)
      decode.success(Some(Text(text)))
    }
    "tool_use" -> {
      use id <- decode.field("id", decode.string)
      use name <- decode.field("name", decode.string)
      use input <- decode.field("input", json_decoder())
      decode.success(Some(ToolUse(id, name, input)))
    }
    _ -> decode.success(None)
  }
}

fn stop_reason_decoder() -> Decoder(StopReason) {
  use reason <- decode.then(decode.string)
  decode.success(case reason {
    "end_turn" -> EndTurn
    "max_tokens" -> MaxTokens
    "stop_sequence" -> StopSequence
    "tool_use" -> ToolUseRequested
    other -> Other(other)
  })
}

fn usage_decoder() -> Decoder(Usage) {
  use input_tokens <- decode.field("input_tokens", decode.int)
  use output_tokens <- decode.field("output_tokens", decode.int)
  decode.success(Usage(input_tokens:, output_tokens:))
}

/// Decode an arbitrary JSON value so tool inputs can be echoed back verbatim.
fn json_decoder() -> Decoder(Json) {
  decode.recursive(fn() {
    decode.one_of(decode.string |> decode.map(json.string), [
      decode.bool |> decode.map(json.bool),
      decode.int |> decode.map(json.int),
      decode.float |> decode.map(json.float),
      decode.list(json_decoder()) |> decode.map(json.preprocessed_array),
      decode.dict(decode.string, json_decoder())
        |> decode.map(fn(entries) { json.object(dict.to_list(entries)) }),
      decode.optional(decode.string) |> decode.map(fn(_) { json.null() }),
    ])
  })
}
