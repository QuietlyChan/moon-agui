///|
test "SSE frames contain one compact event data line and a blank separator" {
  let event = @core.AgUiEvent::text_message_content(
    message_id="msg-1",
    delta="Hello",
  )
  assert_eq(
    @sse.frame(event),
    "data: {\"type\":\"TEXT_MESSAGE_CONTENT\",\"messageId\":\"msg-1\",\"delta\":\"Hello\"}\n\n",
  )
}

///|
test "SSE ping uses a comment line" {
  assert_eq(@sse.ping(), ": ping\n\n")
}
