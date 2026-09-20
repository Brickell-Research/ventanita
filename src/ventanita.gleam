import gleam/io
import ventanita/agent

pub fn main() -> Nil {
  case agent.execute() {
    Ok(reply) -> io.println(reply)
    Error(reason) -> io.println_error("error: " <> reason)
  }
}
