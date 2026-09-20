import ventanita/agent/context
import ventanita/agent/core
import ventanita/anthropic/message
import ventanita/anthropic/models

pub fn make_request_carries_history_test() {
  let earlier = message.user("first")
  let ctx =
    context.Context(
      history: [earlier],
      config: context.Config(
        max_tokens: 256,
        anthropic_api_key: "sk-test",
        model: models.Sonnet5,
      ),
    )

  let asked = message.user("second")
  let req = core.make_request(ctx, asked)

  assert req.model == "claude-sonnet-5"
  assert req.max_tokens == 256
  // The new message goes last, after everything already said.
  assert req.messages == [earlier, asked]
}
