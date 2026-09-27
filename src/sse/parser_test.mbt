///|
test "parse SSE data frames and comments" {
  let stream = ": ping\n\ndata: {\"type\":\"RUN_STARTED\",\"threadId\":\"t\",\"runId\":\"r\"}\n\n"
  let events = @sse.parse_stream(stream)
  assert_eq(events.length(), 1)
  assert_eq(events[0].event_type().wire_name(), "RUN_STARTED")
}

///|
test "parse multiline SSE data payload" {
  let frame = "data: {\"type\":\ndata: \"CUSTOM\",\"name\":\"x\",\"value\":1}\n"
  let event = @sse.parse_frame(frame)
  assert_true(event is Some(_))
}
