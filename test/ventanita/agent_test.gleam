import gleeunit/should
import ventanita/agent

pub fn execute_test() {
  let actual = agent.new_context() |> agent.execute_turn()
  let expected = "done"

  should.equal(actual, expected)
}
