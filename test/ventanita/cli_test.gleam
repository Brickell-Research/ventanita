import ventanita/agent/tool
import ventanita/cli

pub fn parse_is_read_only_by_default_test() {
  assert cli.parse(["list", "the", "files"])
    == Ok(#("list the files", [tool.ReadOnly]))
}

pub fn parse_allow_writes_flag_test() {
  let expected = Ok(#("make a file", [tool.ReadOnly, tool.Mutating]))

  assert cli.parse(["--allow-writes", "make", "a", "file"]) == expected
  assert cli.parse(["make", "a", "file", "--allow-writes"]) == expected
}

pub fn parse_requires_a_prompt_test() {
  let usage = Error("usage: ventanita [--allow-writes] <prompt>")

  assert cli.parse([]) == usage
  assert cli.parse(["--allow-writes"]) == usage
}
