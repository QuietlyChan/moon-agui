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
