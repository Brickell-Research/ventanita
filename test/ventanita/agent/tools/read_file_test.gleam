import gleam/json
import gleam/string
import simplifile
import ventanita/agent/tool
import ventanita/agent/tools/read_file

fn call(path: String) {
  tool.call(
    [read_file.tool()],
    "read_file",
    json.object([#("path", json.string(path))]),
  )
}

pub fn reads_contents_test() {
  let assert Ok(contents) = call("test/fixtures/text_response.json")

  assert string.contains(contents, "\"id\"")
}

pub fn missing_file_is_an_error_test() {
  let assert Error(reason) = call("no/such/file")

  assert string.starts_with(reason, "could not read no/such/file")
}

pub fn truncates_large_files_test() {
  let assert Ok(contents) =
    call("build/packages/gleam_stdlib/src/gleam/list.gleam")

  assert string.ends_with(contents, "\n[truncated]")
}
