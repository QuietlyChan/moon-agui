///|
/// Message roles recognized by AG-UI 1.0.
pub(all) enum Role {
  Developer
  System
  Assistant
  User
  Tool
  Activity
  Reasoning
}

///|
/// Return the lower-case role value used on the wire.
pub fn Role::wire_name(self : Role) -> String {
  match self {
    Developer => "developer"
    System => "system"
    Assistant => "assistant"
    User => "user"
    Tool => "tool"
    Activity => "activity"
    Reasoning => "reasoning"
  }
}

///|
/// An AG-UI message value. Keeping its JSON form allows multimodal and
/// integration-specific message fields to pass through unchanged.
pub struct Message {
  value : Json
}

///|
fn validate_tool_call(value : Json) -> Unit raise {
  let kind = required_model_string(value, "type", "tool call")
  guard kind == "function" else { fail("tool call type must be function") }
  let function = required_model_field(value, "function", "tool call")
  ignore(required_model_string(function, "name", "function call"))
  ignore(required_model_string(function, "arguments", "function call"))
  ignore(required_model_string(value, "id", "tool call"))
  validate_optional_model_string(value, "encryptedValue", "tool call")
  validate_optional_model_object(value, "metadata", "tool call")
}

///|
fn validate_optional_model_string(
  value : Json,
  name : String,
  label : String,
) -> Unit raise {
  match value {
    Object(fields) =>
      match fields.get(name) {
        Some(String(_)) | None => ()
        Some(_) => fail(label + " " + name + " must be a string")
      }
    _ => fail(label + " must be an object")
  }
}

///|
fn validate_optional_model_object(
  value : Json,
  name : String,
  label : String,
) -> Unit raise {
  match value {
    Object(fields) =>
      match fields.get(name) {
        Some(Object(_)) | None => ()
        Some(_) => fail(label + " " + name + " must be an object")
      }
    _ => fail(label + " must be an object")
  }
}

///|
fn validate_tool(value : Json) -> Unit raise {
  ignore(required_model_string(value, "name", "tool"))
  ignore(required_model_string(value, "description", "tool"))
  validate_optional_model_object(value, "metadata", "tool")
}

///|
fn validate_context(value : Json) -> Unit raise {
  ignore(required_model_string(value, "description", "context"))
  ignore(required_model_string(value, "value", "context"))
}

///|
fn validate_resume(value : Json) -> Unit raise {
  ignore(required_model_string(value, "interruptId", "resume entry"))
  let status = required_model_string(value, "status", "resume entry")
  guard status == "resolved" || status == "cancelled" else {
    fail("resume entry status must be resolved or cancelled")
  }
  validate_optional_model_object(value, "metadata", "resume entry")
}

///|
/// Build a simple text message.
pub fn Message::text(
  id~ : String,
  role~ : Role,
  content~ : String,
  name? : String,
) -> Message {
  let value : Map[String, Json] = Map([
    ("id", Json::string(id)),
    ("role", Json::string(role.wire_name())),
    ("content", Json::string(content)),
  ])
  match name {
    Some(author_name) => value["name"] = Json::string(author_name)
    None => ()
  }
  { value: Json::object(value), }
}

///|
/// Decode and preserve an arbitrary AG-UI message object.
pub fn Message::from_json(value : Json) -> Message raise {
  match value {
    { "id": String(_), "role": String(role), .. } => {
      validate_optional_model_string(value, "subagentRunId", "message")
      match role {
        "developer" | "system" => {
          validate_optional_model_string(value, "name", "message")
          validate_optional_model_string(value, "encryptedValue", "message")
          validate_optional_model_object(value, "metadata", "message")
          match value {
            { "content": String(_), .. } => ()
            _ => fail("developer/system messages require string content")
          }
        }
        "assistant" => {
          validate_optional_model_string(value, "name", "message")
          validate_optional_model_string(value, "encryptedValue", "message")
          validate_optional_model_object(value, "metadata", "message")
          match value {
            { "content": String(_), "toolCalls": Array(tool_calls), .. } =>
              for tool_call in tool_calls {
                validate_tool_call(tool_call)
              }
            { "content": String(_), .. } => ()
            { "toolCalls": Array(tool_calls), .. } =>
              for tool_call in tool_calls {
                validate_tool_call(tool_call)
              }
            { "content": _, .. } =>
              fail("assistant message content must be a string")
            _ => ()
          }
        }
        "user" => {
          validate_optional_model_string(value, "name", "message")
          validate_optional_model_string(value, "encryptedValue", "message")
          validate_optional_model_object(value, "metadata", "message")
          match value {
            { "content": String(_), .. } => ()
            { "content": Array(_), .. } =>
              validate_content_parts(
                required_model_field(value, "content", "user message"),
                "user message",
              )
            _ => fail("user messages require string or parts content")
          }
        }
        "tool" => {
          validate_optional_model_string(value, "error", "message")
          validate_optional_model_string(value, "encryptedValue", "message")
          validate_optional_model_object(value, "metadata", "message")
          match value {
            { "content": String(_), "toolCallId": String(_), .. } => ()
            { "content": Array(_), "toolCallId": String(_), .. } =>
              validate_content_parts(
                required_model_field(value, "content", "tool message"),
                "tool message",
              )
            _ => fail("tool messages require content and toolCallId")
          }
        }
        "activity" => {
          validate_optional_model_object(value, "metadata", "message")
          match value {
            { "activityType": String(_), "content": Object(_), .. } => ()
            _ =>
              fail("activity messages require activityType and object content")
          }
        }
        "reasoning" => {
          validate_optional_model_string(value, "encryptedValue", "message")
          validate_optional_model_object(value, "metadata", "message")
          match value {
            { "content": String(_), .. } => ()
            _ => fail("reasoning messages require string content")
          }
        }
        _ => fail("unknown AG-UI message role: " + role)
      }
      { value, }
    }
    _ => fail("AG-UI message must contain string id and role fields")
  }
}

