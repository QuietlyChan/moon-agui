///|
/// AG-UI protocol event names from the 1.0 schema.
pub(all) enum EventType {
  TextMessageStart
  TextMessageContent
  TextMessageEnd
  TextMessageChunk
  ToolCallStart
  ToolCallArgs
  ToolCallEnd
  ToolCallChunk
  ToolCallResult
  StateSnapshot
  StateDelta
  MessagesSnapshot
  ActivitySnapshot
  ActivityDelta
  Raw
  Custom
  RunStarted
  RunFinished
  RunError
  StepStarted
  StepFinished
  ReasoningStart
  ReasoningMessageStart
  ReasoningMessageContent
  ReasoningMessageEnd
  ReasoningMessageChunk
  ReasoningEnd
  ReasoningEncryptedValue
  SubagentStarted
  SubagentFinished
  SubagentError
  Other(String)
}

///|
/// Convert a protocol event name to its MoonBit variant, retaining future names.
pub fn EventType::from_wire_name(name : String) -> EventType {
  match name {
    "TEXT_MESSAGE_START" => TextMessageStart
    "TEXT_MESSAGE_CONTENT" => TextMessageContent
    "TEXT_MESSAGE_END" => TextMessageEnd
    "TEXT_MESSAGE_CHUNK" => TextMessageChunk
    "TOOL_CALL_START" => ToolCallStart
    "TOOL_CALL_ARGS" => ToolCallArgs
    "TOOL_CALL_END" => ToolCallEnd
    "TOOL_CALL_CHUNK" => ToolCallChunk
    "TOOL_CALL_RESULT" => ToolCallResult
    "STATE_SNAPSHOT" => StateSnapshot
    "STATE_DELTA" => StateDelta
    "MESSAGES_SNAPSHOT" => MessagesSnapshot
    "ACTIVITY_SNAPSHOT" => ActivitySnapshot
    "ACTIVITY_DELTA" => ActivityDelta
    "RAW" => Raw
    "CUSTOM" => Custom
    "RUN_STARTED" => RunStarted
    "RUN_FINISHED" => RunFinished
    "RUN_ERROR" => RunError
    "STEP_STARTED" => StepStarted
    "STEP_FINISHED" => StepFinished
    "REASONING_START" => ReasoningStart
    "REASONING_MESSAGE_START" => ReasoningMessageStart
    "REASONING_MESSAGE_CONTENT" => ReasoningMessageContent
    "REASONING_MESSAGE_END" => ReasoningMessageEnd
    "REASONING_MESSAGE_CHUNK" => ReasoningMessageChunk
    "REASONING_END" => ReasoningEnd
    "REASONING_ENCRYPTED_VALUE" => ReasoningEncryptedValue
    "SUBAGENT_STARTED" => SubagentStarted
    "SUBAGENT_FINISHED" => SubagentFinished
    "SUBAGENT_ERROR" => SubagentError
    _ => Other(name)
  }
}

///|
/// Return the canonical AG-UI discriminator for an event type.
pub fn EventType::wire_name(self : EventType) -> String {
  match self {
    TextMessageStart => "TEXT_MESSAGE_START"
    TextMessageContent => "TEXT_MESSAGE_CONTENT"
    TextMessageEnd => "TEXT_MESSAGE_END"
    TextMessageChunk => "TEXT_MESSAGE_CHUNK"
    ToolCallStart => "TOOL_CALL_START"
    ToolCallArgs => "TOOL_CALL_ARGS"
    ToolCallEnd => "TOOL_CALL_END"
    ToolCallChunk => "TOOL_CALL_CHUNK"
    ToolCallResult => "TOOL_CALL_RESULT"
    StateSnapshot => "STATE_SNAPSHOT"
    StateDelta => "STATE_DELTA"
    MessagesSnapshot => "MESSAGES_SNAPSHOT"
    ActivitySnapshot => "ACTIVITY_SNAPSHOT"
    ActivityDelta => "ACTIVITY_DELTA"
    Raw => "RAW"
    Custom => "CUSTOM"
    RunStarted => "RUN_STARTED"
    RunFinished => "RUN_FINISHED"
    RunError => "RUN_ERROR"
    StepStarted => "STEP_STARTED"
    StepFinished => "STEP_FINISHED"
    ReasoningStart => "REASONING_START"
    ReasoningMessageStart => "REASONING_MESSAGE_START"
    ReasoningMessageContent => "REASONING_MESSAGE_CONTENT"
    ReasoningMessageEnd => "REASONING_MESSAGE_END"
    ReasoningMessageChunk => "REASONING_MESSAGE_CHUNK"
    ReasoningEnd => "REASONING_END"
    ReasoningEncryptedValue => "REASONING_ENCRYPTED_VALUE"
    SubagentStarted => "SUBAGENT_STARTED"
    SubagentFinished => "SUBAGENT_FINISHED"
    SubagentError => "SUBAGENT_ERROR"
    Other(name) => name
  }
}

