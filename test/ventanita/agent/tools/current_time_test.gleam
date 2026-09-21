import gleam/json
import gleam/string
import ventanita/agent/tool
import ventanita/agent/tools/current_time

pub fn returns_utc_timestamp_test() {
  let assert Ok(now) =
    tool.call([current_time.tool()], "current_time", json.object([]))

  assert string.ends_with(now, "Z")
}
