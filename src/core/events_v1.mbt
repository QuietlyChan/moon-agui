///|
/// AG-UI 1.0 event factories not present in the original minimal API.
fn event_with_base(
  event_type : EventType,
  fields : Map[String, Json],
  attributable : Bool,
  timestamp : Int?,
  raw_event : Json?,
  metadata : Json?,
  subagent_run_id : String?,
) -> AgUiEvent {
  put_optional_int(fields, "timestamp", timestamp)
  put_optional_json(fields, "rawEvent", raw_event)
  put_optional_json(fields, "metadata", metadata)
  if attributable {
    put_optional_string(fields, "subagentRunId", subagent_run_id)
  }
  AgUiEvent::new(event_type~, fields~)
}

///|
fn put_usage(fields : Map[String, Json], usage : Array[TokenUsage]?) -> Unit {
  match usage {
    Some(usage) =>
      fields["usage"] = Json::array([ for value in usage => value.to_json() ])
    None => ()
  }
}

///|
/// Build a TEXT_MESSAGE_CHUNK event. All payload fields are optional by schema.
pub fn AgUiEvent::text_message_chunk(
  message_id? : String,
  role? : String,
  delta? : String,
  name? : String,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
  subagent_run_id? : String,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([])
  put_optional_string(fields, "messageId", message_id)
  put_optional_string(fields, "role", role)
  put_optional_string(fields, "delta", delta)
  put_optional_string(fields, "name", name)
  event_with_base(
    EventType::TextMessageChunk,
    fields,
    true,
    timestamp,
    raw_event,
    metadata,
    subagent_run_id,
  )
}

///|
/// Build a TOOL_CALL_CHUNK event.
pub fn AgUiEvent::tool_call_chunk(
  tool_call_id? : String,
  tool_call_name? : String,
  parent_message_id? : String,
  delta? : String,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
  subagent_run_id? : String,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([])
  put_optional_string(fields, "toolCallId", tool_call_id)
  put_optional_string(fields, "toolCallName", tool_call_name)
  put_optional_string(fields, "parentMessageId", parent_message_id)
  put_optional_string(fields, "delta", delta)
  event_with_base(
    EventType::ToolCallChunk,
    fields,
    true,
    timestamp,
    raw_event,
    metadata,
    subagent_run_id,
  )
}

///|
/// Build an ACTIVITY_SNAPSHOT event.
pub fn AgUiEvent::activity_snapshot(
  message_id~ : String,
  activity_type~ : String,
  content~ : Json,
  replace? : Bool,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
  subagent_run_id? : String,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([
    ("messageId", Json::string(message_id)),
    ("activityType", Json::string(activity_type)),
    ("content", content),
  ])
  put_optional_bool(fields, "replace", replace)
  event_with_base(
    EventType::ActivitySnapshot,
    fields,
    true,
    timestamp,
    raw_event,
    metadata,
    subagent_run_id,
  )
}

///|
/// Build an ACTIVITY_DELTA event with JSON Patch operations.
pub fn AgUiEvent::activity_delta(
  message_id~ : String,
  activity_type~ : String,
  patch~ : Json,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
  subagent_run_id? : String,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([
    ("messageId", Json::string(message_id)),
    ("activityType", Json::string(activity_type)),
    ("patch", patch),
  ])
  event_with_base(
    EventType::ActivityDelta,
    fields,
    true,
    timestamp,
    raw_event,
    metadata,
    subagent_run_id,
  )
}

///|
/// Build a RAW event carrying an integration-native JSON value.
pub fn AgUiEvent::raw(
  event~ : Json,
  source? : String,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
  subagent_run_id? : String,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([("event", event)])
  put_optional_string(fields, "source", source)
  event_with_base(
    EventType::Raw,
    fields,
    true,
    timestamp,
    raw_event,
    metadata,
    subagent_run_id,
  )
}

///|
/// Build a CUSTOM application event.
pub fn AgUiEvent::custom_with_options(
  name~ : String,
  value~ : Json,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
  subagent_run_id? : String,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([
    ("name", Json::string(name)),
    ("value", value),
  ])
  event_with_base(
    EventType::Custom,
    fields,
    true,
    timestamp,
    raw_event,
    metadata,
    subagent_run_id,
  )
}

