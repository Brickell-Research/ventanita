import gleeunit/should
import ventanita/vendors/anthropic/models

pub fn to_string_test() {
  models.to_string(models.Fable5pt1) |> should.equal("claude-fable-5-1")
  models.to_string(models.Opus5) |> should.equal("claude-opus-5")
  models.to_string(models.Sonnet5) |> should.equal("claude-sonnet-5")
  models.to_string(models.Haiku4pt5)
  |> should.equal("claude-haiku-4-5-20251001")
}
