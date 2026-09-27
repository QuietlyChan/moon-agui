///|
/// Check a complete run for a valid lifecycle and paired message/tool/step events.
pub fn validate_event_sequence(events : Array[AgUiEvent]) -> Unit raise {
  guard events.length() > 0 else { fail("AG-UI event sequence is empty") }
  guard events[0].event_type() is EventType::RunStarted else {
    fail("AG-UI event sequence must start with RUN_STARTED")
  }

  let open_messages : Map[String, Unit] = Map([])
  let open_tools : Map[String, Unit] = Map([])
  let open_steps : Map[String, Unit] = Map([])
  let mut ended = false

  for index, event in events {
    if ended {
      fail("AG-UI event appeared after the run terminal event")
    }
    match event.event_type() {
      EventType::RunStarted =>
        if index != 0 {
          fail("AG-UI run may only contain one RUN_STARTED event")
        }
      EventType::TextMessageStart => {
        let id = event.string_field("messageId").unwrap_or("")
        guard id != "" else { fail("TEXT_MESSAGE_START requires messageId") }
        guard !open_messages.contains(id) else {
          fail("TEXT_MESSAGE_START repeated for an open message")
        }
        open_messages[id] = ()
      }
      EventType::TextMessageContent => {
        let id = event.string_field("messageId").unwrap_or("")
        guard open_messages.contains(id) else {
          fail("TEXT_MESSAGE_CONTENT has no matching TEXT_MESSAGE_START")
        }
      }
      EventType::TextMessageEnd => {
        let id = event.string_field("messageId").unwrap_or("")
        guard open_messages.contains(id) else {
          fail("TEXT_MESSAGE_END has no matching TEXT_MESSAGE_START")
        }
        open_messages.remove(id)
      }
      EventType::ToolCallStart => {
        let id = event.string_field("toolCallId").unwrap_or("")
        guard id != "" else { fail("TOOL_CALL_START requires toolCallId") }
        guard !open_tools.contains(id) else {
          fail("TOOL_CALL_START repeated for an open tool call")
        }
        open_tools[id] = ()
      }
      EventType::ToolCallArgs => {
        let id = event.string_field("toolCallId").unwrap_or("")
        guard open_tools.contains(id) else {
          fail("TOOL_CALL_ARGS has no matching TOOL_CALL_START")
        }
      }
      EventType::ToolCallEnd => {
        let id = event.string_field("toolCallId").unwrap_or("")
        guard open_tools.contains(id) else {
          fail("TOOL_CALL_END has no matching TOOL_CALL_START")
        }
        open_tools.remove(id)
      }
      EventType::StepStarted => {
        let name = event.string_field("stepName").unwrap_or("")
        guard name != "" else { fail("STEP_STARTED requires stepName") }
        guard !open_steps.contains(name) else {
          fail("STEP_STARTED repeated for an open step")
        }
        open_steps[name] = ()
      }
      EventType::StepFinished => {
        let name = event.string_field("stepName").unwrap_or("")
        guard open_steps.contains(name) else {
          fail("STEP_FINISHED has no matching STEP_STARTED")
        }
        open_steps.remove(name)
      }
      EventType::RunFinished | EventType::RunError => {
        guard open_messages.is_empty() else {
          fail("run ended with an open text message")
        }
        guard open_tools.is_empty() else {
          fail("run ended with an open tool call")
        }
        guard open_steps.is_empty() else { fail("run ended with an open step") }
        guard index == events.length() - 1 else {
          fail("run terminal event must be last")
        }
        ended = true
      }
      _ => ()
    }
  }
  guard ended else { fail("AG-UI event sequence has no run terminal event") }
}
