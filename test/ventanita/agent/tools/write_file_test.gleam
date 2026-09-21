import gleam/json
import gleam/string
import simplifile
import ventanita/agent/tool
import ventanita/agent/tools/write_file

fn call(path: String, content: String) {
  tool.call(
    [write_file.tool()],
    "write_file",
    json.object([
      #("path", json.string(path)),
      #("content", json.string(content)),
    ]),
  )
}

pub fn is_mutating_test() {
  assert write_file.tool().access == tool.Mutating
}

pub fn writes_and_replaces_contents_test() {
  let path = "build/write_file_test.tmp"

  assert call(path, "first") == Ok("wrote 5 bytes to " <> path)
  assert call(path, "second") == Ok("wrote 6 bytes to " <> path)
  assert simplifile.read(path) == Ok("second")

  let assert Ok(Nil) = simplifile.delete(path)
}

pub fn missing_parent_directory_is_an_error_test() {
  let assert Error(reason) = call("no/such/dir/file.txt", "x")

  assert string.starts_with(reason, "could not write no/such/dir/file.txt")
}
