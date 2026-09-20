//// The Claude models this project knows how to ask for.

pub type Model {
  Fable5pt1
  Opus5
  Sonnet5
  Haiku4pt5
}

/// The model ID the Messages API expects.
pub fn to_string(model: Model) -> String {
  case model {
    Fable5pt1 -> "claude-fable-5-1"
    Opus5 -> "claude-opus-5"
    Sonnet5 -> "claude-sonnet-5"
    Haiku4pt5 -> "claude-haiku-4-5-20251001"
  }
}
