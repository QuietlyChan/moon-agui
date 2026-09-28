///|
test "event constructors use official event names and camelCase fields" {
  let event = @core.AgUiEvent::run_started(thread_id="thread-1", run_id="run-1")
  assert_eq(
    event.to_json_string(),
    "{\"type\":\"RUN_STARTED\",\"threadId\":\"thread-1\",\"runId\":\"run-1\"}",
  )
  let start = @core.AgUiEvent::text_message_start(message_id="msg-1")
  assert_true(start.to_json_string().contains("\"messageId\":\"msg-1\""))
  assert_false(start.to_json_string().contains("message_id"))
}

///|
test "event decoding preserves unknown event types and all fields" {
  let source = "{\"type\":\"FUTURE_EVENT\",\"messageId\":\"m1\",\"payload\":{\"x\":1}}"
  let event = @core.AgUiEvent::from_json_string(source)
  assert_true(event.event_type() is @core.EventType::Other("FUTURE_EVENT"))
  assert_eq(event.to_json_string(), source)
}

///|
test "official event names map to typed event variants" {
  let names = [
    "TEXT_MESSAGE_START", "TEXT_MESSAGE_CONTENT", "TEXT_MESSAGE_END", "TEXT_MESSAGE_CHUNK",
    "TOOL_CALL_START", "TOOL_CALL_ARGS", "TOOL_CALL_END", "TOOL_CALL_CHUNK", "TOOL_CALL_RESULT",
    "STATE_SNAPSHOT", "STATE_DELTA", "MESSAGES_SNAPSHOT", "ACTIVITY_SNAPSHOT", "ACTIVITY_DELTA",
    "RAW", "CUSTOM", "RUN_STARTED", "RUN_FINISHED", "RUN_ERROR", "STEP_STARTED",
    "STEP_FINISHED", "REASONING_START", "REASONING_MESSAGE_START", "REASONING_MESSAGE_CONTENT",
    "REASONING_MESSAGE_END", "REASONING_MESSAGE_CHUNK", "REASONING_END", "REASONING_ENCRYPTED_VALUE",
    "SUBAGENT_STARTED", "SUBAGENT_FINISHED", "SUBAGENT_ERROR",
  ]
  assert_eq(names.length(), 31)
  for name in names {
    let kind = @core.EventType::from_wire_name(name)
    assert_eq(kind.wire_name(), name)
  }
}

///|
test "run input emits 1.0 camelCase fields and preserves JSON values" {
  let input = @core.RunAgentInput::new(
    thread_id="thread-1",
    run_id="run-1",
    messages=[
      @core.Message::text(id="msg-1", role=@core.Role::User, content="Hello"),
    ],
    state={ "count": 2 },
    forwarded_props={ "tenant": "demo" },
  )
  let decoded = @core.RunAgentInput::from_json_string(input.to_json_string())
  assert_eq(decoded.thread_id(), "thread-1")
  assert_eq(decoded.run_id(), "run-1")
  assert_eq(decoded.messages().length(), 1)
  assert_true(decoded.to_json_string().contains("\"protocolVersion\":\"1.0\""))
  assert_true(decoded.to_json_string().contains("\"forwardedProps\""))
  assert_false(decoded.to_json_string().contains("forwarded_props"))
}

///|
test "run input decoder rejects a missing required envelope" {
  try
    @core.RunAgentInput::from_json_string("{\"runId\":\"r1\",\"messages\":[]}")
  catch {
    _ => ()
  } noraise {
    _ => fail("expected a missing threadId to be rejected")
  }
}

///|
test "sequence validator accepts a complete streamed reply" {
  @core.validate_event_sequence([
    @core.AgUiEvent::run_started(thread_id="thread-1", run_id="run-1"),
    @core.AgUiEvent::text_message_start(message_id="msg-1"),
    @core.AgUiEvent::text_message_content(message_id="msg-1", delta="Hi"),
    @core.AgUiEvent::text_message_end(message_id="msg-1"),
    @core.AgUiEvent::run_finished(thread_id="thread-1", run_id="run-1"),
  ])
}

///|
test "sequence validator accepts a tool workflow with state snapshot" {
  @core.validate_event_sequence([
    @core.AgUiEvent::run_started(thread_id="thread-1", run_id="run-1"),
    @core.AgUiEvent::step_started(step_name="lookup"),
    @core.AgUiEvent::tool_call_start(
      tool_call_id="call-1",
      tool_call_name="lookup",
    ),
    @core.AgUiEvent::tool_call_args(
      tool_call_id="call-1",
      delta="{\"query\":\"MoonBit\"}",
    ),
    @core.AgUiEvent::tool_call_end(tool_call_id="call-1"),
    @core.AgUiEvent::tool_call_result(
      message_id="tool-result-1",
      tool_call_id="call-1",
      content=Json::string("Lookup complete"),
    ),
    @core.AgUiEvent::state_snapshot({ "lastTool": "lookup" }),
    @core.AgUiEvent::text_message_start(message_id="msg-1", role="assistant"),
    @core.AgUiEvent::text_message_content(message_id="msg-1", delta="Done"),
    @core.AgUiEvent::text_message_end(message_id="msg-1"),
    @core.AgUiEvent::step_finished(step_name="lookup"),
    @core.AgUiEvent::run_finished(thread_id="thread-1", run_id="run-1"),
  ])
}

///|
test "sequence validator rejects an unmatched message end" {
  try
    @core.validate_event_sequence([
      @core.AgUiEvent::run_started(thread_id="thread-1", run_id="run-1"),
      @core.AgUiEvent::text_message_end(message_id="missing"),
      @core.AgUiEvent::run_finished(thread_id="thread-1", run_id="run-1"),
    ])
  catch {
    _ => ()
  } noraise {
    _ => fail("expected unmatched message end to be rejected")
  }
}

///|
test "sequence validator rejects unclosed calls and events after terminal" {
  try
    @core.validate_event_sequence([
      @core.AgUiEvent::run_started(thread_id="thread-1", run_id="run-1"),
      @core.AgUiEvent::tool_call_start(
        tool_call_id="call-1",
        tool_call_name="lookup",
      ),
      @core.AgUiEvent::run_finished(thread_id="thread-1", run_id="run-1"),
    ])
  catch {
    _ => ()
  } noraise {
    _ => fail("expected an unclosed tool call to be rejected")
  }
  try
    @core.validate_event_sequence([
      @core.AgUiEvent::run_started(thread_id="thread-1", run_id="run-1"),
      @core.AgUiEvent::run_finished(thread_id="thread-1", run_id="run-1"),
      @core.AgUiEvent::custom(name="late", value=Json::null()),
    ])
  catch {
    _ => ()
  } noraise {
    _ => fail("expected an event after terminal to be rejected")
  }
}
