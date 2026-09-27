///|
/// Build a complete, protocol-valid AG-UI response without a model or network.
fn sample_events() -> Array[@core.AgUiEvent] {
  [
    @core.AgUiEvent::run_started(thread_id="thread-demo", run_id="run-demo"),
    @core.AgUiEvent::text_message_start(
      message_id="message-demo",
      role="assistant",
    ),
    @core.AgUiEvent::text_message_content(
      message_id="message-demo",
      delta="Hello from a MoonBit AG-UI agent!",
    ),
    @core.AgUiEvent::text_message_end(message_id="message-demo"),
    @core.AgUiEvent::run_finished(thread_id="thread-demo", run_id="run-demo"),
  ]
}

///|
/// Demonstrate JSON encoding, SSE framing, decoding, and lifecycle validation.
fn main raise {
  let events = sample_events()
  @core.validate_event_sequence(events) catch {
    error => {
      println("Invalid event sequence: \{error}")
      return
    }
  }
  println("AG-UI 1.0 offline example")
  println("JSON events:")
  let decoded = []
  for event in events {
    println("  " + event.to_json_string())
    decoded.push(@core.AgUiEvent::from_json_string(event.to_json_string()))
    println("  SSE: " + @sse.frame(event).trim_end().to_owned())
  }
  println("JSON round-trip: \{decoded.length()} event(s)")
  for event in decoded {
    println("  " + event.event_type().wire_name())
  }
}
