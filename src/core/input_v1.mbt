///|
/// Typed message and RunAgentInput conveniences generated from AG-UI 1.0.
fn message_value(fields : Map[String, Json]) -> Message {
  { value: Json::object(fields), }
}

///|
fn message_base(id : String, role : String) -> Map[String, Json] {
  Map([("id", Json::string(id)), ("role", Json::string(role))])
}

///|
fn put_content_parts(
  fields : Map[String, Json],
  parts : Array[ContentPart],
) -> Unit {
  fields["content"] = Json::array([ for part in parts => part.to_json() ])
}

///|
/// Build a developer message.
pub fn Message::developer(
  id~ : String,
  content~ : String,
  name? : String,
  encrypted_value? : String,
  metadata? : Json,
  subagent_run_id? : String,
) -> Message {
  let fields = message_base(id, "developer")
  fields["content"] = Json::string(content)
  put_optional_string(fields, "name", name)
  put_optional_string(fields, "encryptedValue", encrypted_value)
  put_optional_json(fields, "metadata", metadata)
  put_optional_string(fields, "subagentRunId", subagent_run_id)
  message_value(fields)
}

///|
/// Build a system message.
pub fn Message::system(
  id~ : String,
  content~ : String,
  name? : String,
  encrypted_value? : String,
  metadata? : Json,
  subagent_run_id? : String,
) -> Message {
  let fields = message_base(id, "system")
  fields["content"] = Json::string(content)
  put_optional_string(fields, "name", name)
  put_optional_string(fields, "encryptedValue", encrypted_value)
  put_optional_json(fields, "metadata", metadata)
  put_optional_string(fields, "subagentRunId", subagent_run_id)
  message_value(fields)
}

///|
/// Build an assistant message with optional tool calls.
pub fn Message::assistant(
  id~ : String,
  content? : String,
  tool_calls? : Array[ToolCall],
  name? : String,
  metadata? : Json,
  encrypted_value? : String,
  subagent_run_id? : String,
) -> Message {
  let fields = message_base(id, "assistant")
  put_optional_string(fields, "content", content)
  match tool_calls {
    Some(values) =>
      fields["toolCalls"] = Json::array(
        [
          for value in values => value.to_json()
        ],
      )
    None => ()
  }
  put_optional_string(fields, "name", name)
  put_optional_json(fields, "metadata", metadata)
  put_optional_string(fields, "encryptedValue", encrypted_value)
  put_optional_string(fields, "subagentRunId", subagent_run_id)
  message_value(fields)
}

///|
/// Build a user message with string content.
pub fn Message::user(
  id~ : String,
  content~ : String,
  name? : String,
  metadata? : Json,
  encrypted_value? : String,
  subagent_run_id? : String,
) -> Message {
  let fields = message_base(id, "user")
  fields["content"] = Json::string(content)
  put_optional_string(fields, "name", name)
  put_optional_json(fields, "metadata", metadata)
  put_optional_string(fields, "encryptedValue", encrypted_value)
  put_optional_string(fields, "subagentRunId", subagent_run_id)
  message_value(fields)
}

///|
/// Build a user message with multimodal content parts.
pub fn Message::user_parts(
  id~ : String,
  content~ : Array[ContentPart],
  name? : String,
  metadata? : Json,
  encrypted_value? : String,
  subagent_run_id? : String,
) -> Message {
  let fields = message_base(id, "user")
  put_content_parts(fields, content)
  put_optional_string(fields, "name", name)
  put_optional_json(fields, "metadata", metadata)
  put_optional_string(fields, "encryptedValue", encrypted_value)
  put_optional_string(fields, "subagentRunId", subagent_run_id)
  message_value(fields)
}

///|
/// Build a tool result message with string content.
pub fn Message::tool(
  id~ : String,
  tool_call_id~ : String,
  content~ : String,
  error? : String,
  encrypted_value? : String,
  metadata? : Json,
  subagent_run_id? : String,
) -> Message {
  let fields = message_base(id, "tool")
  fields["content"] = Json::string(content)
  fields["toolCallId"] = Json::string(tool_call_id)
  put_optional_string(fields, "error", error)
  put_optional_string(fields, "encryptedValue", encrypted_value)
  put_optional_json(fields, "metadata", metadata)
  put_optional_string(fields, "subagentRunId", subagent_run_id)
  message_value(fields)
}

///|
/// Build a tool result message with multimodal content parts.
pub fn Message::tool_parts(
  id~ : String,
  tool_call_id~ : String,
  content~ : Array[ContentPart],
  error? : String,
  encrypted_value? : String,
  metadata? : Json,
  subagent_run_id? : String,
) -> Message {
  let fields = message_base(id, "tool")
  put_content_parts(fields, content)
  fields["toolCallId"] = Json::string(tool_call_id)
  put_optional_string(fields, "error", error)
  put_optional_string(fields, "encryptedValue", encrypted_value)
  put_optional_json(fields, "metadata", metadata)
  put_optional_string(fields, "subagentRunId", subagent_run_id)
  message_value(fields)
}

