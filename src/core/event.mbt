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
    { "type": String(name), .. } => {
      let event_type = EventType::from_wire_name(name)
      validate_known_event(event_type, value)
      { event_type, value, }
    }
    _ => fail("AG-UI event must be an object with a string type field")
  }
}

///|
fn field(value : Json, name : String) -> Json? {
  match value {
    Object(fields) => fields.get(name)
    _ => None
  }
}

///|
fn required_field(
  value : Json,
  name : String,
  event_name : String,
) -> Json raise {
  match field(value, name) {
    Some(value) => value
    None => fail(event_name + " requires " + name)
  }
}

///|
fn required_string(
  value : Json,
  name : String,
  event_name : String,
) -> String raise {
  match required_field(value, name, event_name) {
    String(value) => value
    _ => fail(event_name + " requires string " + name)
  }
}

///|
fn required_object(
  value : Json,
  name : String,
  event_name : String,
) -> Unit raise {
  match required_field(value, name, event_name) {
    Object(_) => ()
    _ => fail(event_name + " requires object " + name)
  }
}

///|
fn validate_optional_string(
  value : Json,
  name : String,
  event_name : String,
) -> Unit raise {
  match field(value, name) {
    Some(String(_)) | None => ()
    Some(_) => fail(event_name + " " + name + " must be a string")
  }
}

///|
fn validate_optional_bool(
  value : Json,
  name : String,
  event_name : String,
) -> Unit raise {
  match field(value, name) {
    Some(True) | Some(False) | None => ()
    Some(_) => fail(event_name + " " + name + " must be a boolean")
  }
}

///|
fn validate_integer(
  value : Json,
  label : String,
  minimum : Double,
  maximum : Double,
) -> Unit raise {
  match value {
    Number(number, ..) => {
      guard number == number.floor() else {
        fail(label + " must be an integer")
      }
      guard number >= minimum && number <= maximum else {
        fail(label + " is outside the supported range")
      }
    }
    _ => fail(label + " must be a number")
  }
}

///|
fn validate_optional_integer(
  value : Json,
  name : String,
  event_name : String,
  minimum : Double,
  maximum : Double,
) -> Unit raise {
  match field(value, name) {
    Some(value) =>
      validate_integer(value, event_name + " " + name, minimum, maximum)
    None => ()
  }
}

///|
fn validate_optional_base(value : Json, event_name : String) -> Unit raise {
  match value {
    Object(fields) => {
      validate_optional_integer(
        value, "timestamp", event_name, -9007199254740991.0, 9007199254740991.0,
      )
      match fields.get("metadata") {
        Some(Object(_)) => ()
        Some(_) => fail(event_name + " metadata must be an object")
        None => ()
      }
      match fields.get("rawEvent") {
        Some(Null) => fail(event_name + " rawEvent cannot be null")
        _ => ()
      }
      match fields.get("subagentRunId") {
        Some(String(_)) => ()
        Some(_) => fail(event_name + " subagentRunId must be a string")
        None => ()
      }
    }
    _ => fail(event_name + " must be an object")
  }
}

///|
fn validate_usage(value : Json, event_name : String) -> Unit raise {
  match value {
    Array(entries) =>
      for entry in entries {
        match entry {
          Object(_) => {
            validate_optional_string(entry, "provider", event_name)
            validate_optional_string(entry, "model", event_name)
            for
              name in [
                "inputTokens", "outputTokens", "totalTokens", "reasoningTokens",
                "cachedInputTokens", "cacheWriteInputTokens",
              ] {
              validate_optional_integer(
                entry, name, event_name, 0.0, 9007199254740991.0,
              )
            }
          }
          _ => fail(event_name + " usage entries must be objects")
        }
      }
    _ => fail(event_name + " usage must be an array")
  }
}

