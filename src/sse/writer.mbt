///|
/// Encode one AG-UI event as an SSE data frame.
pub fn frame(event : @core.AgUiEvent) -> String {
  "data: " + event.to_json_string() + "\n\n"
}

///|
/// Return an SSE comment frame suitable for a keepalive ping.
pub fn ping() -> String {
  ": ping\n\n"
}

///|
/// Decode one complete SSE event block into an AG-UI event.
///
/// Comment, `event`, `id`, and `retry` lines are ignored. Multiple `data:`
/// lines are joined with a newline according to the SSE specification.
pub fn parse_frame(frame_text : String) -> @core.AgUiEvent? raise {
  let normalized = frame_text.replace_all(old="\r\n", new="\n")
  let data = StringBuilder()
  let mut saw_data = false
  for line_view in normalized.split("\n") {
    let line = line_view.to_owned()
    if line.has_prefix("data:") {
      if saw_data {
        data.write_string("\n")
      }
      let payload = line[5:]
      data.write_string(
        if payload.has_prefix(" ") {
          payload[1:].to_owned()
        } else {
          payload.to_owned()
        },
      )
      saw_data = true
    }
  }
  if !saw_data {
    None
  } else {
    Some(@core.AgUiEvent::from_json_string(data.to_string()))
  }
}

///|
/// Decode all complete SSE event blocks in a response body.
pub fn parse_stream(stream : String) -> Array[@core.AgUiEvent] raise {
  let events : Array[@core.AgUiEvent] = []
  let normalized = stream.replace_all(old="\r\n", new="\n")
  for block_view in normalized.split("\n\n") {
    match parse_frame(block_view.to_owned()) {
      Some(event) => events.push(event)
      None => ()
    }
  }
  events
}
