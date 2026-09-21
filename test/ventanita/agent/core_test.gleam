import gleam/json
import gleam/list
import gleam/option.{Some}
import ventanita/agent/context
import ventanita/agent/core
import ventanita/agent/prompt
import ventanita/agent/tool
import ventanita/anthropic/message
import ventanita/anthropic/models

fn test_context(tools: List(tool.Tool), allowed: List(tool.Access)) {
  context.Context(
    history: [message.user("first")],
    config: context.Config(
      ..context.config("sk-test", "/work"),
      max_tokens: 256,
      model: models.Sonnet5,
      tools:,
      allowed_access: allowed,
    ),
  )
}

fn stub(name: String, access: tool.Access) -> tool.Tool {
  tool.Tool(name, "echo", access, json.object([]), fn(_) { Ok("pong") })
}

pub fn make_request_carries_history_test() {
  let ctx = test_context([], [])
  let asked = message.user("second")
  let req = core.make_request(ctx, [asked])

  assert req.model == "claude-sonnet-5"
  assert req.max_tokens == 256
  // The new message goes last, after everything already said.
  assert req.messages == [message.user("first"), asked]
}

pub fn make_request_sets_system_prompt_test() {
  let req = core.make_request(test_context([], []), [])

  assert req.system == Some(prompt.system("/work"))
}

pub fn make_request_offers_only_permitted_tools_test() {
  let ctx =
    test_context([stub("read", tool.ReadOnly), stub("write", tool.Mutating)], [
      tool.ReadOnly,
    ])

  let names = list.map(core.make_request(ctx, []).tools, fn(t) { t.name })

  assert names == ["read"]
}

pub fn run_tools_answers_each_call_test() {
  let ctx =
    test_context([stub("read", tool.ReadOnly), stub("write", tool.Mutating)], [
      tool.ReadOnly,
    ])
  let input = json.object([])

  let results =
    core.run_tools(
      ctx,
      [
        message.Text("thinking"),
        message.ToolUse("a", "read", input),
        // Registered but not permitted: refused like an unknown tool.
        message.ToolUse("b", "write", input),
        message.ToolUse("c", "nope", input),
      ],
      1,
    )

  assert results
    == [
      message.ToolResult("a", "pong", False),
      message.ToolResult("b", "unknown tool: write", True),
      message.ToolResult("c", "unknown tool: nope", True),
    ]
}