///|
fn validate_run_outcome(value : Json, event_name : String) -> Unit raise {
  let kind = required_string(value, "type", event_name + " outcome")
  match kind {
    "success" => {
      match field(value, "pendingToolCallIds") {
        Some(Array(ids)) =>
          for id in ids {
            match id {
              String(_) => ()
              _ => fail(event_name + " pending tool call ids must be strings")
            }
          }
        Some(_) => fail(event_name + " pendingToolCallIds must be an array")
        None => ()
      }
      match field(value, "interrupts") {
        Some(_) =>
          fail(event_name + " success outcome cannot contain interrupts")
        None => ()
      }
    }
    "interrupt" => {
      match field(value, "pendingToolCallIds") {
        Some(_) =>
          fail(
            event_name + " interrupt outcome cannot contain pendingToolCallIds",
          )
        None => ()
      }
      match required_field(value, "interrupts", event_name + " outcome") {
        Array(interrupts) => {
          guard interrupts.length() > 0 else {
            fail(event_name + " interrupt outcome requires an interrupt")
          }
          for interrupt in interrupts {
            ignore(required_string(interrupt, "id", event_name + " interrupt"))
            ignore(
              required_string(interrupt, "reason", event_name + " interrupt"),
            )
          }
        }
        _ => fail(event_name + " interrupts must be an array")
      }
    }
    "cancelled" => {
      match field(value, "interrupts") {
        Some(_) =>
          fail(event_name + " cancelled outcome cannot contain interrupts")
        None => ()
      }
      match field(value, "pendingToolCallIds") {
        Some(_) =>
          fail(
            event_name + " cancelled outcome cannot contain pendingToolCallIds",
          )
        None => ()
      }
    }
    _ => fail(event_name + " outcome type is invalid")
  }
}

///|
fn validate_subagent_outcome(value : Json, event_name : String) -> Unit raise {
  let kind = required_string(value, "type", event_name + " outcome")
  match kind {
    "success" =>
      match field(value, "interruptIds") {
        Some(_) =>
          fail(event_name + " success outcome cannot contain interruptIds")
        None => ()
      }
    "suspended" =>
      match field(value, "interruptIds") {
        Some(Array(ids)) =>
          for id in ids {
            match id {
              String(_) => ()
              _ => fail(event_name + " interruptIds must be strings")
            }
          }
        Some(_) => fail(event_name + " interruptIds must be an array")
        None => ()
      }
    _ => fail(event_name + " outcome type is invalid")
  }
}

