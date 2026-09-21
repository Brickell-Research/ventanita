//// Reports the current UTC time. Read-only, takes no input.

import gleam/dynamic/decode
import gleam/json
import gleam/time/duration
import gleam/time/timestamp
import ventanita/agent/tool.{type Tool}

pub fn tool() -> Tool {
  tool.new(
    name: "current_time",
    description: "Get the current date and time in UTC (RFC 3339).",
    access: tool.ReadOnly,
    input_schema: json.object([
      #("type", json.string("object")),
      #("properties", json.object([])),
    ]),
    decoder: decode.success(Nil),
    handler: fn(_) {
      Ok(timestamp.to_rfc3339(timestamp.system_time(), duration.seconds(0)))
    },
  )
}
