import ventanita/anthropic/models

pub fn to_string_test() {
  assert models.to_string(models.Fable5pt1) == "claude-fable-5-1"
  assert models.to_string(models.Opus5) == "claude-opus-5"
  assert models.to_string(models.Sonnet5) == "claude-sonnet-5"
  assert models.to_string(models.Haiku4pt5) == "claude-haiku-4-5-20251001"
}
