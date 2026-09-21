//// The state a run of the agent carries between turns: static settings and
//// the conversation so far.

import envoy
import gleam/list
import gleam/result
import simplifile
import ventanita/agent/prompt
import ventanita/agent/tool.{type Access, type Tool}
import ventanita/agent/tools/current_time
import ventanita/agent/tools/list_files
import ventanita/agent/tools/read_file
import ventanita/agent/tools/write_file
import ventanita/anthropic/message.{type Message}
import ventanita/anthropic/models.{type Model}

pub type Config {
  Config(
    max_tokens: Int,
    anthropic_api_key: String,
    model: Model,
    system_prompt: String,
    /// Every tool that exists for this agent...
    tools: List(Tool),
    /// ...and the kinds of access it is actually allowed to use.
    allowed_access: List(Access),
    /// Cap on model calls per turn, so a tool loop cannot run away.
    max_steps: Int,
  )
}

pub type Context {
  Context(history: List(Message), config: Config)
}

pub fn new_context() -> Result(Context, String) {
  use api_key <- result.try(
    envoy.get("ANTHROPIC_API_KEY")
    |> result.replace_error("ANTHROPIC_API_KEY is not set"),
  )
  use cwd <- result.try(
    simplifile.current_directory()
    |> result.map_error(fn(e) {
      "could not read working directory: " <> simplifile.describe_error(e)
    }),
  )
  Ok(Context(history: [], config: config(api_key, cwd)))
}

pub fn config(api_key: String, working_directory: String) -> Config {
  Config(
    max_tokens: 1024,
    anthropic_api_key: api_key,
    model: models.Sonnet5,
    system_prompt: prompt.system(working_directory),
    tools: [
      current_time.tool(),
      list_files.tool(),
      read_file.tool(),
      write_file.tool(),
    ],
    allowed_access: [tool.ReadOnly],
    max_steps: 8,
  )
}

/// Records a completed exchange so the next turn can see it.
pub fn append(context: Context, messages: List(Message)) -> Context {
  Context(..context, history: list.append(context.history, messages))
}
