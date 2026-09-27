# moon-agui

[简体中文](README.md) | [English](README.en.md)

[![CI](https://github.com/QuietlyChan/moon-agui/actions/workflows/ci.yml/badge.svg)](https://github.com/QuietlyChan/moon-agui/actions/workflows/ci.yml)
[![Pages](https://github.com/QuietlyChan/moon-agui/actions/workflows/pages.yml/badge.svg)](https://github.com/QuietlyChan/moon-agui/actions/workflows/pages.yml)
[![MoonBit](https://img.shields.io/badge/MoonBit-native-F5A623.svg)](https://www.moonbitlang.com/)
[![AG-UI](https://img.shields.io/badge/AG--UI-1.0-2563eb.svg)](https://docs.ag-ui.com/)
[![Mooncakes](https://img.shields.io/badge/Mooncakes-agui-f59e0b.svg)](https://mooncakes.io/)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

面向 MoonBit 智能体的 AG-UI 1.0 协议 SDK。它把 agent 运行过程编码为统一的类型化事件，通过 JSON 和 Server-Sent Events（SSE）发送给聊天界面、审批流、共享状态和其他 AG-UI 消费者。

项目当前版本为 `0.1.0`，已发布到 Mooncakes：`QuietlyChan/agui`。协议实现参考 [AG-UI 官方仓库](https://github.com/ag-ui-protocol/ag-ui/)、1.0 schema/fixtures 以及官方 SDK 的可观察行为。

## 当前实现

- **完整事件模型**：官方 31 个 AG-UI 1.0 事件，包括文本、工具调用、状态、消息快照、activity、RAW、CUSTOM、run/step、reasoning 和 subagent 事件。
- **类型化协议对象**：`RunAgentInput`、消息、工具、上下文、多模态内容、JSON Patch、interrupt/resume、token usage、agent capabilities。
- **前向兼容解码**：未知事件名和未知字段会保留，方便接收未来协议扩展；已知事件会校验必填字段和联合结构。
- **生命周期校验**：检查 run、message、tool call、reasoning、step 和 subagent 的开始/增量/结束顺序。
- **SSE transport**：`data: {json}\n\n` 帧、keepalive ping、CRLF、多行 `data:`、注释帧和流解析。
- **原生 HTTP 服务**：`AgUiAgent` trait 和 `serve` 函数暴露 `POST /agent`，自动 flush SSE，并支持 CORS/OPTIONS 预检。
- **事件 emitter**：带 middleware 的内存 `BufferedEmitter`，用于录制、重放、测试和把现有 agent 日志投影为 AG-UI 事件。

当前版本专注于 JSON wire format 和 SSE transport，不包含 protobuf/binary encoder，也不提供 React/TypeScript UI 状态管理。

## 包结构

| 包 | 用途 |
| --- | --- |
| `QuietlyChan/agui/core` | 事件、输入、消息、工具、状态模型、capabilities 和生命周期校验 |
| `QuietlyChan/agui/sse` | AG-UI 事件的 SSE 编码/解码和 keepalive ping |
| `QuietlyChan/agui/server` | MoonBit native `POST /agent` SSE 服务端抽象 |
| `QuietlyChan/agui/emitter` | 可插入 middleware 的内存事件 emitter |

## 安装

使用 Mooncakes 安装：

```shell
moon add QuietlyChan/agui
```

在 `moon.pkg` 中按需导入：

```moonbit
import {
  "QuietlyChan/agui/core",
  "QuietlyChan/agui/sse",
  "QuietlyChan/agui/server",
}
```

SDK 当前支持 MoonBit native target，HTTP 运行时使用 `moonbitlang/async`。

## 最小 Agent

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

服务端接收 AG-UI `RunAgentInput`，响应头为 `text/event-stream`，每个事件都会立即 flush：

```shell
curl -N http://127.0.0.1:8087/agent \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{"threadId":"thread-1","runId":"run-1","messages":[{"id":"m1","role":"user","content":"Hello"}],"tools":[],"context":[]}'
```

## 类型化输入和多模态内容

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

所有协议对象都可以通过 `to_json()` 写入官方 wire object；`from_json` 和 `AgUiEvent::new` 可用于保留尚未由 SDK 建模的扩展字段。

## 示例和在线演示

[`examples`](examples/README.md) 是独立的 MoonBit workspace，包含无需 API key 的示例：

```shell
# 完整事件生命周期、JSON 解码和 SSE framing
moon run examples/basic_events

# 最小 HTTP / SSE echo agent
moon run examples/echo_server

# 浏览器前端 + MoonBit SSE 后端
moon run examples/web_agent/backend
```

`examples/web_agent` 包含：

- `frontend/`：原生 HTML/CSS/JavaScript 前端，解析 AG-UI SSE，展示文本消息和原始事件时间线。
- `backend/`：MoonBit native HTTP 服务，提供 `GET /api/health` 和 `POST /agent`，支持 CORS。
- 离线模式：不需要后端和 API key，可以在 GitHub Pages 上直接运行确定性事件流。
- 后端模式：填写 `/agent` 地址，观察真实 MoonBit SSE 事件。

在线查看：<https://quietlychan.github.io/moon-agui/>

GitHub Pages workflow 会发布 `examples/web_agent/frontend`；后端需要自行部署到支持 HTTPS 和 CORS 的服务。

## 兼容性边界

- 协议版本常量为 `@core.PROTOCOL_VERSION == "1.0"`。
- 事件 discriminator 使用官方大写名称，例如 `RUN_STARTED`、`TEXT_MESSAGE_CONTENT` 和 `RUN_FINISHED`。
- JSON 字段使用官方 camelCase，例如 `threadId`、`runId`、`messageId`。
- SDK 只负责协议对象、编码/解码和服务端流输出；模型调用、鉴权、前端框架和 agent 编排由应用自行选择。
- 当前 transport 是 JSON/SSE；protobuf 或其他 binary transport 可以在不改变 core 模型的前提下单独扩展。

协议详情见 [AG-UI 文档](https://docs.ag-ui.com/) 和 [官方仓库](https://github.com/ag-ui-protocol/ag-ui/)。

## 开发与验证

仓库通过 `moon.work` 同时管理 SDK 和 examples：

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

GitHub Actions 在 `main` 推送和 Pull Request 上执行 SDK/examples 的格式检查、包检查、构建和测试；Pages workflow 负责发布在线前端。项目使用 Apache-2.0 许可证，详见 [`LICENSE`](LICENSE)。
