///|
/// A minimal AG-UI agent that echoes the latest user message over SSE.
struct EchoAgent {}

///|
fn latest_user_text(input : @core.RunAgentInput) -> String {
  let mut text = ""
  for message in input.messages() {
    match message {
      { "role": "user", "content": String(value), .. } => text = value
      _ => ()
    }
  }
  text
}

///|
impl @server.AgUiAgent for EchoAgent with fn run(self, input, emit) {
  ignore(self)
  let thread_id = input.thread_id()
  let run_id = input.run_id()
  let message_id = run_id + "-assistant"
  let reply = "Echo: " + latest_user_text(input)
  emit(@core.AgUiEvent::run_started(thread_id~, run_id~))
  emit(@core.AgUiEvent::text_message_start(message_id~, role="assistant"))
  emit(@core.AgUiEvent::text_message_content(message_id~, delta=reply))
  emit(@core.AgUiEvent::text_message_end(message_id~))
  emit(@core.AgUiEvent::run_finished(thread_id~, run_id~))
}

///|
async fn main {
  println("AG-UI echo server: POST http://127.0.0.1:8087/agent")
  @server.serve(EchoAgent::{ } as &@server.AgUiAgent)
}
