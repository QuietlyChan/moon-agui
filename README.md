# moon-agui

MoonBit 的 AG-UI 服务端 SDK，面向需要把智能体运行过程统一输出给聊天界面、审批流和共享状态消费者的 MoonBit 开发者。

本项目只负责协议核心和 agent 端输出，不实现 React/TypeScript 客户端。事件 JSON 与 AG-UI 1.0 schema 对齐：顶层使用大写 `type` discriminator，字段使用 camelCase，SSE 使用 `data: {json}\n\n` 帧。

## 当前能力

- `QuietlyChan/agui/core`：31 个 AG-UI 1.0 事件名、`AgUiEvent` 构造/解析、`RunAgentInput`、消息角色、JSON 扩展字段透传。
- `QuietlyChan/agui/core`：运行生命周期、文本消息、工具调用和步骤事件的配对校验器。
- `QuietlyChan/agui/sse`：事件和 keepalive ping 的 SSE 序列化。
- `QuietlyChan/agui/server`：MoonBit native HTTP `POST /agent` SSE endpoint 抽象。
- `src/cmd/demo`：离线 echo agent，可用 `curl` 观察完整的 AG-UI 事件流。

未知的事件名和未知字段会被保留，便于 AG-UI schema 演进；已知事件的便利 `*_CHUNK` 事件不自动展开，agent 可以直接使用 `AgUiEvent::new` 或 `CUSTOM` 扩展。

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

## 设计边界

SDK 的目标是为 MoonBit agent 提供稳定的 server-side wire contract，而不是复制现有 TypeScript UI SDK。HTTP server、鉴权、模型调用和前端渲染均保持可替换；`RunAgentInput` 和事件对象保留原始 JSON，使 MoonBit agent 可以逐步跟进官方 schema。

协议跟踪：AG-UI 1.0 schema，参考仓库 <https://github.com/ag-ui-protocol/ag-ui/>，文档 <https://docs.ag-ui.com/>。

许可证：Apache-2.0。
