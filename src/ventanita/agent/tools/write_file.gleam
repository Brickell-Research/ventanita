//// Writes a text file, replacing any existing contents. The only mutating
//// tool: it stays out of reach unless the context's `allowed_access`
//// includes `Mutating`.

import gleam/bit_array
import gleam/dynamic/decode
import gleam/int
import gleam/json
import simplifile
import ventanita/agent/tool.{type Tool}

pub fn tool() -> Tool {
  tool.new(
    name: "write_file",
    description: "Write text to a file, creating it or replacing its contents. The parent directory must already exist.",
    access: tool.Mutating,
    input_schema: json.object([
      #("type", json.string("object")),
      #(
        "properties",
        json.object([
          #(
            "path",
            json.object([
              #("type", json.string("string")),
              #("description", json.string("Path of the file to write.")),
            ]),
          ),
          #(
            "content",
            json.object([
              #("type", json.string("string")),
              #("description", json.string("The full new contents.")),
            ]),
          ),
        ]),
      ),
      #("required", json.array(["path", "content"], json.string)),
    ]),
    decoder: {
      use path <- decode.field("path", decode.string)
      use content <- decode.field("content", decode.string)
      decode.success(#(path, content))
    },
    handler: fn(input) { write_file(input.0, input.1) },
  )
}

fn write_file(path: String, content: String) -> Result(String, String) {
  case simplifile.write(path, content) {
    Ok(Nil) -> {
      let bytes = bit_array.byte_size(bit_array.from_string(content))
      Ok("wrote " <> int.to_string(bytes) <> " bytes to " <> path)
    }
    Error(reason) ->
      Error(
        "could not write " <> path <> ": " <> simplifile.describe_error(reason),
      )
  }
}
