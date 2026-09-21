import envoy
import ventanita/anthropic/response.{Usage}
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

pub fn format_usage_test() {
  envoy.set("NO_COLOR", "1")
  let lines = ui.format_usage(Usage(1234, 56), 3, 2.44)
  envoy.unset("NO_COLOR")

  assert lines == "  tokens  1234 in · 56 out\n  steps   3\n  time    2.4s"
}

pub fn format_section_test() {
  envoy.set("NO_COLOR", "1")
  let diagnostics = ui.format_section("diagnostics")
  let output = ui.format_section("output")
  envoy.unset("NO_COLOR")

  assert diagnostics == "  ── diagnostics ─────────────────────────"
  assert output == "  ── output ──────────────────────────────"
}