///|
fn validate_known_event(event_type : EventType, value : Json) -> Unit raise {
  let event_name = event_type.wire_name()
  validate_optional_base(value, event_name)
  match event_type {
    EventType::TextMessageStart => {
      ignore(required_string(value, "messageId", event_name))
      match field(value, "role") {
        Some(String(role)) => {
          guard role == "developer" ||
            role == "system" ||
            role == "assistant" ||
            role == "user" else {
            fail(event_name + " role is invalid")
          }
        }
        Some(_) => fail(event_name + " role must be a string")
        None => ()
      }
      validate_optional_string(value, "name", event_name)
    }
    EventType::TextMessageContent => {
      ignore(required_string(value, "messageId", event_name))
      ignore(required_string(value, "delta", event_name))
    }
    EventType::TextMessageEnd =>
      ignore(required_string(value, "messageId", event_name))
    EventType::TextMessageChunk => {
      validate_optional_string(value, "messageId", event_name)
      validate_optional_string(value, "role", event_name)
      validate_optional_string(value, "delta", event_name)
      validate_optional_string(value, "name", event_name)
      match field(value, "role") {
        Some(String(role)) => {
          guard role == "developer" ||
            role == "system" ||
            role == "assistant" ||
            role == "user" else {
            fail(event_name + " role is invalid")
          }
        }
        _ => ()
      }
    }
    EventType::ToolCallStart => {
      ignore(required_string(value, "toolCallId", event_name))
      ignore(required_string(value, "toolCallName", event_name))
      validate_optional_string(value, "parentMessageId", event_name)
    }
    EventType::ToolCallArgs => {
      ignore(required_string(value, "toolCallId", event_name))
      ignore(required_string(value, "delta", event_name))
    }
    EventType::ToolCallEnd =>
      ignore(required_string(value, "toolCallId", event_name))
    EventType::ToolCallChunk => {
      validate_optional_string(value, "toolCallId", event_name)
      validate_optional_string(value, "toolCallName", event_name)
      validate_optional_string(value, "parentMessageId", event_name)
      validate_optional_string(value, "delta", event_name)
    }
    EventType::ToolCallResult => {
      ignore(required_string(value, "messageId", event_name))
      ignore(required_string(value, "toolCallId", event_name))
      let content = required_field(value, "content", event_name)
      match content {
        String(_) => ()
        Array(_) => validate_content_parts(content, event_name)
        _ =>
          fail(event_name + " content must be a string or content-part array")
      }
      match field(value, "role") {
        Some(String(role)) if role == "tool" => ()
        Some(String(_)) => fail(event_name + " role must be tool")
        Some(_) => fail(event_name + " role must be a string")
        None => ()
      }
    }
    EventType::StateSnapshot =>
      ignore(required_field(value, "snapshot", event_name))
    EventType::StateDelta =>
      validate_json_patch(
        required_field(value, "delta", event_name),
        event_name,
      )
    EventType::MessagesSnapshot =>
      match required_field(value, "messages", event_name) {
        Array(messages) =>
          for message in messages {
            ignore(Message::from_json(message))
          }
        _ => fail(event_name + " requires array messages")
      }
    EventType::ActivitySnapshot => {
      ignore(required_string(value, "messageId", event_name))
      ignore(required_string(value, "activityType", event_name))
      required_object(value, "content", event_name)
      validate_optional_bool(value, "replace", event_name)
    }
    EventType::ActivityDelta => {
      ignore(required_string(value, "messageId", event_name))
      ignore(required_string(value, "activityType", event_name))
      validate_json_patch(
        required_field(value, "patch", event_name),
        event_name,
      )
    }
    EventType::Raw => {
      ignore(required_field(value, "event", event_name))
      validate_optional_string(value, "source", event_name)
    }
    EventType::Custom => {
      ignore(required_string(value, "name", event_name))
      ignore(required_field(value, "value", event_name))
    }
    EventType::RunStarted => {
      ignore(required_string(value, "threadId", event_name))
      ignore(required_string(value, "runId", event_name))
      validate_optional_string(value, "protocolVersion", event_name)
      validate_optional_string(value, "parentRunId", event_name)
      match field(value, "input") {
        Some(input) => ignore(RunAgentInput::from_json(input))
        None => ()
      }
    }
    EventType::RunFinished => {
      ignore(required_string(value, "threadId", event_name))
      ignore(required_string(value, "runId", event_name))
      match field(value, "outcome") {
        Some(outcome) => validate_run_outcome(outcome, event_name)
        None => ()
      }
      match field(value, "usage") {
        Some(usage) => validate_usage(usage, event_name)
        None => ()
      }
    }
    EventType::RunError => {
      ignore(required_string(value, "message", event_name))
      validate_optional_string(value, "code", event_name)
      match field(value, "usage") {
        Some(usage) => validate_usage(usage, event_name)
        None => ()
      }
    }
    EventType::StepStarted | EventType::StepFinished =>
      ignore(required_string(value, "stepName", event_name))
    EventType::ReasoningStart
    | EventType::ReasoningMessageEnd
    | EventType::ReasoningEnd =>
      ignore(required_string(value, "messageId", event_name))
    EventType::ReasoningMessageStart => {
      ignore(required_string(value, "messageId", event_name))
      let role = required_string(value, "role", event_name)
      guard role == "reasoning" else {
        fail(event_name + " role must be reasoning")
      }
    }
    EventType::ReasoningMessageContent => {
      ignore(required_string(value, "messageId", event_name))
      ignore(required_string(value, "delta", event_name))
    }
    EventType::ReasoningMessageChunk => {
      validate_optional_string(value, "messageId", event_name)
      validate_optional_string(value, "delta", event_name)
    }
    EventType::ReasoningEncryptedValue => {
      let subtype = required_string(value, "subtype", event_name)
      guard subtype == "tool-call" || subtype == "message" else {
        fail(event_name + " subtype must be tool-call or message")
      }
      ignore(required_string(value, "entityId", event_name))
      ignore(required_string(value, "encryptedValue", event_name))
    }
    EventType::SubagentStarted => {
      ignore(required_string(value, "subagentRunId", event_name))
      ignore(required_string(value, "name", event_name))
      validate_optional_string(value, "description", event_name)
      validate_optional_string(value, "parentSubagentRunId", event_name)
      validate_optional_string(value, "parentToolCallId", event_name)
      validate_optional_string(value, "parentMessageId", event_name)
    }
    EventType::SubagentFinished => {
      ignore(required_string(value, "subagentRunId", event_name))
      match field(value, "outcome") {
        Some(outcome) => validate_subagent_outcome(outcome, event_name)
        None => ()
      }
    }
    EventType::SubagentError => {
      ignore(required_string(value, "subagentRunId", event_name))
      ignore(required_string(value, "message", event_name))
      validate_optional_string(value, "code", event_name)
    }
    EventType::Other(_) => ()
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
  protocol_version? : String,
  parent_run_id? : String,
  input? : RunAgentInput,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
) -> AgUiEvent {
  AgUiEvent::run_started_full(
    thread_id~,
    run_id~,
    protocol_version?,
    parent_run_id?,
    input?,
    timestamp?,
    raw_event?,
    metadata?,
  )
}

///|
/// Build a run-finished event.
pub fn AgUiEvent::run_finished(
  thread_id~ : String,
  run_id~ : String,
  result? : Json,
  outcome? : Json,
  usage? : Array[TokenUsage],
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
) -> AgUiEvent {
  AgUiEvent::run_finished_full(
    thread_id~,
    run_id~,
    result?,
    outcome?,
    usage?,
    timestamp?,
    raw_event?,
    metadata?,
  )
}

///|
/// Build a run-error event.
pub fn AgUiEvent::run_error(
  message~ : String,
  code? : String,
  usage? : Array[TokenUsage],
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
) -> AgUiEvent {
  AgUiEvent::run_error_full(
    message~,
    code?,
    usage?,
    timestamp?,
    raw_event?,
    metadata?,
  )
}

///|
/// Build a step-start event.
pub fn AgUiEvent::step_started(
  step_name~ : String,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
  subagent_run_id? : String,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([("stepName", Json::string(step_name))])
  event_with_base(
    EventType::StepStarted,
    fields,
    true,
    timestamp,
    raw_event,
    metadata,
    subagent_run_id,
  )
}

///|
/// Build a step-finished event.
pub fn AgUiEvent::step_finished(
  step_name~ : String,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
  subagent_run_id? : String,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([("stepName", Json::string(step_name))])
  event_with_base(
    EventType::StepFinished,
    fields,
    true,
    timestamp,
    raw_event,
    metadata,
    subagent_run_id,
  )
}

///|
/// Build a text-message-start event. The official role field is optional.
pub fn AgUiEvent::text_message_start(
  message_id~ : String,
  role? : String,
  name? : String,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
  subagent_run_id? : String,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([("messageId", Json::string(message_id))])
  put_optional_string(fields, "role", role)
  put_optional_string(fields, "name", name)
  event_with_base(
    EventType::TextMessageStart,
    fields,
    true,
    timestamp,
    raw_event,
    metadata,
    subagent_run_id,
  )
}

///|
/// Build a text delta for an open message.
pub fn AgUiEvent::text_message_content(
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
    EventType::TextMessageContent,
    fields,
    true,
    timestamp,
    raw_event,
    metadata,
    subagent_run_id,
  )
}

