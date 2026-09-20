//// A successful Messages API response.

import gleam/dynamic/decode.{type Decoder}
import gleam/json
import gleam/list
import gleam/string
import ventanita/anthropic/message.{type Block}

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

/// The concatenated text blocks of a response, ignoring tool calls.
pub fn text(response: Response) -> String {
  response.content
  |> list.filter_map(fn(block) {
    case block {
      message.Text(text) -> Ok(text)
      _ -> Error(Nil)
    }
  })
  |> string.concat
}

pub fn from_json(body: String) -> Result(Response, json.DecodeError) {
  json.parse(body, decoder())
}

fn decoder() -> Decoder(Response) {
  use id <- decode.field("id", decode.string)
  use model <- decode.field("model", decode.string)
  use content <- decode.field("content", message.blocks_decoder())
  use stop_reason <- decode.field("stop_reason", stop_reason_decoder())
  use usage <- decode.field("usage", usage_decoder())
  decode.success(Response(id:, model:, content:, stop_reason:, usage:))
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
