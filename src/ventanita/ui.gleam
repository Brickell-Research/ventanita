//// How a run looks to a person. Progress goes to stderr, dimmed and marked
//// with a symbol, so it can't be mistaken for the reply on stdout. Set
//// `NO_COLOR` to drop the colour.

import envoy
import gleam/int
import gleam/io
import gleam/string

/// `step` counts the model calls in this turn, from 1; calls the model makes
/// together share a number. `args` is the call's input as JSON text.
pub fn tool_call(step: Int, name: String, args: String) -> Nil {
  io.println_error(format_tool_call(step, name, args))
}

pub fn format_tool_call(step: Int, name: String, args: String) -> String {
  dim("  ⚙ " <> int.to_string(step) <> " · " <> name <> " " <> args)
}

/// A rule between the tool trail and the reply. Like the trail it goes to
/// stderr, so stdout stays just the reply.
pub fn divider() -> Nil {
  io.println_error(format_divider())
}

pub fn format_divider() -> String {
  dim("  " <> string.repeat("─", 40))
}

fn dim(text: String) -> String {
  case envoy.get("NO_COLOR") {
    Ok(_) -> text
    Error(Nil) -> "\u{1b}[2m" <> text <> "\u{1b}[0m"
  }
}
