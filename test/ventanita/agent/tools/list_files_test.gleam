import gleam/json
import gleam/string
import ventanita/agent/tool
import ventanita/agent/tools/list_files

fn call(directory: String) {
  tool.call(
    [list_files.tool()],
    "list_files",
    json.object([#("directory", json.string(directory))]),
  )
}

pub fn lists_entries_sorted_test() {
  assert call("test/fixtures")
    == Ok("text_response.json\nthinking_response.json\ntool_use_response.json")
}

pub fn missing_directory_is_an_error_test() {
  let assert Error(reason) = call("no/such/dir")

  assert string.starts_with(reason, "could not list no/such/dir")
}