///|
/// A top-level AG-UI event object with a decoded discriminator.
///
/// The original JSON object is retained so fields added by newer protocol
/// versions or integrations survive decoding and re-encoding.
pub struct AgUiEvent {
  event_type : EventType
  value : Json
}

///|
/// Build an event with arbitrary protocol fields. The SDK always owns `type`.
pub fn AgUiEvent::new(
  event_type~ : EventType,
  fields~ : Map[String, Json],
) -> AgUiEvent {
  let value : Map[String, Json] = Map([
    ("type", Json::string(event_type.wire_name())),
  ])
  for key, field in fields {
    if key != "type" {
      value[key] = field
    }
  }
  { event_type, value: Json::object(value), }
}

///|
/// Decode an event object while preserving every field, including unknown ones.
pub fn AgUiEvent::from_json(value : Json) -> AgUiEvent raise {
  match value {
    { "type": String(name), .. } =>
      { event_type: EventType::from_wire_name(name), value, }
    _ => fail("AG-UI event must be an object with a string type field")
  }
}

///|
/// Decode an event from compact or whitespace-formatted JSON text.
pub fn AgUiEvent::from_json_string(value : String) -> AgUiEvent raise {
  AgUiEvent::from_json(@json.parse(value))
}

///|
/// Return the event's discriminator.
pub fn AgUiEvent::event_type(self : AgUiEvent) -> EventType {
  self.event_type
}

///|
/// Return the complete event as JSON.
pub fn AgUiEvent::to_json(self : AgUiEvent) -> Json {
  self.value
}

///|
/// Encode the event as compact JSON with AG-UI camelCase keys.
pub fn AgUiEvent::to_json_string(self : AgUiEvent) -> String {
  self.value.stringify()
}

///|
/// Return a string-valued event field when present.
pub fn AgUiEvent::string_field(self : AgUiEvent, name : String) -> String? {
  match self.value {
    Object(fields) =>
      match fields.get(name) {
        Some(String(value)) => Some(value)
        _ => None
      }
    _ => None
  }
}

///|
/// Build a run-start event with the required thread and run identifiers.
pub fn AgUiEvent::run_started(
  thread_id~ : String,
  run_id~ : String,
) -> AgUiEvent {
  AgUiEvent::new(
    event_type=EventType::RunStarted,
    fields=Map([
      ("threadId", Json::string(thread_id)),
      ("runId", Json::string(run_id)),
    ]),
  )
}

///|
/// Build a run-finished event.
pub fn AgUiEvent::run_finished(
  thread_id~ : String,
  run_id~ : String,
) -> AgUiEvent {
  AgUiEvent::new(
    event_type=EventType::RunFinished,
    fields=Map([
      ("threadId", Json::string(thread_id)),
      ("runId", Json::string(run_id)),
    ]),
  )
}

///|
/// Build a run-error event.
pub fn AgUiEvent::run_error(message~ : String, code? : String) -> AgUiEvent {
  let fields : Map[String, Json] = Map([("message", Json::string(message))])
  match code {
    Some(value) => fields["code"] = Json::string(value)
    None => ()
  }
  AgUiEvent::new(event_type=EventType::RunError, fields~)
}

///|
/// Build a step-start event.
pub fn AgUiEvent::step_started(step_name~ : String) -> AgUiEvent {
  AgUiEvent::new(
    event_type=EventType::StepStarted,
    fields=Map([("stepName", Json::string(step_name))]),
  )
}

