# AG-UI Web Agent

[简体中文](README.md) | English

This is a complete AG-UI frontend/backend example. The native MoonBit backend emits AG-UI SSE events, while the browser renders messages, lifecycle state, and raw events as they arrive. The frontend includes a deterministic offline stream, so the same directory can be published to GitHub Pages and viewed without an API key or backend.

## Run locally

Start the MoonBit backend from the repository root:

```shell
moon run examples/web_agent/backend
```

Serve `examples/web_agent/frontend` with any static server, for example:

```shell
python -m http.server 4173 --directory examples/web_agent/frontend
```

Open <http://127.0.0.1:4173/>. Switch the mode to **Backend** and set the endpoint to `http://127.0.0.1:8087/agent`. The backend supports CORS preflight and returns standard `data: {json}\n\n` SSE frames.

## GitHub Pages

`.github/workflows/pages.yml` publishes `examples/web_agent/frontend` whenever `main` changes. Set the repository's Pages source to **GitHub Actions** once in Settings -> Pages. The project site is normally:

<https://quietlychan.github.io/moon-agui/>

Pages starts in **Offline demo** mode and shows `RUN_STARTED`, `STEP_STARTED`, text deltas, `STEP_FINISHED`, and `RUN_FINISHED`. To connect a real MoonBit backend, deploy it to an HTTPS endpoint with CORS enabled, then select **Backend** and enter its `/agent` URL.

## API

| Endpoint | Purpose |
| --- | --- |
| `GET /api/health` | Reports protocol version and SSE transport |
| `POST /agent` | Accepts AG-UI `RunAgentInput` and streams events |

Example request:

```shell
curl -N http://127.0.0.1:8087/agent \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{"threadId":"thread-1","runId":"run-1","messages":[{"id":"m1","role":"user","content":"Hello"}],"tools":[],"context":[]}'
```
