///|
/// AG-UI 1.0 shared JSON model helpers.
///
/// The protocol deliberately carries application-owned JSON in a number of
/// places. These small wrappers provide typed constructors without losing
/// fields added by an integration or a newer protocol revision.
fn json_number(value : Int) -> Json {
  Json::number(value.to_double())
}

///|
fn put_optional_string(
  fields : Map[String, Json],
  key : String,
  value : String?,
) -> Unit {
  match value {
    Some(value) => fields[key] = Json::string(value)
    None => ()
  }
}

///|
fn put_optional_json(
  fields : Map[String, Json],
  key : String,
  value : Json?,
) -> Unit {
  match value {
    Some(value) => fields[key] = value
    None => ()
  }
}

///|
fn put_optional_bool(
  fields : Map[String, Json],
  key : String,
  value : Bool?,
) -> Unit {
  match value {
    Some(value) => fields[key] = Json::boolean(value)
    None => ()
  }
}

///|
fn put_optional_int(
  fields : Map[String, Json],
  key : String,
  value : Int?,
) -> Unit {
  match value {
    Some(value) => fields[key] = json_number(value)
    None => ()
  }
}

///|
fn put_optional_strings(
  fields : Map[String, Json],
  key : String,
  values : Array[String]?,
) -> Unit {
  match values {
    Some(values) =>
      fields[key] = Json::array([ for value in values => Json::string(value) ])
    None => ()
  }
}

///|
fn json_object(fields : Map[String, Json]) -> Json {
  Json::object(fields)
}

///|
fn validate_source(value : Json) -> Unit raise {
  match value {
    { "type": String(kind), "value": String(_), .. } =>
      match kind {
        "data" =>
          ignore(required_model_string(value, "mimeType", "data source"))
        "url" => validate_optional_model_string(value, "mimeType", "url source")
        "file" => {
          validate_optional_model_string(value, "provider", "file source")
          validate_optional_model_string(value, "mimeType", "file source")
        }
        _ => fail("unknown AG-UI content source type: " + kind)
      }
    _ => fail("content source requires string type and value")
  }
}

///|
fn validate_content_part(value : Json) -> Unit raise {
  match value {
    { "type": String(kind), .. } =>
      match kind {
        "text" => {
          ignore(required_model_string(value, "text", "text part"))
          validate_optional_model_string(value, "id", "text part")
          validate_optional_model_object(value, "metadata", "text part")
        }
        "image" | "audio" | "video" | "document" => {
          validate_source(required_model_field(value, "source", kind + " part"))
          validate_optional_model_string(value, "id", kind + " part")
          validate_optional_model_object(value, "metadata", kind + " part")
        }
        _ => fail("unknown AG-UI content part type: " + kind)
      }
    _ => fail("content part requires a string type")
  }
}

///|
fn validate_content_parts(value : Json, label : String) -> Unit raise {
  match value {
    Array(parts) =>
      for part in parts {
        validate_content_part(part)
      }
    _ => fail(label + " content must be a string or content-part array")
  }
}

///|
fn required_model_field(
  value : Json,
  name : String,
  label : String,
) -> Json raise {
  match value {
    Object(fields) =>
      match fields.get(name) {
        Some(value) => value
        None => fail(label + " requires " + name)
      }
    _ => fail(label + " must be an object")
  }
}

///|
fn required_model_string(
  value : Json,
  name : String,
  label : String,
) -> String raise {
  match required_model_field(value, name, label) {
    String(value) => value
    _ => fail(label + " requires string " + name)
  }
}

///|
/// Validate an RFC 6901 JSON Pointer.
fn validate_json_pointer(value : String, label : String) -> Unit raise {
  if value == "" {
    return
  }
  guard value.has_prefix("/") else {
    fail(label + " path must be empty or start with /")
  }
  let mut escaped = false
  for ch in value {
    if escaped {
      guard ch == '0' || ch == '1' else {
        fail(label + " path contains an invalid ~ escape")
      }
      escaped = false
    } else if ch == '~' {
      escaped = true
    }
  }
  guard !escaped else { fail(label + " path ends with an incomplete ~ escape") }
}

