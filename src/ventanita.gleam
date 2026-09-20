import gleam/io
import ventanita/agent.{execute}

pub fn main() -> Nil {
  let outcome = execute()

  case outcome {
    Ok(reply) -> io.println(reply)
    Error(reason) -> io.println_error("error: " <> reason)
  }
}
