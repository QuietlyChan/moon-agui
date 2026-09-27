# moon-agui

[简体中文](README.md) | [English](README.en.md)

[![CI](https://github.com/QuietlyChan/moon-agui/actions/workflows/ci.yml/badge.svg)](https://github.com/QuietlyChan/moon-agui/actions/workflows/ci.yml)
[![Pages](https://github.com/QuietlyChan/moon-agui/actions/workflows/pages.yml/badge.svg)](https://github.com/QuietlyChan/moon-agui/actions/workflows/pages.yml)
[![MoonBit](https://img.shields.io/badge/MoonBit-native-F5A623.svg)](https://www.moonbitlang.com/)
[![AG-UI](https://img.shields.io/badge/AG--UI-1.0-2563eb.svg)](https://docs.ag-ui.com/)
[![Mooncakes](https://img.shields.io/badge/Mooncakes-agui-f59e0b.svg)](https://mooncakes.io/)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

An AG-UI 1.0 protocol SDK for MoonBit agents. It turns agent execution into typed events and sends them over JSON and Server-Sent Events (SSE) to chat interfaces, approval flows, shared state consumers, and other AG-UI clients.

The current release is `0.1.0` and is published on Mooncakes as `QuietlyChan/agui`. The implementation follows the [official AG-UI repository](https://github.com/ag-ui-protocol/ag-ui/), the 1.0 schema/fixtures, and observable behavior from the official SDKs.

## What is implemented

- **Complete event model**: all 31 AG-UI 1.0 event names for text, tools, state, message snapshots, activity, RAW, CUSTOM, run/step, reasoning, and subagents.
- **Typed protocol objects**: `RunAgentInput`, messages, tools, context, multimodal content, JSON Patch, interrupt/resume, token usage, and agent capabilities.
- **Forward-compatible decoding**: unknown event names and fields are preserved; known events receive required-field and union-shape validation.
- **Lifecycle validation**: run, message, tool call, reasoning, step, and subagent start/delta/end ordering is checked.
- **SSE transport**: `data: {json}\n\n` frames, keepalive pings, CRLF, multiline data, comment frames, and stream parsing.
- **Native HTTP server**: `AgUiAgent` and `serve` expose `POST /agent`, flush SSE events, and support CORS/OPTIONS preflight.
- **Event emitter**: an in-memory `BufferedEmitter` with middleware for recording, replay, testing, and log projection.

The current release focuses on the JSON wire format and SSE transport. It does not include a protobuf/binary encoder or React/TypeScript UI state management.

## Packages

| Package | Purpose |
| --- | --- |
| `QuietlyChan/agui/core` | Events, inputs, messages, tools, state models, capabilities, and lifecycle validation |
| `QuietlyChan/agui/sse` | SSE encoding/decoding and keepalive pings |
| `QuietlyChan/agui/server` | Native MoonBit `POST /agent` SSE server abstraction |
| `QuietlyChan/agui/emitter` | Middleware-capable in-memory event emitter |

## Install

Install from Mooncakes:

```shell
moon add QuietlyChan/agui
```

Import the packages you need:

```moonbit
import {
  "QuietlyChan/agui/core",
  "QuietlyChan/agui/sse",
  "QuietlyChan/agui/server",
}
```

The SDK currently targets MoonBit native and uses `moonbitlang/async` for its HTTP runtime.

## Minimal agent

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

The server accepts an AG-UI `RunAgentInput` and responds with `text/event-stream`, flushing each event immediately:

```shell
curl -N http://127.0.0.1:8087/agent \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{"threadId":"thread-1","runId":"run-1","messages":[{"id":"m1","role":"user","content":"Hello"}],"tools":[],"context":[]}'
```

## Typed input and multimodal content

```moonbit
let image = @core.ContentPart::image(
  source=@core.PartSource::url(
    value="https://example.test/image.png",
    mime_type="image/png",
  ),
)
let input = @core.RunAgentInput::new_typed(
  thread_id="thread-1",
  run_id="run-1",
  messages=[
    @core.Message::user_parts(
      id="message-1",
      content=[@core.ContentPart::text(text="Describe this"), image],
    ),
  ],
  tools=[@core.Tool::new(
    name="search",
    description="Search the knowledge base",
    parameters={"type":"object"},
  )],
)
```

Protocol objects can be written to official wire objects with `to_json()`. Use `from_json` and `AgUiEvent::new` when preserving extension fields that are not yet modeled by the SDK.

## Examples and live demo

[`examples`](examples/README.en.md) is a standalone MoonBit workspace with API-key-free examples:

```shell
# Complete lifecycle, JSON decoding, and SSE framing
moon run examples/basic_events

# Minimal HTTP / SSE echo agent
moon run examples/echo_server

# Browser frontend + MoonBit SSE backend
moon run examples/web_agent/backend
```

`examples/web_agent` contains:

- `frontend/`: a plain HTML/CSS/JavaScript UI that parses AG-UI SSE and shows the text response plus raw event timeline.
- `backend/`: a native MoonBit HTTP server with `GET /api/health` and `POST /agent`, including CORS support.
- Offline mode: no backend or API key is required, so the deterministic event stream runs on GitHub Pages.
- Backend mode: enter an `/agent` URL to inspect real MoonBit SSE events.

Live demo: <https://quietlychan.github.io/moon-agui/>

The GitHub Pages workflow publishes `examples/web_agent/frontend`. A real backend must be deployed separately with HTTPS and CORS enabled.

## Compatibility boundary

- The protocol constant is `@core.PROTOCOL_VERSION == "1.0"`.
- Event discriminators use official uppercase names such as `RUN_STARTED`, `TEXT_MESSAGE_CONTENT`, and `RUN_FINISHED`.
- JSON fields use official camelCase names such as `threadId`, `runId`, and `messageId`.
- The SDK owns protocol objects, encoding/decoding, and server-side streaming. Applications choose their own model runtime, authentication, frontend framework, and agent orchestration.
- The current transport is JSON/SSE. Protobuf or another binary transport can be added without changing the core models.

See the [AG-UI documentation](https://docs.ag-ui.com/) and [official repository](https://github.com/ag-ui-protocol/ag-ui/) for protocol details.

## Development and validation

The repository uses `moon.work` to manage the SDK and examples together:

```shell
moon update
moon fmt --check
moon check
moon build
moon test

moon run examples/basic_events
moon build examples/web_agent/backend
node --check examples/web_agent/frontend/app.js
```

GitHub Actions runs formatting, package checks, builds, and tests for the SDK and examples on pushes to `main` and pull requests. The Pages workflow publishes the browser frontend. Licensed under the [Apache License 2.0](LICENSE).