///|
fn validate_json_patch(value : Json, label : String) -> Unit raise {
  match value {
    Array(operations) =>
      for operation in operations {
        let op = required_model_string(operation, "op", label + " operation")
        let path = required_model_string(
          operation,
          "path",
          label + " operation",
        )
        validate_json_pointer(path, label + " operation")
        match op {
          "add" | "replace" | "test" =>
            ignore(required_model_field(operation, "value", label + " " + op))
          "move" | "copy" => {
            let from = required_model_string(
              operation,
              "from",
              label + " " + op,
            )
            validate_json_pointer(from, label + " " + op)
          }
          "remove" => ()
          _ => fail(label + " contains unknown JSON Patch operation: " + op)
        }
      }
    _ => fail(label + " must be an array")
  }
}

///|
/// A JSON Patch operation as defined by RFC 6902.
pub struct JsonPatchOperation {
  value : Json
}

///|
/// Build an `add` operation.
pub fn JsonPatchOperation::add(
  path~ : String,
  value~ : Json,
) -> JsonPatchOperation {
  {
    value: json_object(
      Map([
        ("op", Json::string("add")),
        ("path", Json::string(path)),
        ("value", value),
      ]),
    ),
  }
}

///|
/// Build a `remove` operation.
pub fn JsonPatchOperation::remove(path~ : String) -> JsonPatchOperation {
  {
    value: json_object(
      Map([("op", Json::string("remove")), ("path", Json::string(path))]),
    ),
  }
}

///|
/// Build a `replace` operation.
pub fn JsonPatchOperation::replace(
  path~ : String,
  value~ : Json,
) -> JsonPatchOperation {
  {
    value: json_object(
      Map([
        ("op", Json::string("replace")),
        ("path", Json::string(path)),
        ("value", value),
      ]),
    ),
  }
}

///|
/// Build a `move` operation.
pub fn JsonPatchOperation::move_op(
  from~ : String,
  path~ : String,
) -> JsonPatchOperation {
  {
    value: json_object(
      Map([
        ("op", Json::string("move")),
        ("from", Json::string(from)),
        ("path", Json::string(path)),
      ]),
    ),
  }
}

///|
/// Build a `copy` operation.
pub fn JsonPatchOperation::copy(
  from~ : String,
  path~ : String,
) -> JsonPatchOperation {
  {
    value: json_object(
      Map([
        ("op", Json::string("copy")),
        ("from", Json::string(from)),
        ("path", Json::string(path)),
      ]),
    ),
  }
}

///|
/// Build a `test` operation.
pub fn JsonPatchOperation::test_op(
  path~ : String,
  value~ : Json,
) -> JsonPatchOperation {
  {
    value: json_object(
      Map([
        ("op", Json::string("test")),
        ("path", Json::string(path)),
        ("value", value),
      ]),
    ),
  }
}

///|
/// Return an operation as JSON.
pub fn JsonPatchOperation::to_json(self : JsonPatchOperation) -> Json {
  self.value
}

///|
/// Decode an operation while retaining extension members required by RFC 6902.
pub fn JsonPatchOperation::from_json(value : Json) -> JsonPatchOperation {
  { value, }
}

///|
/// Return a JSON Patch document from typed operations.
pub fn json_patch(operations : Array[JsonPatchOperation]) -> Json {
  Json::array([ for operation in operations => operation.to_json() ])
}

///|
/// A content source for image, audio, video, and document parts.
pub struct PartSource {
  value : Json
}

///|
/// An inline base64/data source.
pub fn PartSource::data(value~ : String, mime_type~ : String) -> PartSource {
  {
    value: json_object(
      Map([
        ("type", Json::string("data")),
        ("value", Json::string(value)),
        ("mimeType", Json::string(mime_type)),
      ]),
    ),
  }
}