///|
/// Build a RUN_STARTED event with optional protocol and parent-run details.
pub fn AgUiEvent::run_started_full(
  thread_id~ : String,
  run_id~ : String,
  protocol_version? : String,
  parent_run_id? : String,
  input? : RunAgentInput,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([
    ("threadId", Json::string(thread_id)),
    ("runId", Json::string(run_id)),
  ])
  put_optional_string(fields, "protocolVersion", protocol_version)
  put_optional_string(fields, "parentRunId", parent_run_id)
  match input {
    Some(input) => fields["input"] = input.to_json()
    None => ()
  }
  event_with_base(
    EventType::RunStarted,
    fields,
    false,
    timestamp,
    raw_event,
    metadata,
    None,
  )
}

///|
/// Build an explicit run outcome.
pub fn run_finished_outcome_success(
  pending_tool_call_ids? : Array[String],
) -> Json {
  let fields : Map[String, Json] = Map([("type", Json::string("success"))])
  put_optional_strings(fields, "pendingToolCallIds", pending_tool_call_ids)
  json_object(fields)
}

///|
/// Build an interrupt run outcome.
pub fn run_finished_outcome_interrupt(interrupts : Array[Interrupt]) -> Json {
  json_object(
    Map([
      ("type", Json::string("interrupt")),
      (
        "interrupts",
        Json::array([ for value in interrupts => value.to_json() ]),
      ),
    ]),
  )
}

///|
/// Build a cancelled run outcome.
pub fn run_finished_outcome_cancelled() -> Json {
  json_object(Map([("type", Json::string("cancelled"))]))
}

///|
/// Build a RUN_FINISHED event with result, outcome, and token usage.
pub fn AgUiEvent::run_finished_full(
  thread_id~ : String,
  run_id~ : String,
  result? : Json,
  outcome? : Json,
  usage? : Array[TokenUsage],
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([
    ("threadId", Json::string(thread_id)),
    ("runId", Json::string(run_id)),
  ])
  put_optional_json(fields, "result", result)
  put_optional_json(fields, "outcome", outcome)
  put_usage(fields, usage)
  event_with_base(
    EventType::RunFinished,
    fields,
    false,
    timestamp,
    raw_event,
    metadata,
    None,
  )
}

///|
/// Build a RUN_ERROR event with optional code and usage.
pub fn AgUiEvent::run_error_full(
  message~ : String,
  code? : String,
  usage? : Array[TokenUsage],
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([("message", Json::string(message))])
  put_optional_string(fields, "code", code)
  put_usage(fields, usage)
  event_with_base(
    EventType::RunError,
    fields,
    false,
    timestamp,
    raw_event,
    metadata,
    None,
  )
}

///|
/// Build a reasoning stream start.
pub fn AgUiEvent::reasoning_start(
  message_id~ : String,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
  subagent_run_id? : String,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([("messageId", Json::string(message_id))])
  event_with_base(
    EventType::ReasoningStart,
    fields,
    true,
    timestamp,
    raw_event,
    metadata,
    subagent_run_id,
  )
}

///|
/// Build a reasoning message start. The role is normally `reasoning`.
pub fn AgUiEvent::reasoning_message_start(
  message_id~ : String,
  role? : String = "reasoning",
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
  subagent_run_id? : String,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([
    ("messageId", Json::string(message_id)),
    ("role", Json::string(role)),
  ])
  event_with_base(
    EventType::ReasoningMessageStart,
    fields,
    true,
    timestamp,
    raw_event,
    metadata,
    subagent_run_id,
  )
}

///|
/// Build a reasoning message content delta.
pub fn AgUiEvent::reasoning_message_content(
  message_id~ : String,
  delta~ : String,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
  subagent_run_id? : String,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([
    ("messageId", Json::string(message_id)),
    ("delta", Json::string(delta)),
  ])
  event_with_base(
    EventType::ReasoningMessageContent,
    fields,
    true,
    timestamp,
    raw_event,
    metadata,
    subagent_run_id,
  )
}

