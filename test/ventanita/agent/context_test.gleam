import envoy
import gleam/string
import simplifile
import ventanita/agent/context
import ventanita/anthropic/message
import ventanita/anthropic/models

pub fn new_context_without_api_key_test() {
  envoy.unset("ANTHROPIC_API_KEY")

  assert context.new_context() == Error("ANTHROPIC_API_KEY is not set")
}

pub fn new_context_reads_api_key_test() {
  envoy.set("ANTHROPIC_API_KEY", "sk-test")
  let assert Ok(ctx) = context.new_context()
  envoy.unset("ANTHROPIC_API_KEY")

  assert ctx.config.anthropic_api_key == "sk-test"
  assert ctx.config.model == models.Haiku4pt5
  assert ctx.history == []
  // The real working directory is part of the system prompt.
  let assert Ok(cwd) = simplifile.current_directory()
  assert string.ends_with(
    ctx.config.system_prompt,
    "Working directory: " <> cwd,
  )
}

pub fn append_preserves_order_test() {
  let ctx =
    context.Context(
      history: [message.user("first")],
      config: context.config("sk-test", "/work"),
    )

  let appended = context.append(ctx, [message.user("second")])

  assert appended.history == [message.user("first"), message.user("second")]
}
