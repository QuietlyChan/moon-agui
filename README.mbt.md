# agui

`QuietlyChan/agui` is an AG-UI 1.0 protocol SDK for MoonBit agents. It
provides typed event construction, JSON encoding/decoding, Server-Sent Events
framing, lifecycle validation, and a native HTTP endpoint for streaming agent
runs.

The SDK follows the official [AG-UI schema](https://docs.ag-ui.com/) and keeps
unknown event names and fields so applications can tolerate protocol
extensions.

## Packages

- `QuietlyChan/agui/core` — 31 AG-UI event types, run input, messages, tools,
  multimodal content, JSON Patch, capabilities, and lifecycle validation.
- `QuietlyChan/agui/sse` — event framing, keepalive pings, and SSE parsing.
- `QuietlyChan/agui/server` — native `POST /agent` SSE server contract with
  CORS/OPTIONS support.
- `QuietlyChan/agui/emitter` — buffered events and ordered middleware.

## Quick start

```moonbit
struct EchoAgent {}

impl @server.AgUiAgent for EchoAgent with fn run(self, input, emit) {
  ignore(self)
  let message_id = input.run_id() + "-assistant"
  emit(@core.AgUiEvent::run_started(
    thread_id=input.thread_id(),
    run_id=input.run_id(),
  ))
  emit(@core.AgUiEvent::text_message_start(message_id~))
  emit(@core.AgUiEvent::text_message_content(
    message_id~,
    delta="Hello from MoonBit",
  ))
  emit(@core.AgUiEvent::text_message_end(message_id~))
  emit(@core.AgUiEvent::run_finished(
    thread_id=input.thread_id(),
    run_id=input.run_id(),
  ))
}

async fn main {
  @server.serve(EchoAgent::{ } as &@server.AgUiAgent)
}
```

Install the published package with:

```shell
moon add QuietlyChan/agui
```

The repository examples are in [`examples`](examples/README.md). Run
`moon run examples/basic_events` for an offline stream, or
`moon run examples/web_agent/backend` for the browser/SSE example. The browser
frontend also runs without a backend at
<https://quietlychan.github.io/moon-agui/>.

The current release covers JSON and SSE transports and targets MoonBit native.
It does not include a protobuf/binary encoder or a frontend framework SDK.
The project is licensed under Apache-2.0; see [`LICENSE`](LICENSE).