///|
/// Build a reasoning message end.
pub fn AgUiEvent::reasoning_message_end(
  message_id~ : String,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
  subagent_run_id? : String,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([("messageId", Json::string(message_id))])
  event_with_base(
    EventType::ReasoningMessageEnd,
    fields,
    true,
    timestamp,
    raw_event,
    metadata,
    subagent_run_id,
  )
}

///|
/// Build a REASONING_MESSAGE_CHUNK event.
pub fn AgUiEvent::reasoning_message_chunk(
  message_id? : String,
  delta? : String,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
  subagent_run_id? : String,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([])
  put_optional_string(fields, "messageId", message_id)
  put_optional_string(fields, "delta", delta)
  event_with_base(
    EventType::ReasoningMessageChunk,
    fields,
    true,
    timestamp,
    raw_event,
    metadata,
    subagent_run_id,
  )
}

///|
/// Build a reasoning stream end.
pub fn AgUiEvent::reasoning_end(
  message_id~ : String,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
  subagent_run_id? : String,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([("messageId", Json::string(message_id))])
  event_with_base(
    EventType::ReasoningEnd,
    fields,
    true,
    timestamp,
    raw_event,
    metadata,
    subagent_run_id,
  )
}

///|
/// Build a REASONING_ENCRYPTED_VALUE event.
pub fn AgUiEvent::reasoning_encrypted_value(
  subtype~ : String,
  entity_id~ : String,
  encrypted_value~ : String,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
  subagent_run_id? : String,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([
    ("subtype", Json::string(subtype)),
    ("entityId", Json::string(entity_id)),
    ("encryptedValue", Json::string(encrypted_value)),
  ])
  event_with_base(
    EventType::ReasoningEncryptedValue,
    fields,
    true,
    timestamp,
    raw_event,
    metadata,
    subagent_run_id,
  )
}

///|
/// Build a SUBAGENT_STARTED event.
pub fn AgUiEvent::subagent_started(
  subagent_run_id~ : String,
  name~ : String,
  description? : String,
  parent_subagent_run_id? : String,
  parent_tool_call_id? : String,
  parent_message_id? : String,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([
    ("subagentRunId", Json::string(subagent_run_id)),
    ("name", Json::string(name)),
  ])
  put_optional_string(fields, "description", description)
  put_optional_string(fields, "parentSubagentRunId", parent_subagent_run_id)
  put_optional_string(fields, "parentToolCallId", parent_tool_call_id)
  put_optional_string(fields, "parentMessageId", parent_message_id)
  event_with_base(
    EventType::SubagentStarted,
    fields,
    false,
    timestamp,
    raw_event,
    metadata,
    None,
  )
}

///|
/// Build a successful or suspended subagent outcome.
pub fn subagent_finished_outcome(
  suspended : Bool,
  interrupt_ids? : Array[String],
) -> Json {
  let fields : Map[String, Json] = Map([
    ("type", Json::string(if suspended { "suspended" } else { "success" })),
  ])
  if suspended {
    put_optional_strings(fields, "interruptIds", interrupt_ids)
  }
  json_object(fields)
}

///|
/// Build a SUBAGENT_FINISHED event.
pub fn AgUiEvent::subagent_finished(
  subagent_run_id~ : String,
  result? : Json,
  outcome? : Json,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([
    ("subagentRunId", Json::string(subagent_run_id)),
  ])
  put_optional_json(fields, "result", result)
  put_optional_json(fields, "outcome", outcome)
  event_with_base(
    EventType::SubagentFinished,
    fields,
    false,
    timestamp,
    raw_event,
    metadata,
    None,
  )
}

///|
/// Build a SUBAGENT_ERROR event.
pub fn AgUiEvent::subagent_error(
  subagent_run_id~ : String,
  message~ : String,
  code? : String,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([
    ("subagentRunId", Json::string(subagent_run_id)),
    ("message", Json::string(message)),
  ])
  put_optional_string(fields, "code", code)
  event_with_base(
    EventType::SubagentError,
    fields,
    false,
    timestamp,
    raw_event,
    metadata,
    None,
  )
}
