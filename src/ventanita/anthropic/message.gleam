//// Conversation messages and the content blocks they carry, with their JSON
//// encoding and decoding.

import gleam/dict
import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}

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

pub fn user(text: String) -> Message {
  Message(User, [Text(text)])
}

pub fn to_json(message: Message) -> Json {
  let role = case message.role {
    User -> "user"
    Assistant -> "assistant"
  }
  json.object([
    #("role", json.string(role)),
    #("content", json.array(message.content, block_to_json)),
  ])
}

fn block_to_json(block: Block) -> Json {
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

/// Decodes a `content` array. Block types we don't model (e.g. `thinking`)
/// are skipped, not fatal.
pub fn blocks_decoder() -> Decoder(List(Block)) {
  decode.list(block_decoder()) |> decode.map(option.values)
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
      decode.optional(decode.dynamic) |> decode.map(fn(_) { json.null() }),
    ])
  })
}
