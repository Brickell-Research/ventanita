import envoy
import ventanita/ui

pub fn format_tool_call_dims_by_default_test() {
  envoy.unset("NO_COLOR")

  assert ui.format_tool_call("current_time")
    == "\u{1b}[2m  ⚙ current_time\u{1b}[0m"
}

pub fn format_tool_call_respects_no_color_test() {
  envoy.set("NO_COLOR", "1")
  let line = ui.format_tool_call("current_time")
  envoy.unset("NO_COLOR")

  assert line == "  ⚙ current_time"
}
