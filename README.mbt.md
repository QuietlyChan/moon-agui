# agui

`agui` is an AG-UI 1.0 protocol SDK for MoonBit agents. It provides typed
event construction, JSON encoding/decoding, Server-Sent Events framing,
protocol validation, and a native HTTP endpoint for streaming agent runs.

The package follows the official [AG-UI schema](https://docs.ag-ui.com/) and
keeps unknown fields and event names so applications can tolerate protocol
extensions.

## Packages

- `QuietlyChan/agui/core` — AG-UI events, inputs, messages, tools, state,
  capabilities, and lifecycle validation.
- `QuietlyChan/agui/sse` — SSE framing and parsing helpers.
- `QuietlyChan/agui/server` — native `POST /agent` SSE server contract.
- `QuietlyChan/agui/emitter` — buffered event emitter with middleware.

## Quick start

```moonbit
impl @server.AgUiAgent for MyAgent with fn run(self, input, emit) {
  emit(@core.AgUiEvent::run_started(
    thread_id=input.thread_id(),
    run_id=input.run_id(),
  ))
  emit(@core.AgUiEvent::text_message_start(message_id="answer"))
  emit(@core.AgUiEvent::text_message_content(
    message_id="answer",
    delta="Hello from MoonBit",
  ))
  emit(@core.AgUiEvent::text_message_end(message_id="answer"))
  emit(@core.AgUiEvent::run_finished(
    thread_id=input.thread_id(),
    run_id=input.run_id(),
  ))
}
```

See [`examples`](examples/README.md) for an offline event stream and a
complete browser/server example. The browser frontend can also be published
to GitHub Pages and runs a deterministic local AG-UI stream without a backend.

The project is licensed under Apache-2.0. The Chinese project README is the
default human-facing guide; [`README.en.md`](README.en.md) is its English
translation.
