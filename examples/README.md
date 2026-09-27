# AG-UI MoonBit 示例

[English](README.en.md) | 简体中文

这个 workspace 展示如何使用 `QuietlyChan/agui` 在 MoonBit 智能体中输出标准的 AG-UI 1.0 事件。示例默认不需要模型 API Key，适合本地学习和 CI 冒烟测试。

## 示例目录

| 目录 | 内容 |
| --- | --- |
| `basic_events` | 构造完整生命周期事件，校验事件顺序，并演示 JSON 解码与 SSE framing |
| `echo_server` | 使用 `AgUiAgent` 启动原生 HTTP `POST /agent` SSE 服务 |

## 运行

在仓库根目录执行：

```shell
moon run examples/basic_events
moon run examples/echo_server
```

启动服务后，另一个终端发送 AG-UI 请求：

```shell
curl -N http://127.0.0.1:8087/agent \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{"threadId":"thread-1","runId":"run-1","messages":[{"id":"message-1","role":"user","content":"你好"}],"tools":[],"context":[]}'
```

响应是 `data: {json}\n\n` 格式的 SSE 帧，包含 `RUN_STARTED`、文本消息事件和 `RUN_FINISHED`。`basic_events` 则完全离线地验证同一条事件流，并逐帧展示序列化结果。

## 验证

```shell
cd examples
moon update
moon fmt --check
moon check
moon run basic_events
```

示例 workspace 依赖已发布的 `QuietlyChan/agui@0.1.0`，用于验证 Mooncakes 用户的真实导入方式。
