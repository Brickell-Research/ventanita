import envoy
import ventanita/ui

pub fn format_tool_call_dims_by_default_test() {
  envoy.unset("NO_COLOR")

  assert ui.format_tool_call(2, "read_file", "{\"path\":\"a\"}")
    == "\u{1b}[2m  ⚙ 2 · read_file {\"path\":\"a\"}\u{1b}[0m"
}

pub fn format_tool_call_respects_no_color_test() {
  envoy.set("NO_COLOR", "1")
  let line = ui.format_tool_call(2, "read_file", "{\"path\":\"a\"}")
  envoy.unset("NO_COLOR")

  assert line == "  ⚙ 2 · read_file {\"path\":\"a\"}"
}

pub fn format_divider_test() {
  envoy.set("NO_COLOR", "1")
  let line = ui.format_divider()
  envoy.unset("NO_COLOR")

  assert line == "  ────────────────────────────────────────"
}
