# moon-agui

[简体中文](README.md) | [English](README.en.md)

[![CI](https://github.com/QuietlyChan/moon-agui/actions/workflows/ci.yml/badge.svg)](https://github.com/QuietlyChan/moon-agui/actions/workflows/ci.yml)
[![MoonBit](https://img.shields.io/badge/MoonBit-native-F5A623.svg)](https://www.moonbitlang.com/)
[![AG-UI](https://img.shields.io/badge/AG--UI-1.0-2563eb.svg)](https://docs.ag-ui.com/)
[![Mooncakes](https://img.shields.io/badge/Mooncakes-agui-f59e0b.svg)](https://mooncakes.io/)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

MoonBit 的 AG-UI 1.0 SDK，面向需要把智能体运行过程统一输出给聊天界面、审批流和共享状态消费者的 MoonBit 开发者。协议参考官方仓库的 `spec/1.0/schema.json`、fixtures 以及 TypeScript/Python SDK。

本项目提供 server-side wire contract：事件类型化构造、JSON 编解码、SSE 编解码、HTTP endpoint 和流生命周期校验。它不复制 React/TypeScript 客户端的 UI 状态管理。事件 JSON 使用 AG-UI 规定的大写 `type` discriminator 和 camelCase 字段，SSE 使用 `data: {json}\n\n` 帧。

## 当前能力

- `QuietlyChan/agui/core`：官方 31 个 AG-UI 1.0 事件名，包括文本、工具调用、状态、消息快照、activity、RAW、CUSTOM、run/step、reasoning 和 subagent。
- `@core.PROTOCOL_VERSION`：当前模型对应的 AG-UI 协议版本常量（`"1.0"`）。
- 共享模型：多模态 `ContentPart`（data/url/file source）、消息角色、工具和上下文、JSON Patch RFC 6902、interrupt/resume、token usage、agent capabilities。
- 类型化便利构造器：`Message::user_parts`、`Message::assistant`、`AgUiEvent::run_finished_full`、`run_finished_outcome_interrupt` 等；未知字段和未知事件名会原样保留。
- 协议校验：`Message::from_json`、`RunAgentInput::from_json` 校验必填字段和联合类型；`validate_event_sequence` 校验 run、消息、工具、reasoning、step、subagent 的流式生命周期。
- `QuietlyChan/agui/sse`：事件和 keepalive ping 的 SSE 序列化，以及 `parse_frame`/`parse_stream` 解码器，支持 CRLF、多行 `data:` 和注释帧。
- `QuietlyChan/agui/server`：MoonBit native HTTP `POST /agent` SSE endpoint 抽象，包含正确的流式响应 headers 和 flush。
- `QuietlyChan/agui/emitter`：带 middleware 的内存 emitter，适合录制、重放和把现有 agent 日志投影为 AG-UI 事件。
- `src/cmd/demo`：离线 echo agent，可用 `curl` 观察完整的 AG-UI 事件流。

协议的 protobuf/binary encoder 不在当前版本中；当前版本完整覆盖 JSON wire format 和 SSE transport。这样不会把 MoonBit SDK 绑定到某个 HTTP 或 protobuf 实现，后续可单独增加 binary transport。

## 运行 demo

需要 MoonBit nightly/native 工具链：

```shell
moon test
moon run src/cmd/demo
```

另一个终端发送 AG-UI 运行请求：

```shell
curl -N http://127.0.0.1:8087/agent \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{"threadId":"thread-1","runId":"run-1","messages":[{"id":"m1","role":"user","content":"Hello"}],"tools":[],"context":[]}'
```

响应依次包含 `RUN_STARTED`、`TEXT_MESSAGE_START`、`TEXT_MESSAGE_CONTENT`、`TEXT_MESSAGE_END` 和 `RUN_FINISHED`。

## 示例 workspace

[`examples`](examples/README.md) 按 MoonBit 官方实践组织为独立 workspace，包含无需 API Key 的离线事件示例和可直接连接的 HTTP/SSE echo agent：

```shell
moon run examples/basic_events
moon run examples/echo_server
```

进入服务示例后，可使用 `curl` 或兼容 AG-UI 的前端发送 `POST /agent` 请求。示例 workspace 同时提供 [英文说明](examples/README.en.md)，并在 CI 中执行格式检查、包检查和离线运行验证。

## 最小 agent

实现 `AgUiAgent`，在 `run` 中按需调用 `emit`：

```moonbit
impl @server.AgUiAgent for MyAgent with fn run(self, input, emit) {
  emit(@core.AgUiEvent::run_started(
    thread_id=input.thread_id(),
    run_id=input.run_id(),
  ))
  // emit text/tool/state events here
}
```

## 类型化输入和多模态消息

```moonbit
let image = @core.ContentPart::image(
  source=@core.PartSource::url(value="https://example.test/image.png", mime_type="image/png"),
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

`Message`、`ContentPart`、`ToolCall`、`Interrupt`、`ResumeEntry` 和 capability 对象都可以通过 `to_json()` 进入官方协议对象；需要继续兼容未来字段时可直接使用 `from_json`/`AgUiEvent::new`。

## 设计边界

SDK 的目标是为 MoonBit agent 提供稳定的 server-side wire contract，而不是复制现有 TypeScript UI SDK。HTTP server、鉴权、模型调用和前端渲染均保持可替换；`RunAgentInput` 和事件对象保留原始 JSON，使 MoonBit agent 可以逐步跟进官方 schema。

## 官方兼容性

协议跟踪：AG-UI 1.0 schema，参考仓库 <https://github.com/ag-ui-protocol/ag-ui/>，文档 <https://docs.ag-ui.com/>。官方 schema 的未知字段规则允许接收端容忍未来扩展，因此 SDK 解码时保留原始 JSON；对已知 discriminator 的必填字段和联合类型执行校验。

许可证：Apache-2.0。

## 开发与验证

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

GitHub Actions 会在 `main` 推送和 Pull Request 上执行同样的检查。项目标签和包元数据包括 `ag-ui`、`agent`、`protocol`、`sse` 与 `moonbit`，方便在 GitHub 和 Mooncakes 中检索。
