///|
/// Cross-check the MoonBit wire output against the official AG-UI 1.0 fixtures.
test "multimodal messages use official content part and source shapes" {
  let image = @core.ContentPart::image(
    source=@core.PartSource::url(
      value="https://example.test/a.png",
      mime_type="image/png",
    ),
    id="part-1",
  )
  let message = @core.Message::user_parts(id="m1", content=[image])
  let wire = message.to_json().stringify()
  assert_true(wire.contains("\"role\":\"user\""))
  assert_true(wire.contains("\"type\":\"image\""))
  assert_true(wire.contains("\"type\":\"url\""))
  assert_true(wire.contains("\"mimeType\":\"image/png\""))
}

///|
test "full event factories preserve official optional fields" {
  let event = @core.AgUiEvent::run_finished_full(
    thread_id="t1",
    run_id="r1",
    result={ "answer": true },
    outcome=@core.run_finished_outcome_cancelled(),
    usage=[@core.TokenUsage::new(provider="moon", total_tokens=3)],
  )
  assert_eq(event.event_type().wire_name(), "RUN_FINISHED")
  assert_true(
    event.to_json_string().contains("\"outcome\":{\"type\":\"cancelled\"}"),
  )
  assert_true(event.to_json_string().contains("\"totalTokens\":3"))
}

///|
test "reasoning and subagent lifecycle validates like official client" {
  @core.validate_event_sequence([
    @core.AgUiEvent::run_started(thread_id="t1", run_id="r1"),
    @core.AgUiEvent::subagent_started(subagent_run_id="s1", name="research"),
    @core.AgUiEvent::reasoning_start(
      message_id="reason-1",
      subagent_run_id="s1",
    ),
    @core.AgUiEvent::reasoning_message_start(
      message_id="reason-1",
      subagent_run_id="s1",
    ),
    @core.AgUiEvent::reasoning_message_content(
      message_id="reason-1",
      delta="thinking",
      subagent_run_id="s1",
    ),
    @core.AgUiEvent::reasoning_message_end(
      message_id="reason-1",
      subagent_run_id="s1",
    ),
    @core.AgUiEvent::reasoning_end(message_id="reason-1", subagent_run_id="s1"),
    @core.AgUiEvent::subagent_finished(
      subagent_run_id="s1",
      outcome=@core.subagent_finished_outcome(true, interrupt_ids=["i1"]),
    ),
    @core.AgUiEvent::run_finished(thread_id="t1", run_id="r1"),
  ])
}

///|
test "chunk events are open-form and round trip" {
  let event = @core.AgUiEvent::text_message_chunk(
    message_id="m1",
    role="assistant",
    delta="hi",
    subagent_run_id="s1",
  )
  let decoded = @core.AgUiEvent::from_json_string(event.to_json_string())
  assert_eq(decoded.event_type().wire_name(), "TEXT_MESSAGE_CHUNK")
  assert_eq(decoded.string_field("delta"), Some("hi"))
}

///|
test "json patch operations use RFC 6902 names" {
  let patch = @core.json_patch([
    @core.JsonPatchOperation::add(path="/count", value=1),
    @core.JsonPatchOperation::replace(path="/name", value="moon"),
    @core.JsonPatchOperation::remove(path="/old"),
  ])
  assert_eq(
    patch.stringify(),
    "[{\"op\":\"add\",\"path\":\"/count\",\"value\":1},{\"op\":\"replace\",\"path\":\"/name\",\"value\":\"moon\"},{\"op\":\"remove\",\"path\":\"/old\"}]",
  )
}

///|
test "state event factories keep the original positional JSON API" {
  let snapshot = @core.AgUiEvent::state_snapshot({ "phase": "ready" })
  let delta = @core.AgUiEvent::state_delta(
    @core.json_patch([
      @core.JsonPatchOperation::replace(path="/phase", value="done"),
    ]),
  )
  assert_eq(snapshot.event_type().wire_name(), "STATE_SNAPSHOT")
  assert_true(snapshot.to_json_string().contains("\"snapshot\""))
  assert_eq(delta.event_type().wire_name(), "STATE_DELTA")
  assert_true(delta.to_json_string().contains("\"delta\""))
}

///|
test "optional public event fields are omitted when absent" {
  let event = @core.AgUiEvent::activity_snapshot(
    message_id="activity-1",
    activity_type="progress",
    content={ "step": 1 },
  )
  assert_false(event.to_json_string().contains("replace"))
  let start = @core.AgUiEvent::text_message_start(message_id="m1")
  assert_false(start.to_json_string().contains("\"role\""))
}

///|
test "decoder rejects malformed official union members" {
  try
    ignore(
      @core.AgUiEvent::from_json_string(
        "{\"type\":\"STATE_DELTA\",\"delta\":[{\"op\":\"add\",\"path\":\"/x\"}]}",
      ),
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("expected an add patch without value to be rejected")
  }
  try
    ignore(
      @core.AgUiEvent::from_json_string(
        "{\"type\":\"REASONING_ENCRYPTED_VALUE\",\"subtype\":\"unknown\",\"entityId\":\"x\",\"encryptedValue\":\"y\"}",
      ),
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("expected an unknown reasoning subtype to be rejected")
  }
}

///|
test "decoder enforces official scalar and RFC 6901 constraints" {
  for
    value in [
      "{\"type\":\"TEXT_MESSAGE_END\",\"messageId\":\"m\",\"timestamp\":1.5}", "{\"type\":\"TEXT_MESSAGE_END\",\"messageId\":\"m\",\"timestamp\":9007199254740992}",
      "{\"type\":\"STATE_DELTA\",\"delta\":[{\"op\":\"remove\",\"path\":\"/a~2b\"}]}",
      "{\"type\":\"RUN_FINISHED\",\"threadId\":\"t\",\"runId\":\"r\",\"outcome\":{\"type\":\"cancelled\",\"interrupts\":[]}}",
      "{\"type\":\"RUN_FINISHED\",\"threadId\":\"t\",\"runId\":\"r\",\"usage\":[{\"inputTokens\":-1}]}",
    ] {
    try ignore(@core.AgUiEvent::from_json_string(value)) catch {
      _ => ()
    } noraise {
      _ => fail("expected an official constraint violation to be rejected")
    }
  }
}
