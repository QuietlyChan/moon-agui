# moon-agui

[简体中文](README.md) | English

[![CI](https://github.com/QuietlyChan/moon-agui/actions/workflows/ci.yml/badge.svg)](https://github.com/QuietlyChan/moon-agui/actions/workflows/ci.yml)
[![MoonBit](https://img.shields.io/badge/MoonBit-native-F5A623.svg)](https://www.moonbitlang.com/)
[![AG-UI](https://img.shields.io/badge/AG--UI-1.0-2563eb.svg)](https://docs.ag-ui.com/)
[![Mooncakes](https://img.shields.io/badge/Mooncakes-agui-f59e0b.svg)](https://mooncakes.io/)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

MoonBit's AG-UI 1.0 SDK for agents that need a stable streaming contract for chat UIs, approval flows, and shared state consumers. The implementation follows the official AG-UI schema, fixtures, and SDK behavior.

This project provides a server-side wire contract: typed event construction, JSON encoding/decoding, SSE framing/parsing, a native HTTP endpoint, and stream lifecycle validation. It does not duplicate React or TypeScript UI state management.

## Features

- All 31 AG-UI 1.0 event names, including text, tool, state, activity, reasoning, raw, custom, and subagent events.
- Typed messages, multimodal content parts, tools, context, JSON Patch, interrupt/resume, token usage, and capabilities.
- Forward-compatible decoding that preserves unknown fields and event names.
- Protocol validation for input envelopes and run/message/tool/reasoning lifecycles.
- JSON and SSE transport helpers, including CRLF, multiline data, comments, and keepalive pings.
- Native HTTP `POST /agent` SSE server and a middleware-capable buffered emitter.

The current release intentionally focuses on JSON and SSE. A protobuf or binary encoder can be added as a separate transport without coupling the core package to an HTTP implementation.

## Install

```shell
moon add QuietlyChan/agui
```

```moonbit
import {
  "QuietlyChan/agui/core",
  "QuietlyChan/agui/sse",
  "QuietlyChan/agui/server",
}
```

## Minimal agent

```moonbit
impl @server.AgUiAgent for MyAgent with fn run(self, input, emit) {
  emit(@core.AgUiEvent::run_started(
    thread_id=input.thread_id(),
    run_id=input.run_id(),
  ))
  // Emit text, tool, state, or custom events here.
}
```

## Examples

The [`examples`](examples/README.en.md) workspace follows MoonBit's standalone-example pattern:

```shell
moon run examples/basic_events
moon run examples/echo_server
```

`basic_events` validates a complete offline stream and round-trips it through SSE. `echo_server` serves a native `POST /agent` endpoint that can be called with `curl` or an AG-UI-compatible frontend.

## Development

```shell
moon update
moon fmt --check
moon check
moon test

cd examples
moon update
moon fmt --check
moon check
moon run basic_events
```

GitHub Actions runs these checks for pushes to `main` and pull requests. Package metadata includes the `ag-ui`, `agent`, `protocol`, `sse`, and `moonbit` keywords for discovery on GitHub and Mooncakes.

## Compatibility and license

Protocol tracking follows the [AG-UI repository](https://github.com/ag-ui-protocol/ag-ui/) and [documentation](https://docs.ag-ui.com/). Unknown fields are retained so clients can tolerate future schema additions while known discriminators receive structural validation.

Licensed under the [Apache License 2.0](LICENSE).
