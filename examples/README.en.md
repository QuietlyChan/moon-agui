# AG-UI MoonBit Examples

[简体中文](README.md) | English

This workspace shows how to emit AG-UI 1.0 events from MoonBit agents. The examples are offline by default, so they need no model API key and can run in CI.

## Examples

| Directory | Demonstrates |
| --- | --- |
| `basic_events` | Builds a complete lifecycle, validates it, and demonstrates JSON decoding plus SSE framing |
| `echo_server` | Serves a native HTTP `POST /agent` AG-UI SSE endpoint |

## Run

From the repository root:

```shell
moon run examples/basic_events
moon run examples/echo_server
```

With the server running, send an AG-UI request from another terminal:

```shell
curl -N http://127.0.0.1:8087/agent \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{"threadId":"thread-1","runId":"run-1","messages":[{"id":"message-1","role":"user","content":"Hello"}],"tools":[],"context":[]}'
```

The response uses `data: {json}\n\n` SSE frames and includes `RUN_STARTED`, text-message events, and `RUN_FINISHED`. `basic_events` validates the same flow without a server and prints each serialized frame.

## Validate

```shell
cd examples
moon update
moon fmt --check
moon check
moon run basic_events
```

The examples workspace imports the published `QuietlyChan/agui@0.1.0` package, matching the dependency declaration used by Mooncakes consumers.