///|
/// A URL source.
pub fn PartSource::url(value~ : String, mime_type? : String) -> PartSource {
  let fields : Map[String, Json] = Map([
    ("type", Json::string("url")),
    ("value", Json::string(value)),
  ])
  put_optional_string(fields, "mimeType", mime_type)
  { value: json_object(fields), }
}

///|
/// A provider file reference.
pub fn PartSource::file(
  value~ : String,
  provider? : String,
  mime_type? : String,
) -> PartSource {
  let fields : Map[String, Json] = Map([
    ("type", Json::string("file")),
    ("value", Json::string(value)),
  ])
  put_optional_string(fields, "provider", provider)
  put_optional_string(fields, "mimeType", mime_type)
  { value: json_object(fields), }
}

///|
/// Return a source as JSON.
pub fn PartSource::to_json(self : PartSource) -> Json {
  self.value
}

///|
/// Decode a source without narrowing provider-specific extensions.
pub fn PartSource::from_json(value : Json) -> PartSource {
  { value, }
}

///|
/// A text or media message content part.
pub struct ContentPart {
  value : Json
}

///|
fn content_part(kind : String, fields : Map[String, Json]) -> ContentPart {
  fields["type"] = Json::string(kind)
  { value: json_object(fields), }
}

///|
/// Build a text content part.
pub fn ContentPart::text(
  text~ : String,
  id? : String,
  metadata? : Json,
) -> ContentPart {
  let fields : Map[String, Json] = Map([("text", Json::string(text))])
  put_optional_string(fields, "id", id)
  put_optional_json(fields, "metadata", metadata)
  content_part("text", fields)
}

///|
/// Build an image content part.
pub fn ContentPart::image(
  source~ : PartSource,
  id? : String,
  metadata? : Json,
) -> ContentPart {
  let fields : Map[String, Json] = Map([("source", source.to_json())])
  put_optional_string(fields, "id", id)
  put_optional_json(fields, "metadata", metadata)
  content_part("image", fields)
}

///|
/// Build an audio content part.
pub fn ContentPart::audio(
  source~ : PartSource,
  id? : String,
  metadata? : Json,
) -> ContentPart {
  let fields : Map[String, Json] = Map([("source", source.to_json())])
  put_optional_string(fields, "id", id)
  put_optional_json(fields, "metadata", metadata)
  content_part("audio", fields)
}

///|
/// Build a video content part.
pub fn ContentPart::video(
  source~ : PartSource,
  id? : String,
  metadata? : Json,
) -> ContentPart {
  let fields : Map[String, Json] = Map([("source", source.to_json())])
  put_optional_string(fields, "id", id)
  put_optional_json(fields, "metadata", metadata)
  content_part("video", fields)
}

///|
/// Build a document content part.
pub fn ContentPart::document(
  source~ : PartSource,
  id? : String,
  metadata? : Json,
) -> ContentPart {
  let fields : Map[String, Json] = Map([("source", source.to_json())])
  put_optional_string(fields, "id", id)
  put_optional_json(fields, "metadata", metadata)
  content_part("document", fields)
}

///|
/// Return a content part as JSON.
pub fn ContentPart::to_json(self : ContentPart) -> Json {
  self.value
}

///|
/// Decode a content part while preserving fields unknown to this SDK.
pub fn ContentPart::from_json(value : Json) -> ContentPart {
  { value, }
}

///|
/// A JSON function call embedded in an assistant message.
pub struct FunctionCall {
  value : Json
}

///|
/// Build a function call.
pub fn FunctionCall::new(name~ : String, arguments~ : String) -> FunctionCall {
  {
    value: json_object(
      Map([("name", Json::string(name)), ("arguments", Json::string(arguments))]),
    ),
  }
}

///|
/// Return a function call as JSON.
pub fn FunctionCall::to_json(self : FunctionCall) -> Json {
  self.value
}

///|
/// A tool call in an assistant message.
pub struct ToolCall {
  value : Json
}

