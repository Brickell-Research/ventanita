pub type Context {
  Context(history: List(String))
}

pub fn new_context() -> Context {
  Context(history: [])
}

pub fn execute(context: Context) -> String {
  execute_turn(context)
}

pub fn execute_turn(_context: Context) -> String {
  "done"
}