///|
/// Build a text-message-end event.
pub fn AgUiEvent::text_message_end(
  message_id~ : String,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
  subagent_run_id? : String,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([("messageId", Json::string(message_id))])
  event_with_base(
    EventType::TextMessageEnd,
    fields,
    true,
    timestamp,
    raw_event,
    metadata,
    subagent_run_id,
  )
}

///|
/// Build a tool-call-start event.
pub fn AgUiEvent::tool_call_start(
  tool_call_id~ : String,
  tool_call_name~ : String,
  parent_message_id? : String,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
  subagent_run_id? : String,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([
    ("toolCallId", Json::string(tool_call_id)),
    ("toolCallName", Json::string(tool_call_name)),
  ])
  match parent_message_id {
    Some(value) => fields["parentMessageId"] = Json::string(value)
    None => ()
  }
  event_with_base(
    EventType::ToolCallStart,
    fields,
    true,
    timestamp,
    raw_event,
    metadata,
    subagent_run_id,
  )
}

///|
/// Build an incremental tool-call arguments event.
pub fn AgUiEvent::tool_call_args(
  tool_call_id~ : String,
  delta~ : String,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
  subagent_run_id? : String,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([
    ("toolCallId", Json::string(tool_call_id)),
    ("delta", Json::string(delta)),
  ])
  event_with_base(
    EventType::ToolCallArgs,
    fields,
    true,
    timestamp,
    raw_event,
    metadata,
    subagent_run_id,
  )
}