///|
/// Build a function tool call.
pub fn ToolCall::function(
  id~ : String,
  name~ : String,
  arguments~ : String,
  encrypted_value? : String,
  metadata? : Json,
) -> ToolCall {
  let fields : Map[String, Json] = Map([
    ("id", Json::string(id)),
    ("type", Json::string("function")),
    ("function", FunctionCall::new(name~, arguments~).to_json()),
  ])
  put_optional_string(fields, "encryptedValue", encrypted_value)
  put_optional_json(fields, "metadata", metadata)
  { value: json_object(fields), }
}

///|
/// Return a tool call as JSON.
pub fn ToolCall::to_json(self : ToolCall) -> Json {
  self.value
}

///|
/// A user-visible context item passed to an agent.
pub struct Context {
  value : Json
}

///|
/// Build a context item.
pub fn Context::new(description~ : String, value~ : String) -> Context {
  {
    value: json_object(
      Map([
        ("description", Json::string(description)),
        ("value", Json::string(value)),
      ]),
    ),
  }
}

///|
/// Return context as JSON.
pub fn Context::to_json(self : Context) -> Json {
  self.value
}

///|
/// A tool definition supplied in RunAgentInput.
pub struct Tool {
  value : Json
}

///|
/// Build a tool definition. Parameters are intentionally arbitrary JSON in AG-UI 1.0.
pub fn Tool::new(
  name~ : String,
  description~ : String,
  parameters? : Json,
  metadata? : Json,
) -> Tool {
  let fields : Map[String, Json] = Map([
    ("name", Json::string(name)),
    ("description", Json::string(description)),
  ])
  put_optional_json(fields, "parameters", parameters)
  put_optional_json(fields, "metadata", metadata)
  { value: json_object(fields), }
}

///|
/// Return a tool definition as JSON.
pub fn Tool::to_json(self : Tool) -> Json {
  self.value
}

///|
/// An interrupt reported by a suspended run.
pub struct Interrupt {
  value : Json
}

///|
/// Build an interrupt. `response_schema` is an object-valued JSON schema.
pub fn Interrupt::new(
  id~ : String,
  reason~ : String,
  message? : String,
  tool_call_id? : String,
  response_schema? : Json,
  expires_at? : String,
  metadata? : Json,
  subagent_run_id? : String,
) -> Interrupt {
  let fields : Map[String, Json] = Map([
    ("id", Json::string(id)),
    ("reason", Json::string(reason)),
  ])
  put_optional_string(fields, "message", message)
  put_optional_string(fields, "toolCallId", tool_call_id)
  put_optional_json(fields, "responseSchema", response_schema)
  put_optional_string(fields, "expiresAt", expires_at)
  put_optional_json(fields, "metadata", metadata)
  put_optional_string(fields, "subagentRunId", subagent_run_id)
  { value: json_object(fields), }
}

///|
/// Return an interrupt as JSON.
pub fn Interrupt::to_json(self : Interrupt) -> Json {
  self.value
}

///|
/// A response to an interrupt supplied in the next RunAgentInput.
pub struct ResumeEntry {
  value : Json
}

///|
/// Build a resolved or cancelled resume entry.
pub fn ResumeEntry::new(
  interrupt_id~ : String,
  status~ : String,
  payload? : Json,
  metadata? : Json,
) -> ResumeEntry {
  let fields : Map[String, Json] = Map([
    ("interruptId", Json::string(interrupt_id)),
    ("status", Json::string(status)),
  ])
  put_optional_json(fields, "payload", payload)
  put_optional_json(fields, "metadata", metadata)
  { value: json_object(fields), }
}

///|
/// Return a resume entry as JSON.
pub fn ResumeEntry::to_json(self : ResumeEntry) -> Json {
  self.value
}

///|
/// Token accounting for one provider/model pair.
pub struct TokenUsage {
  value : Json
}

