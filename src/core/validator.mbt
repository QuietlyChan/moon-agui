///|
/// Validate behavioural lifecycle rules that are not expressible in JSON schema.
/// A stream may contain several runs for one thread.
pub fn validate_event_sequence(events : Array[AgUiEvent]) -> Unit raise {
  guard events.length() > 0 else { fail("AG-UI event sequence is empty") }

  let open_messages : Map[String, Unit] = Map([])
  let open_tools : Map[String, Unit] = Map([])
  let open_steps : Map[String, Map[String, Unit]] = Map([])
  let open_reasoning_spans : Map[String, Unit] = Map([])
  let open_reasoning_messages : Map[String, Unit] = Map([])
  let open_subagents : Map[String, Unit] = Map([])
  let closed_subagents : Map[String, Unit] = Map([])
  let mut run_active = false
  let mut saw_terminal = false
  let mut run_count = 0

  fn clear_run_state() -> Unit {
    open_messages.clear()
    open_tools.clear()
    open_steps.clear()
    open_reasoning_spans.clear()
    open_reasoning_messages.clear()
    open_subagents.clear()
    closed_subagents.clear()
  }

  fn owner_key(event : AgUiEvent) -> String {
    match event.string_field("subagentRunId") {
      Some(id) => "subagent:" + id
      None => "parent"
    }
  }

  fn steps_for(owner : String) -> Map[String, Unit] {
    match open_steps.get(owner) {
      Some(steps) => steps
      None => {
        let steps : Map[String, Unit] = Map([])
        open_steps[owner] = steps
        steps
      }
    }
  }

  fn require_id(
    event : AgUiEvent,
    field : String,
    label : String,
  ) -> String raise {
    let id = event.string_field(field).unwrap_or("")
    guard id != "" else { fail(label + " requires " + field) }
    id
  }

  for index, event in events {
    let kind = event.event_type()
    if kind is EventType::RunStarted {
      guard !run_active else {
        fail("RUN_STARTED appeared while a run was active")
      }
      clear_run_state()
      run_active = true
      saw_terminal = false
      run_count += 1
      continue
    }
    if !run_active {
      if kind is EventType::RunError && index == 0 {
        saw_terminal = true
        continue
      }
      fail("every event must belong to a run beginning with RUN_STARTED")
    }
    if saw_terminal {
      fail(
        "event appeared after the run terminal event; start a new run with RUN_STARTED",
      )
    }

    match kind {
      EventType::TextMessageStart => {
        let id = require_id(event, "messageId", "TEXT_MESSAGE_START")
        guard !open_messages.contains(id) else {
          fail("TEXT_MESSAGE_START repeated for an open message")
        }
        open_messages[id] = ()
      }
      EventType::TextMessageContent => {
        let id = require_id(event, "messageId", "TEXT_MESSAGE_CONTENT")
        guard open_messages.contains(id) else {
          fail("TEXT_MESSAGE_CONTENT has no matching TEXT_MESSAGE_START")
        }
      }
      EventType::TextMessageEnd => {
        let id = require_id(event, "messageId", "TEXT_MESSAGE_END")
        guard open_messages.contains(id) else {
          fail("TEXT_MESSAGE_END has no matching TEXT_MESSAGE_START")
        }
        open_messages.remove(id)
      }
      EventType::ToolCallStart => {
        let id = require_id(event, "toolCallId", "TOOL_CALL_START")
        guard !open_tools.contains(id) else {
          fail("TOOL_CALL_START repeated for an open tool call")
        }
        open_tools[id] = ()
      }
      EventType::ToolCallArgs => {
        let id = require_id(event, "toolCallId", "TOOL_CALL_ARGS")
        guard open_tools.contains(id) else {
          fail("TOOL_CALL_ARGS has no matching TOOL_CALL_START")
        }
      }
      EventType::ToolCallEnd => {
        let id = require_id(event, "toolCallId", "TOOL_CALL_END")
        guard open_tools.contains(id) else {
          fail("TOOL_CALL_END has no matching TOOL_CALL_START")
        }
        open_tools.remove(id)
      }
      EventType::ReasoningStart => {
        let id = require_id(event, "messageId", "REASONING_START")
        guard !open_reasoning_spans.contains(id) else {
          fail("REASONING_START repeated for an open reasoning span")
        }
        open_reasoning_spans[id] = ()
      }
      EventType::ReasoningMessageStart => {
        let id = require_id(event, "messageId", "REASONING_MESSAGE_START")
        guard !open_reasoning_messages.contains(id) else {
          fail("REASONING_MESSAGE_START repeated for an open reasoning message")
        }
        open_reasoning_messages[id] = ()
      }
      EventType::ReasoningMessageContent => {
        let id = require_id(event, "messageId", "REASONING_MESSAGE_CONTENT")
        guard open_reasoning_messages.contains(id) else {
          fail(
            "REASONING_MESSAGE_CONTENT has no matching REASONING_MESSAGE_START",
          )
        }
      }
      EventType::ReasoningMessageEnd => {
        let id = require_id(event, "messageId", "REASONING_MESSAGE_END")
        guard open_reasoning_messages.contains(id) else {
          fail("REASONING_MESSAGE_END has no matching REASONING_MESSAGE_START")
        }
        open_reasoning_messages.remove(id)
      }
      EventType::ReasoningEnd => {
        let id = require_id(event, "messageId", "REASONING_END")
        guard open_reasoning_spans.contains(id) else {
          fail("REASONING_END has no matching REASONING_START")
        }
        open_reasoning_spans.remove(id)
      }
      EventType::StepStarted => {
        let name = require_id(event, "stepName", "STEP_STARTED")
        let steps = steps_for(owner_key(event))
        guard !steps.contains(name) else {
          fail("STEP_STARTED repeated for an open step")
        }
        steps[name] = ()
      }
      EventType::StepFinished => {
        let name = require_id(event, "stepName", "STEP_FINISHED")
        let owner = owner_key(event)
        let steps = steps_for(owner)
        guard steps.contains(name) else {
          fail("STEP_FINISHED has no matching STEP_STARTED")
        }
        steps.remove(name)
      }
      EventType::SubagentStarted => {
        let id = require_id(event, "subagentRunId", "SUBAGENT_STARTED")
        guard event.string_field("name") is Some(_) else {
          fail("SUBAGENT_STARTED requires name")
        }
        match event.string_field("parentSubagentRunId") {
          Some(parent) =>
            if !open_subagents.contains(parent) &&
              !closed_subagents.contains(parent) {
              fail("SUBAGENT_STARTED parentSubagentRunId has not been started")
            }
          None => ()
        }
        guard !open_subagents.contains(id) else {
          fail("SUBAGENT_STARTED repeated for an active subagent")
        }
        guard !closed_subagents.contains(id) else {
          fail("SUBAGENT_STARTED cannot reuse a finished subagent id")
        }
        open_subagents[id] = ()
      }
      EventType::SubagentFinished | EventType::SubagentError => {
        let id = require_id(event, "subagentRunId", kind.wire_name())
        guard open_subagents.contains(id) else {
          fail(kind.wire_name() + " has no matching SUBAGENT_STARTED")
        }
        open_subagents.remove(id)
        closed_subagents[id] = ()
      }
      EventType::RunFinished | EventType::RunError => {
        guard open_messages.is_empty() else {
          fail("run ended with an open text message")
        }
        guard open_tools.is_empty() else {
          fail("run ended with an open tool call")
        }
        for _, steps in open_steps {
          guard steps.is_empty() else { fail("run ended with an open step") }
        }
        guard open_reasoning_spans.is_empty() else {
          fail("run ended with an open reasoning span")
        }
        guard open_reasoning_messages.is_empty() else {
          fail("run ended with an open reasoning message")
        }
        guard open_subagents.is_empty() else {
          fail("run ended with an active subagent")
        }
        saw_terminal = true
        run_active = false
      }
      _ => ()
    }
  }

  guard run_count > 0 else {
    fail("AG-UI event sequence has no RUN_STARTED event")
  }
  guard saw_terminal else {
    fail("AG-UI event sequence has no run terminal event")
  }
}