///|
/// Build an activity message. Activity content is an arbitrary JSON object.
pub fn Message::activity(
  id~ : String,
  activity_type~ : String,
  content~ : Json,
  metadata? : Json,
  subagent_run_id? : String,
) -> Message {
  let fields = message_base(id, "activity")
  fields["activityType"] = Json::string(activity_type)
  fields["content"] = content
  put_optional_json(fields, "metadata", metadata)
  put_optional_string(fields, "subagentRunId", subagent_run_id)
  message_value(fields)
}

///|
/// Build a reasoning message.
pub fn Message::reasoning(
  id~ : String,
  content~ : String,
  encrypted_value? : String,
  metadata? : Json,
  subagent_run_id? : String,
) -> Message {
  let fields = message_base(id, "reasoning")
  fields["content"] = Json::string(content)
  put_optional_string(fields, "encryptedValue", encrypted_value)
  put_optional_json(fields, "metadata", metadata)
  put_optional_string(fields, "subagentRunId", subagent_run_id)
  message_value(fields)
}

///|
/// Return the message id, if the message was decoded from a valid object.
pub fn Message::id(self : Message) -> String {
  match self.value {
    { "id": String(value), .. } => value
    _ => ""
  }
}

///|
/// Return the message role, if present.
pub fn Message::role_name(self : Message) -> String {
  match self.value {
    { "role": String(value), .. } => value
    _ => ""
  }
}

///|
/// Return the raw content value, preserving string, parts, or activity objects.
pub fn Message::content(self : Message) -> Json? {
  match self.value {
    { "content": value, .. } => Some(value)
    _ => None
  }
}

///|
/// Build a RunAgentInput from typed tool, context, and resume values.
pub fn RunAgentInput::new_typed(
  thread_id~ : String,
  run_id~ : String,
  messages~ : Array[Message],
  protocol_version? : String = PROTOCOL_VERSION,
  parent_run_id? : String,
  state? : Json,
  tools? : Array[Tool],
  context? : Array[Context],
  forwarded_props? : Json,
  resume? : Array[ResumeEntry],
) -> RunAgentInput {
  let fields : Map[String, Json] = Map([
    ("threadId", Json::string(thread_id)),
    ("runId", Json::string(run_id)),
    ("protocolVersion", Json::string(protocol_version)),
    ("messages", Json::array([ for message in messages => message.to_json() ])),
  ])
  match tools {
    Some(values) =>
      fields["tools"] = Json::array([ for value in values => value.to_json() ])
    None => ()
  }
  match context {
    Some(values) =>
      fields["context"] = Json::array(
        [
          for value in values => value.to_json()
        ],
      )
    None => ()
  }
  put_optional_string(fields, "parentRunId", parent_run_id)
  put_optional_json(fields, "state", state)
  put_optional_json(fields, "forwardedProps", forwarded_props)
  match resume {
    Some(values) =>
      fields["resume"] = Json::array([ for value in values => value.to_json() ])
    None => ()
  }
  { value: Json::object(fields), }
}

///|
fn object_field(value : Json, key : String) -> Json? {
  match value {
    Object(fields) => fields.get(key)
    _ => None
  }
}

///|
/// Return protocolVersion, if supplied.
pub fn RunAgentInput::protocol_version(self : RunAgentInput) -> String? {
  match object_field(self.value, "protocolVersion") {
    Some(String(value)) => Some(value)
    _ => None
  }
}

///|
/// Return parentRunId, if supplied.
pub fn RunAgentInput::parent_run_id(self : RunAgentInput) -> String? {
  match object_field(self.value, "parentRunId") {
    Some(String(value)) => Some(value)
    _ => None
  }
}

///|
/// Return the state JSON value, if supplied.
pub fn RunAgentInput::state(self : RunAgentInput) -> Json? {
  object_field(self.value, "state")
}

///|
/// Return tools as raw JSON values.
pub fn RunAgentInput::tools(self : RunAgentInput) -> Array[Json] {
  match object_field(self.value, "tools") {
    Some(Array(values)) => values
    _ => []
  }
}

///|
/// Return context as raw JSON values.
pub fn RunAgentInput::context(self : RunAgentInput) -> Array[Json] {
  match object_field(self.value, "context") {
    Some(Array(values)) => values
    _ => []
  }
}

///|
/// Return forwarded properties, if supplied.
pub fn RunAgentInput::forwarded_props(self : RunAgentInput) -> Json? {
  object_field(self.value, "forwardedProps")
}

///|
/// Return resume entries as raw JSON values.
pub fn RunAgentInput::resume(self : RunAgentInput) -> Array[Json] {
  match object_field(self.value, "resume") {
    Some(Array(values)) => values
    _ => []
  }
}