///|
/// Build token usage. Counts are optional because providers may report only a subset.
pub fn TokenUsage::new(
  provider? : String,
  model? : String,
  input_tokens? : Int,
  output_tokens? : Int,
  total_tokens? : Int,
  reasoning_tokens? : Int,
  cached_input_tokens? : Int,
  cache_write_input_tokens? : Int,
) -> TokenUsage {
  let fields : Map[String, Json] = Map([])
  put_optional_string(fields, "provider", provider)
  put_optional_string(fields, "model", model)
  put_optional_int(fields, "inputTokens", input_tokens)
  put_optional_int(fields, "outputTokens", output_tokens)
  put_optional_int(fields, "totalTokens", total_tokens)
  put_optional_int(fields, "reasoningTokens", reasoning_tokens)
  put_optional_int(fields, "cachedInputTokens", cached_input_tokens)
  put_optional_int(fields, "cacheWriteInputTokens", cache_write_input_tokens)
  { value: json_object(fields), }
}

///|
/// Return token usage as JSON.
pub fn TokenUsage::to_json(self : TokenUsage) -> Json {
  self.value
}

///|
/// A named subagent advertised by capabilities.
pub struct SubagentInfo {
  value : Json
}

///|
/// Build a subagent capability entry.
pub fn SubagentInfo::new(name~ : String, description? : String) -> SubagentInfo {
  let fields : Map[String, Json] = Map([("name", Json::string(name))])
  put_optional_string(fields, "description", description)
  { value: json_object(fields), }
}

///|
/// Return subagent info as JSON.
pub fn SubagentInfo::to_json(self : SubagentInfo) -> Json {
  self.value
}

///|
/// A generic capabilities object. Its fields are the official camelCase keys.
pub struct AgentCapabilities {
  value : Json
}

///|
/// Build capabilities from arbitrary JSON. Use the specialized capability
/// constructors below for common fields and `custom` for vendor extensions.
pub fn AgentCapabilities::new(fields : Map[String, Json]) -> AgentCapabilities {
  { value: json_object(fields), }
}

///|
/// Return capabilities as JSON.
pub fn AgentCapabilities::to_json(self : AgentCapabilities) -> Json {
  self.value
}

///|
/// Build identity capabilities.
pub fn identity_capabilities(
  name? : String,
  kind? : String,
  description? : String,
  version? : String,
  provider? : String,
  documentation_url? : String,
  metadata? : Json,
) -> Json {
  let fields : Map[String, Json] = Map([])
  put_optional_string(fields, "name", name)
  put_optional_string(fields, "type", kind)
  put_optional_string(fields, "description", description)
  put_optional_string(fields, "version", version)
  put_optional_string(fields, "provider", provider)
  put_optional_string(fields, "documentationUrl", documentation_url)
  put_optional_json(fields, "metadata", metadata)
  json_object(fields)
}

///|
/// Build transport capabilities.
pub fn transport_capabilities(
  streaming? : Bool,
  websocket? : Bool,
  http_binary? : Bool,
  push_notifications? : Bool,
  resumable? : Bool,
) -> Json {
  let fields : Map[String, Json] = Map([])
  put_optional_bool(fields, "streaming", streaming)
  put_optional_bool(fields, "websocket", websocket)
  put_optional_bool(fields, "httpBinary", http_binary)
  put_optional_bool(fields, "pushNotifications", push_notifications)
  put_optional_bool(fields, "resumable", resumable)
  json_object(fields)
}

///|
/// Build tool capabilities.
pub fn tools_capabilities(
  supported? : Bool,
  items? : Array[Tool],
  parallel_calls? : Bool,
  client_provided? : Bool,
) -> Json {
  let fields : Map[String, Json] = Map([])
  put_optional_bool(fields, "supported", supported)
  match items {
    Some(items) =>
      fields["items"] = Json::array([ for item in items => item.to_json() ])
    None => ()
  }
  put_optional_bool(fields, "parallelCalls", parallel_calls)
  put_optional_bool(fields, "clientProvided", client_provided)
  json_object(fields)
}

///|
/// Build output capabilities.
pub fn output_capabilities(
  structured_output? : Bool,
  supported_mime_types? : Array[String],
) -> Json {
  let fields : Map[String, Json] = Map([])
  put_optional_bool(fields, "structuredOutput", structured_output)
  put_optional_strings(fields, "supportedMimeTypes", supported_mime_types)
  json_object(fields)
}

