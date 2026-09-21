//// Reads a text file. Read-only.

import gleam/dynamic/decode
import gleam/json
import gleam/string
import simplifile
import ventanita/agent/tool.{type Tool}

/// Keeps one huge file from swamping the conversation.
const max_chars = 50_000

pub fn tool() -> Tool {
  tool.new(
    name: "read_file",
    description: "Read the contents of a text file.",
    access: tool.ReadOnly,
    input_schema: json.object([
      #("type", json.string("object")),
      #(
        "properties",
        json.object([
          #(
            "path",
            json.object([
              #("type", json.string("string")),
              #("description", json.string("Path of the file to read.")),
            ]),
          ),
        ]),
      ),
      #("required", json.array(["path"], json.string)),
    ]),
    decoder: {
      use path <- decode.field("path", decode.string)
      decode.success(path)
    },
    handler: read_file,
  )
}

fn read_file(path: String) -> Result(String, String) {
  case simplifile.read(path) {
    Ok(contents) -> Ok(truncate(contents))
    Error(reason) ->
      Error(
        "could not read " <> path <> ": " <> simplifile.describe_error(reason),
      )
  }
}

fn truncate(contents: String) -> String {
  case string.length(contents) > max_chars {
    True -> string.slice(contents, 0, max_chars) <> "\n[truncated]"
    False -> contents
  }
}
