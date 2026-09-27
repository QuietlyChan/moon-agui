///|
/// Typed capability objects from the AG-UI 1.0 schema.
/// Identity and descriptive metadata for an agent.
pub struct IdentityCapabilities {
  value : Json
}

///|
/// Transport features supported by an agent endpoint.
pub struct TransportCapabilities {
  value : Json
}

///|
/// Tool discovery and invocation features.
pub struct ToolsCapabilities {
  value : Json
}

///|
/// Output formats accepted or produced by an agent.
pub struct OutputCapabilities {
  value : Json
}

///|
/// State snapshot, delta, and persistence support.
pub struct StateCapabilities {
  value : Json
}

///|
/// Delegation and subagent support.
pub struct MultiAgentCapabilities {
  value : Json
}

///|
/// Reasoning stream and encryption support.
pub struct ReasoningCapabilities {
  value : Json
}

///|
/// Input media accepted by the agent.
pub struct MultimodalInputCapabilities {
  value : Json
}

///|
/// Media that can be returned by the agent.
pub struct MultimodalOutputCapabilities {
  value : Json
}

///|
/// Combined multimodal input and output capabilities.
pub struct MultimodalCapabilities {
  value : Json
}

///|
/// Code execution and resource limit support.
pub struct ExecutionCapabilities {
  value : Json
}

///|
/// Approval, intervention, and feedback support.
pub struct HumanInTheLoopCapabilities {
  value : Json
}

///|
fn capability(value : Json) -> Json {
  value
}

///|
/// Build identity capabilities as a typed value.
pub fn IdentityCapabilities::new(
  name? : String,
  kind? : String,
  description? : String,
  version? : String,
  provider? : String,
  documentation_url? : String,
  metadata? : Json,
) -> IdentityCapabilities {
  {
    value: identity_capabilities(
      name?,
      kind?,
      description?,
      version?,
      provider?,
      documentation_url?,
      metadata?,
    ),
  }
}

///|
/// Build transport capabilities as a typed value.
pub fn TransportCapabilities::new(
  streaming? : Bool,
  websocket? : Bool,
  http_binary? : Bool,
  push_notifications? : Bool,
  resumable? : Bool,
) -> TransportCapabilities {
  {
    value: transport_capabilities(
      streaming?,
      websocket?,
      http_binary?,
      push_notifications?,
      resumable?,
    ),
  }
}

///|
/// Build tool capabilities as a typed value.
pub fn ToolsCapabilities::new(
  supported? : Bool,
  items? : Array[Tool],
  parallel_calls? : Bool,
  client_provided? : Bool,
) -> ToolsCapabilities {
  {
    value: tools_capabilities(
      supported?,
      items?,
      parallel_calls?,
      client_provided?,
    ),
  }
}

///|
/// Build output capabilities as a typed value.
pub fn OutputCapabilities::new(
  structured_output? : Bool,
  supported_mime_types? : Array[String],
) -> OutputCapabilities {
  { value: output_capabilities(structured_output?, supported_mime_types?), }
}

///|
/// Build state capabilities as a typed value.
pub fn StateCapabilities::new(
  snapshots? : Bool,
  deltas? : Bool,
  memory? : Bool,
  persistent_state? : Bool,
) -> StateCapabilities {
  {
    value: state_capabilities(snapshots?, deltas?, memory?, persistent_state?),
  }
}

///|
/// Build multi-agent capabilities as a typed value.
pub fn MultiAgentCapabilities::new(
  supported? : Bool,
  delegation? : Bool,
  handoffs? : Bool,
  subagents? : Array[SubagentInfo],
) -> MultiAgentCapabilities {
  {
    value: multi_agent_capabilities(
      supported?,
      delegation?,
      handoffs?,
      subagents?,
    ),
  }
}

///|
/// Build reasoning capabilities as a typed value.
pub fn ReasoningCapabilities::new(
  supported? : Bool,
  streaming? : Bool,
  encrypted? : Bool,
) -> ReasoningCapabilities {
  { value: reasoning_capabilities(supported?, streaming?, encrypted?), }
}

///|
/// Build multimodal input capabilities as a typed value.
pub fn MultimodalInputCapabilities::new(
  image? : Bool,
  audio? : Bool,
  video? : Bool,
  pdf? : Bool,
  file? : Bool,
) -> MultimodalInputCapabilities {
  { value: multimodal_input_capabilities(image?, audio?, video?, pdf?, file?), }
}

///|
/// Build multimodal output capabilities as a typed value.
pub fn MultimodalOutputCapabilities::new(
  image? : Bool,
  audio? : Bool,
) -> MultimodalOutputCapabilities {
  { value: multimodal_output_capabilities(image?, audio?), }
}

///|
/// Build multimodal capabilities as a typed value.
pub fn MultimodalCapabilities::new(
  input~ : MultimodalInputCapabilities,
  output~ : MultimodalOutputCapabilities,
) -> MultimodalCapabilities {
  { value: multimodal_capabilities(input=input.value, output=output.value), }
}