///|
/// Build state capabilities.
pub fn state_capabilities(
  snapshots? : Bool,
  deltas? : Bool,
  memory? : Bool,
  persistent_state? : Bool,
) -> Json {
  let fields : Map[String, Json] = Map([])
  put_optional_bool(fields, "snapshots", snapshots)
  put_optional_bool(fields, "deltas", deltas)
  put_optional_bool(fields, "memory", memory)
  put_optional_bool(fields, "persistentState", persistent_state)
  json_object(fields)
}

///|
/// Build multi-agent capabilities.
pub fn multi_agent_capabilities(
  supported? : Bool,
  delegation? : Bool,
  handoffs? : Bool,
  subagents? : Array[SubagentInfo],
) -> Json {
  let fields : Map[String, Json] = Map([])
  put_optional_bool(fields, "supported", supported)
  put_optional_bool(fields, "delegation", delegation)
  put_optional_bool(fields, "handoffs", handoffs)
  match subagents {
    Some(values) =>
      fields["subagents"] = Json::array(
        [
          for value in values => value.to_json()
        ],
      )
    None => ()
  }
  json_object(fields)
}

///|
/// Build reasoning capabilities.
pub fn reasoning_capabilities(
  supported? : Bool,
  streaming? : Bool,
  encrypted? : Bool,
) -> Json {
  let fields : Map[String, Json] = Map([])
  put_optional_bool(fields, "supported", supported)
  put_optional_bool(fields, "streaming", streaming)
  put_optional_bool(fields, "encrypted", encrypted)
  json_object(fields)
}

///|
/// Build multimodal input capabilities.
pub fn multimodal_input_capabilities(
  image? : Bool,
  audio? : Bool,
  video? : Bool,
  pdf? : Bool,
  file? : Bool,
) -> Json {
  let fields : Map[String, Json] = Map([])
  put_optional_bool(fields, "image", image)
  put_optional_bool(fields, "audio", audio)
  put_optional_bool(fields, "video", video)
  put_optional_bool(fields, "pdf", pdf)
  put_optional_bool(fields, "file", file)
  json_object(fields)
}

///|
/// Build multimodal output capabilities.
pub fn multimodal_output_capabilities(image? : Bool, audio? : Bool) -> Json {
  let fields : Map[String, Json] = Map([])
  put_optional_bool(fields, "image", image)
  put_optional_bool(fields, "audio", audio)
  json_object(fields)
}

///|
/// Build multimodal capabilities from input and output capability objects.
pub fn multimodal_capabilities(input~ : Json, output~ : Json) -> Json {
  json_object(Map([("input", input), ("output", output)]))
}

///|
/// Build execution capabilities.
pub fn execution_capabilities(
  code_execution? : Bool,
  sandboxed? : Bool,
  max_iterations? : Int,
  max_execution_time? : Int,
) -> Json {
  let fields : Map[String, Json] = Map([])
  put_optional_bool(fields, "codeExecution", code_execution)
  put_optional_bool(fields, "sandboxed", sandboxed)
  put_optional_int(fields, "maxIterations", max_iterations)
  put_optional_int(fields, "maxExecutionTime", max_execution_time)
  json_object(fields)
}

///|
/// Build human-in-the-loop capabilities.
pub fn human_in_the_loop_capabilities(
  supported? : Bool,
  approvals? : Bool,
  interventions? : Bool,
  feedback? : Bool,
  interrupts? : Bool,
  approve_with_edits? : Bool,
) -> Json {
  let fields : Map[String, Json] = Map([])
  put_optional_bool(fields, "supported", supported)
  put_optional_bool(fields, "approvals", approvals)
  put_optional_bool(fields, "interventions", interventions)
  put_optional_bool(fields, "feedback", feedback)
  put_optional_bool(fields, "interrupts", interrupts)
  put_optional_bool(fields, "approveWithEdits", approve_with_edits)
  json_object(fields)
}