///|
/// Build a tool-call-end event.
pub fn AgUiEvent::tool_call_end(
  tool_call_id~ : String,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
  subagent_run_id? : String,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([
    ("toolCallId", Json::string(tool_call_id)),
  ])
  event_with_base(
    EventType::ToolCallEnd,
    fields,
    true,
    timestamp,
    raw_event,
    metadata,
    subagent_run_id,
  )
}

///|
/// Build a tool result event. `content` may be text or structured content parts.
pub fn AgUiEvent::tool_call_result(
  message_id~ : String,
  tool_call_id~ : String,
  content~ : Json,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
  subagent_run_id? : String,
) -> AgUiEvent {
  let fields : Map[String, Json] = Map([
    ("messageId", Json::string(message_id)),
    ("toolCallId", Json::string(tool_call_id)),
    ("content", content),
    ("role", Json::string("tool")),
  ])
  event_with_base(
    EventType::ToolCallResult,
    fields,
    true,
    timestamp,
    raw_event,
    metadata,
    subagent_run_id,
  )
}

///|
/// Build a full shared-state snapshot event.
pub fn AgUiEvent::state_snapshot(
  snapshot : Json,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
  subagent_run_id? : String,
) -> AgUiEvent {
  event_with_base(
    EventType::StateSnapshot,
    Map([("snapshot", snapshot)]),
    true,
    timestamp,
    raw_event,
    metadata,
    subagent_run_id,
  )
}

///|
/// Build a JSON Patch state-delta event.
pub fn AgUiEvent::state_delta(
  delta : Json,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
  subagent_run_id? : String,
) -> AgUiEvent {
  event_with_base(
    EventType::StateDelta,
    Map([("delta", delta)]),
    true,
    timestamp,
    raw_event,
    metadata,
    subagent_run_id,
  )
}

///|
/// Build a messages-snapshot event.
pub fn AgUiEvent::messages_snapshot(
  messages : Array[Json],
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
) -> AgUiEvent {
  event_with_base(
    EventType::MessagesSnapshot,
    Map([("messages", Json::array(messages))]),
    false,
    timestamp,
    raw_event,
    metadata,
    None,
  )
}

///|
/// Build a custom application event.
pub fn AgUiEvent::custom(
  name~ : String,
  value~ : Json,
  timestamp? : Int,
  raw_event? : Json,
  metadata? : Json,
  subagent_run_id? : String,
) -> AgUiEvent {
  AgUiEvent::custom_with_options(
    name~,
    value~,
    timestamp?,
    raw_event?,
    metadata?,
    subagent_run_id?,
  )
}
