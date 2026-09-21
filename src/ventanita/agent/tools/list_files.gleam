//// Lists the entries of a directory. Read-only.

import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/string
import simplifile
import ventanita/agent/tool.{type Tool}

pub fn tool() -> Tool {
  tool.new(
    name: "list_files",
    description: "List the files and directories in a directory, one per line.",
    access: tool.ReadOnly,
    input_schema: json.object([
      #("type", json.string("object")),
      #(
        "properties",
        json.object([
          #(
            "directory",
            json.object([
              #("type", json.string("string")),
              #("description", json.string("Path of the directory to list.")),
            ]),
          ),
        ]),
      ),
      #("required", json.array(["directory"], json.string)),
    ]),
    decoder: {
      use directory <- decode.field("directory", decode.string)
      decode.success(directory)
    },
    handler: list_files,
  )
}

fn list_files(directory: String) -> Result(String, String) {
  case simplifile.read_directory(directory) {
    Ok(entries) -> Ok(entries |> list.sort(string.compare) |> string.join("\n"))
    Error(reason) ->
      Error(
        "could not list "
        <> directory
        <> ": "
        <> simplifile.describe_error(reason),
      )
  }
}
