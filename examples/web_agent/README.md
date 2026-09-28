# AG-UI Web Agent

[English](README.en.md) | 简体中文

这是一个可运行的 AG-UI MVP：MoonBit native 后端执行确定性的 `lookup` 工具调用，输出工具参数、工具结果、共享状态快照和最终文本的 AG-UI SSE 事件；浏览器前端解析事件并实时渲染消息、生命周期和原始事件。前端默认使用内置离线事件流，因此发布到 GitHub Pages 后无需 API Key 或后端也能直接看到效果。

## 本地运行

在仓库根目录启动 MoonBit 后端：

```shell
moon run examples/web_agent/backend
```

然后用静态服务器打开 `examples/web_agent/frontend`，例如：

```shell
python -m http.server 4173 --directory examples/web_agent/frontend
```

打开 <http://127.0.0.1:4173/>，在右上角将模式切换为“连接后端”，端点填写 `http://127.0.0.1:8087/agent`。后端支持跨域预检，响应为标准 `data: {json}\n\n` SSE 帧。

## GitHub Pages

`.github/workflows/pages.yml` 会在 `main` 更新时发布 `examples/web_agent/frontend`。在仓库 Settings -> Pages 中将 Source 设为 **GitHub Actions**，之后页面地址通常为：

<https://quietlychan.github.io/moon-agui/>

Pages 模式默认选中“离线演示”，可观察 `RUN_STARTED`、`STEP_STARTED`、`TOOL_CALL_START`、`TOOL_CALL_RESULT`、`STATE_SNAPSHOT`、文本事件、`STEP_FINISHED` 和 `RUN_FINISHED`。要连接真实 MoonBit 后端，需要把后端部署到支持 CORS 的 HTTPS 地址，再在页面中选择“连接后端”并填写 `/agent` 地址。

## API

| Endpoint | 说明 |
| --- | --- |
| `GET /api/health` | 返回协议版本和 SSE transport 信息 |
| `POST /agent` | 接收 AG-UI `RunAgentInput`，返回事件流 |

请求示例：

```shell
curl -N http://127.0.0.1:8087/agent \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{"threadId":"thread-1","runId":"run-1","messages":[{"id":"m1","role":"user","content":"你好"}],"tools":[],"context":[]}'
```