///|
/// Return the message JSON object.
pub fn Message::to_json(self : Message) -> Json {
  self.value
}

///|
/// A parsed AG-UI RunAgentInput. Original JSON is kept to preserve extensions.
pub struct RunAgentInput {
  value : Json
}

///|
/// Construct a run input using AG-UI 1.0 fields.
pub fn RunAgentInput::new(
  thread_id~ : String,
  run_id~ : String,
  messages~ : Array[Message],
  protocol_version? : String = PROTOCOL_VERSION,
  parent_run_id? : String,
  state? : Json,
  tools? : Array[Json] = [],
  context? : Array[Json] = [],
  forwarded_props? : Json,
  resume_entries? : Array[Json],
) -> RunAgentInput {
  let fields : Map[String, Json] = Map([
    ("threadId", Json::string(thread_id)),
    ("runId", Json::string(run_id)),
    ("protocolVersion", Json::string(protocol_version)),
    ("messages", Json::array([ for message in messages => message.to_json() ])),
    ("tools", Json::array(tools)),
    ("context", Json::array(context)),
  ])
  match parent_run_id {
    Some(value) => fields["parentRunId"] = Json::string(value)
    None => ()
  }
  match state {
    Some(value) => fields["state"] = value
    None => ()
  }
  match forwarded_props {
    Some(value) => fields["forwardedProps"] = value
    None => ()
  }
  match resume_entries {
    Some(value) => fields["resume"] = Json::array(value)
    None => ()
  }
  { value: Json::object(fields), }
}

///|
/// Decode an AG-UI run request and validate its required envelope fields.
pub fn RunAgentInput::from_json(value : Json) -> RunAgentInput raise {
  match value {
    {
      "threadId": String(_),
      "runId": String(_),
      "messages": Array(messages),
      ..
    } => {
      for message in messages {
        ignore(Message::from_json(message))
      }
      match value {
        { "tools": Array(tools), .. } =>
          for tool in tools {
            validate_tool(tool)
          }
        _ => ()
      }
      match value {
        { "context": Array(context), .. } =>
          for item in context {
            validate_context(item)
          }
        _ => ()
      }
      match value {
        { "resume": Array(entries), .. } =>
          for entry in entries {
            validate_resume(entry)
          }
        _ => ()
      }
      { value, }
    }
    _ => fail("RunAgentInput requires string threadId/runId and messages array")
  }
}

///|
/// Decode an AG-UI run request from JSON text.
pub fn RunAgentInput::from_json_string(value : String) -> RunAgentInput raise {
  RunAgentInput::from_json(@json.parse(value))
}

///|
/// Return the request thread identifier.
pub fn RunAgentInput::thread_id(self : RunAgentInput) -> String {
  match self.value {
    { "threadId": String(value), .. } => value
    _ => ""
  }
}

///|
/// Return the request run identifier.
pub fn RunAgentInput::run_id(self : RunAgentInput) -> String {
  match self.value {
    { "runId": String(value), .. } => value
    _ => ""
  }
}

///|
/// Return the message values without narrowing their multimodal contents.
pub fn RunAgentInput::messages(self : RunAgentInput) -> Array[Json] {
  match self.value {
    { "messages": Array(values), .. } => values
    _ => []
  }
}

///|
/// Return the complete input object, including fields unknown to this SDK.
pub fn RunAgentInput::to_json(self : RunAgentInput) -> Json {
  self.value
}

///|
/// Encode the input as compact JSON.
pub fn RunAgentInput::to_json_string(self : RunAgentInput) -> String {
  self.value.stringify()
}