///|
/// Build execution capabilities as a typed value.
pub fn ExecutionCapabilities::new(
  code_execution? : Bool,
  sandboxed? : Bool,
  max_iterations? : Int,
  max_execution_time? : Int,
) -> ExecutionCapabilities {
  {
    value: execution_capabilities(
      code_execution?,
      sandboxed?,
      max_iterations?,
      max_execution_time?,
    ),
  }
}

///|
/// Build human-in-the-loop capabilities as a typed value.
pub fn HumanInTheLoopCapabilities::new(
  supported? : Bool,
  approvals? : Bool,
  interventions? : Bool,
  feedback? : Bool,
  interrupts? : Bool,
  approve_with_edits? : Bool,
) -> HumanInTheLoopCapabilities {
  {
    value: human_in_the_loop_capabilities(
      supported?,
      approvals?,
      interventions?,
      feedback?,
      interrupts?,
      approve_with_edits?,
    ),
  }
}

///|
/// Encode identity capabilities.
pub fn IdentityCapabilities::to_json(self : IdentityCapabilities) -> Json {
  capability(self.value)
}

///|
/// Encode transport capabilities.
pub fn TransportCapabilities::to_json(self : TransportCapabilities) -> Json {
  capability(self.value)
}

///|
/// Encode tool capabilities.
pub fn ToolsCapabilities::to_json(self : ToolsCapabilities) -> Json {
  capability(self.value)
}

///|
/// Encode output capabilities.
pub fn OutputCapabilities::to_json(self : OutputCapabilities) -> Json {
  capability(self.value)
}

///|
/// Encode state capabilities.
pub fn StateCapabilities::to_json(self : StateCapabilities) -> Json {
  capability(self.value)
}

///|
/// Encode multi-agent capabilities.
pub fn MultiAgentCapabilities::to_json(self : MultiAgentCapabilities) -> Json {
  capability(self.value)
}

///|
/// Encode reasoning capabilities.
pub fn ReasoningCapabilities::to_json(self : ReasoningCapabilities) -> Json {
  capability(self.value)
}

///|
/// Encode multimodal input capabilities.
pub fn MultimodalInputCapabilities::to_json(
  self : MultimodalInputCapabilities,
) -> Json {
  capability(self.value)
}

///|
/// Encode multimodal output capabilities.
pub fn MultimodalOutputCapabilities::to_json(
  self : MultimodalOutputCapabilities,
) -> Json {
  capability(self.value)
}

///|
/// Encode combined multimodal capabilities.
pub fn MultimodalCapabilities::to_json(self : MultimodalCapabilities) -> Json {
  capability(self.value)
}

///|
/// Encode execution capabilities.
pub fn ExecutionCapabilities::to_json(self : ExecutionCapabilities) -> Json {
  capability(self.value)
}

///|
/// Encode human-in-the-loop capabilities.
pub fn HumanInTheLoopCapabilities::to_json(
  self : HumanInTheLoopCapabilities,
) -> Json {
  capability(self.value)
}

///|
/// Combine typed capability sections into an AgentCapabilities value.
pub fn AgentCapabilities::with_sections(
  identity? : IdentityCapabilities,
  transport? : TransportCapabilities,
  tools? : ToolsCapabilities,
  output? : OutputCapabilities,
  state? : StateCapabilities,
  multi_agent? : MultiAgentCapabilities,
  reasoning? : ReasoningCapabilities,
  multimodal? : MultimodalCapabilities,
  execution? : ExecutionCapabilities,
  human_in_the_loop? : HumanInTheLoopCapabilities,
  custom? : Json,
) -> AgentCapabilities {
  let fields : Map[String, Json] = Map([])
  match identity {
    Some(value) => fields["identity"] = value.to_json()
    None => ()
  }
  match transport {
    Some(value) => fields["transport"] = value.to_json()
    None => ()
  }
  match tools {
    Some(value) => fields["tools"] = value.to_json()
    None => ()
  }
  match output {
    Some(value) => fields["output"] = value.to_json()
    None => ()
  }
  match state {
    Some(value) => fields["state"] = value.to_json()
    None => ()
  }
  match multi_agent {
    Some(value) => fields["multiAgent"] = value.to_json()
    None => ()
  }
  match reasoning {
    Some(value) => fields["reasoning"] = value.to_json()
    None => ()
  }
  match multimodal {
    Some(value) => fields["multimodal"] = value.to_json()
    None => ()
  }
  match execution {
    Some(value) => fields["execution"] = value.to_json()
    None => ()
  }
  match human_in_the_loop {
    Some(value) => fields["humanInTheLoop"] = value.to_json()
    None => ()
  }
  put_optional_json(fields, "custom", custom)
  AgentCapabilities::new(fields)
}