///|
/// Build a step-finished event.
pub fn AgUiEvent::step_finished(step_name~ : String) -> AgUiEvent {
  AgUiEvent::new(
    event_type=EventType::StepFinished,
    fields=Map([("stepName", Json::string(step_name))]),
  )
}

///|
/// Build a text-message-start event. The official role field is optional.
pub fn AgUiEvent::text_message_start(
  message_id~ : String,
  role? : String = "assistant",
) -> AgUiEvent {
  AgUiEvent::new(
    event_type=EventType::TextMessageStart,
    fields=Map([
      ("messageId", Json::string(message_id)),
      ("role", Json::string(role)),
    ]),
  )
}

///|
/// Build a text delta for an open message.
pub fn AgUiEvent::text_message_content(
  message_id~ : String,
  delta~ : String,
) -> AgUiEvent {
  AgUiEvent::new(
    event_type=EventType::TextMessageContent,
    fields=Map([
      ("messageId", Json::string(message_id)),
      ("delta", Json::string(delta)),
    ]),
  )
}

///|
/// Build a text-message-end event.
pub fn AgUiEvent::text_message_end(message_id~ : String) -> AgUiEvent {
  AgUiEvent::new(
    event_type=EventType::TextMessageEnd,
    fields=Map([("messageId", Json::string(message_id))]),
  )
}

///|
/// Build a tool-call-start event.
pub fn AgUiEvent::tool_call_start(
  tool_call_id~ : String,
  tool_call_name~ : String,
  parent_message_id? : String,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([
    ("toolCallId", Json::string(tool_call_id)),
    ("toolCallName", Json::string(tool_call_name)),
  ])
  match parent_message_id {
    Some(value) => fields["parentMessageId"] = Json::string(value)
    None => ()
  }
  AgUiEvent::new(event_type=EventType::ToolCallStart, fields~)
}

///|
/// Build an incremental tool-call arguments event.
pub fn AgUiEvent::tool_call_args(
  tool_call_id~ : String,
  delta~ : String,
) -> AgUiEvent {
  AgUiEvent::new(
    event_type=EventType::ToolCallArgs,
    fields=Map([
      ("toolCallId", Json::string(tool_call_id)),
      ("delta", Json::string(delta)),
    ]),
  )
}

///|
/// Build a tool-call-end event.
pub fn AgUiEvent::tool_call_end(tool_call_id~ : String) -> AgUiEvent {
  AgUiEvent::new(
    event_type=EventType::ToolCallEnd,
    fields=Map([("toolCallId", Json::string(tool_call_id))]),
  )
}

///|
/// Build a tool result event. `content` may be text or structured content parts.
pub fn AgUiEvent::tool_call_result(
  message_id~ : String,
  tool_call_id~ : String,
  content~ : Json,
) -> AgUiEvent {
  AgUiEvent::new(
    event_type=EventType::ToolCallResult,
    fields=Map([
      ("messageId", Json::string(message_id)),
      ("toolCallId", Json::string(tool_call_id)),
      ("content", content),
      ("role", Json::string("tool")),
    ]),
  )
}

///|
/// Build a full shared-state snapshot event.
pub fn AgUiEvent::state_snapshot(snapshot : Json) -> AgUiEvent {
  AgUiEvent::new(
    event_type=EventType::StateSnapshot,
    fields=Map([("snapshot", snapshot)]),
  )
}

///|
/// Build a JSON Patch state-delta event.
pub fn AgUiEvent::state_delta(delta : Json) -> AgUiEvent {
  AgUiEvent::new(
    event_type=EventType::StateDelta,
    fields=Map([("delta", delta)]),
  )
}

///|
/// Build a messages-snapshot event.
pub fn AgUiEvent::messages_snapshot(messages : Array[Json]) -> AgUiEvent {
  AgUiEvent::new(
    event_type=EventType::MessagesSnapshot,
    fields=Map([("messages", Json::array(messages))]),
  )
}

///|
/// Build a custom application event.
pub fn AgUiEvent::custom(name~ : String, value~ : Json) -> AgUiEvent {
  AgUiEvent::new(
    event_type=EventType::Custom,
    fields=Map([("name", Json::string(name)), ("value", value)]),
  )
}
