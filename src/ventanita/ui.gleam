//// How a run looks to a person. Progress goes to stderr, dimmed and marked
//// with a symbol, so it can't be mistaken for the output on stdout. Set
//// `NO_COLOR` to drop the colour.

import envoy
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import ventanita/anthropic/response.{type Usage}

/// `step` counts the model calls in this turn, from 1; calls the model makes
/// together share a number. `args` is the call's input as JSON text.
pub fn tool_call(step: Int, name: String, args: String) -> Nil {
  io.println_error(format_tool_call(step, name, args))
}

pub fn format_tool_call(step: Int, name: String, args: String) -> String {
  dim("  ⚙ " <> int.to_string(step) <> " · " <> name <> " " <> args)
}

/// A labelled rule that opens a section of the run, on stderr. The run reads
/// top to bottom as: tool calls, diagnostics, then the output.
pub fn section(label: String) -> Nil {
  io.println_error(format_section(label))
}

pub fn format_section(label: String) -> String {
  let fill = int.max(0, 36 - string.length(label))
  dim("  ── " <> label <> " " <> string.repeat("─", fill))
}

/// Token, step and time totals for the turn, one per line, on stderr.
pub fn usage(usage: Usage, steps: Int, seconds: Float) -> Nil {
  io.println_error(format_usage(usage, steps, seconds))
}

pub fn format_usage(usage: Usage, steps: Int, seconds: Float) -> String {
  [
    "  tokens  "
      <> int.to_string(usage.input_tokens)
      <> " in · "
      <> int.to_string(usage.output_tokens)
      <> " out",
    "  steps   " <> int.to_string(steps),
    "  time    " <> float.to_string(float.to_precision(seconds, 1)) <> "s",
  ]
  |> list.map(dim)
  |> string.join("\n")
}

fn dim(text: String) -> String {
  case envoy.get("NO_COLOR") {
    Ok(_) -> text
    Error(Nil) -> "\u{1b}[2m" <> text <> "\u{1b}[0m"
  }
}
