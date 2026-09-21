//// How a run looks to a person. Progress goes to stderr, dimmed and marked
//// with a symbol, so it can't be mistaken for the reply on stdout. Set
//// `NO_COLOR` to drop the colour.

import envoy
import gleam/io

pub fn tool_call(name: String) -> Nil {
  io.println_error(format_tool_call(name))
}

pub fn format_tool_call(name: String) -> String {
  dim("  ⚙ " <> name)
}

fn dim(text: String) -> String {
  case envoy.get("NO_COLOR") {
    Ok(_) -> text
    Error(Nil) -> "\u{1b}[2m" <> text <> "\u{1b}[0m"
  }
}
