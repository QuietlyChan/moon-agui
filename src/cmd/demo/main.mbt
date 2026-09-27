///|
struct EchoAgent {}

///|
impl @server.AgUiAgent for EchoAgent with fn run(self, input, emit) {
  ignore(self)
  let mut prompt = ""
  for message in input.messages() {
    match message {
      { "role": "user", "content": String(content), .. } => prompt = content
      _ => ()
    }
  }
  let thread_id = input.thread_id()
  let run_id = input.run_id()
  let message_id = run_id + "-assistant"
  emit(@core.AgUiEvent::run_started(thread_id~, run_id~))
  emit(@core.AgUiEvent::text_message_start(message_id~))
  emit(
    @core.AgUiEvent::text_message_content(message_id~, delta="Echo: " + prompt),
  )
  emit(@core.AgUiEvent::text_message_end(message_id~))
  emit(@core.AgUiEvent::run_finished(thread_id~, run_id~))
}

///|
async fn main {
  let agent = EchoAgent::{ }
  @server.serve(agent as &@server.AgUiAgent)
}
