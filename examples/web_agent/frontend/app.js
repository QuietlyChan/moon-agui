const elements = {
  clearButton: document.querySelector("#clearButton"),
  composer: document.querySelector("#composer"),
  connectionLabel: document.querySelector("#connectionLabel"),
  connectionStatus: document.querySelector("#connectionStatus"),
  emptyState: document.querySelector("#emptyState"),
  endpointInput: document.querySelector("#endpointInput"),
  eventCount: document.querySelector("#eventCount"),
  eventList: document.querySelector("#eventList"),
  hintText: document.querySelector("#hintText"),
  messageInput: document.querySelector("#messageInput"),
  modeSelect: document.querySelector("#modeSelect"),
  runBadge: document.querySelector("#runBadge"),
  runValue: document.querySelector("#runValue"),
  sendButton: document.querySelector("#sendButton"),
  threadValue: document.querySelector("#threadValue"),
  transcript: document.querySelector("#transcript"),
  characterCount: document.querySelector("#characterCount"),
};

const state = {
  controller: null,
  events: 0,
  generating: false,
  messages: [],
  mode: ["backend", "demo"].includes(new URLSearchParams(location.search).get("mode"))
    ? new URLSearchParams(location.search).get("mode")
    : (localStorage.getItem("agui-mode") === "backend" ? "backend" : "demo"),
  threadId: "thread-demo",
};

function id(prefix) {
  if (globalThis.crypto?.randomUUID) return `${prefix}-${crypto.randomUUID()}`;
  return `${prefix}-${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

function setConnection(kind, label) {
  elements.connectionStatus.dataset.state = kind;
  elements.connectionLabel.textContent = label;
}

function setMode(mode) {
  state.mode = mode;
  const backend = mode === "backend";
  elements.endpointInput.disabled = !backend;
  elements.hintText.textContent = backend
    ? "请求会发送到 endpoint，并实时解析 text/event-stream"
    : "离线演示会生成确定性的 AG-UI 事件";
  setConnection(backend ? "idle" : "demo", backend ? "等待后端" : "本地事件流");
  localStorage.setItem("agui-mode", mode);
}

function scrollToBottom(node) {
  requestAnimationFrame(() => { node.scrollTop = node.scrollHeight; });
}

function appendMessage(role, text = "") {
  const article = document.createElement("article");
  article.className = `message ${role}`;
  const meta = document.createElement("div");
  meta.className = "message-meta";
  meta.textContent = role === "user" ? "你" : "AG-UI Agent";
  const content = document.createElement("p");
  content.className = "message-content";
  content.textContent = text;
  article.append(meta, content);
  elements.transcript.append(article);
  scrollToBottom(elements.transcript);
  return { article, content };
}

function resetEvents() {
  state.events = 0;
  elements.eventList.replaceChildren(elements.emptyState);
  elements.emptyState.hidden = false;
  elements.eventCount.textContent = "0";
}

function summarize(event) {
  switch (event.type) {
    case "TEXT_MESSAGE_CONTENT": return event.delta || "文本增量";
    case "TEXT_MESSAGE_START": return event.role ? `role: ${event.role}` : "消息开始";
    case "TOOL_CALL_START": return event.toolCallName || "工具调用开始";
    case "TOOL_CALL_ARGS": return event.delta || "参数增量";
    case "STATE_SNAPSHOT": return "共享状态快照";
    case "STATE_DELTA": return "共享状态补丁";
    case "RUN_ERROR": return event.message || "运行错误";
    default: return "AG-UI event";
  }
}

function addEvent(event) {
  state.events += 1;
  elements.emptyState.hidden = true;
  const item = document.createElement("article");
  item.className = "event-item";
  const header = document.createElement("div");
  header.className = "event-item-header";
  const type = document.createElement("strong");
  type.textContent = event.type || "UNKNOWN";
  const number = document.createElement("span");
  number.textContent = String(state.events).padStart(2, "0");
  header.append(type, number);
  const summary = document.createElement("p");
  summary.textContent = summarize(event);
  const raw = document.createElement("pre");
  raw.textContent = JSON.stringify(event, null, 2);
  raw.hidden = true;
  item.append(header, summary, raw);
  item.addEventListener("click", () => { raw.hidden = !raw.hidden; });
  elements.eventList.append(item);
  elements.eventCount.textContent = String(state.events);
  scrollToBottom(elements.eventList);
}

function handleEvent(event, assistant) {
  addEvent(event);
  switch (event.type) {
    case "RUN_STARTED":
      elements.threadValue.textContent = event.threadId || state.threadId;
      elements.runValue.textContent = event.runId || "未知";
      elements.runBadge.textContent = "RUNNING";
      break;
    case "TEXT_MESSAGE_CONTENT":
      assistant.content.textContent += event.delta || "";
      scrollToBottom(elements.transcript);
      break;
    case "RUN_FINISHED":
      elements.runBadge.textContent = "FINISHED";
      break;
    case "RUN_ERROR":
      throw new Error(event.message || "AG-UI run failed");
    default:
      break;
  }
}

function demoEvents(text, runId) {
  const reply = `这是 MoonBit AG-UI 的离线演示。你发送了：“${text}”`;
  const chunks = ["这是 MoonBit AG-UI 的离线演示。", `你发送了：“${text}”`];
  return [
    { type: "RUN_STARTED", threadId: state.threadId, runId, protocolVersion: "1.0" },
    { type: "STEP_STARTED", stepName: "offline-demo" },
    { type: "TEXT_MESSAGE_START", messageId: `${runId}-message`, role: "assistant" },
    ...chunks.map((delta) => ({ type: "TEXT_MESSAGE_CONTENT", messageId: `${runId}-message`, delta })),
    { type: "TEXT_MESSAGE_END", messageId: `${runId}-message` },
    { type: "STATE_SNAPSHOT", snapshot: { mode: "offline", text: reply } },
    { type: "STEP_FINISHED", stepName: "offline-demo" },
    { type: "RUN_FINISHED", threadId: state.threadId, runId },
  ];
}

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function runDemo(text, assistant) {
  for (const event of demoEvents(text, id("run"))) {
    if (state.controller?.signal.aborted) throw new DOMException("Stopped", "AbortError");
    await wait(160);
    handleEvent(event, assistant);
  }
}

function decodeFrame(frame) {
  const data = frame.split(/\r?\n/)
    .filter((line) => line.startsWith("data:"))
    .map((line) => line.slice(5).trimStart())
    .join("\n");
  if (!data || data === "[DONE]") return null;
  return JSON.parse(data);
}

async function runBackend(text, assistant) {
  const runId = id("run");
  const response = await fetch(elements.endpointInput.value.trim(), {
    method: "POST",
    headers: { "Content-Type": "application/json", Accept: "text/event-stream" },
    body: JSON.stringify({
      threadId: state.threadId,
      runId,
      protocolVersion: "1.0",
      messages: [{ id: id("message"), role: "user", content: text }],
      tools: [],
      context: [],
    }),
    signal: state.controller.signal,
  });
  if (!response.ok) throw new Error(`后端返回 HTTP ${response.status}`);
  if (!response.body) throw new Error("浏览器没有收到流式响应");
  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let buffer = "";
  while (true) {
    const { value, done } = await reader.read();
    buffer += decoder.decode(value || new Uint8Array(), { stream: !done });
    const frames = buffer.split(/\r?\n\r?\n/);
    buffer = frames.pop() || "";
    for (const frame of frames) {
      const event = decodeFrame(frame);
      if (event) handleEvent(event, assistant);
    }
    if (done) break;
  }
  if (buffer.trim()) {
    const event = decodeFrame(buffer);
    if (event) handleEvent(event, assistant);
  }
}

async function submit(event) {
  event.preventDefault();
  const text = elements.messageInput.value.trim();
  if (!text || state.generating) return;
  appendMessage("user", text);
  state.messages.push({ role: "user", content: text });
  elements.messageInput.value = "";
  updateComposer();
  resetEvents();
  const assistant = appendMessage("assistant");
  assistant.article.dataset.state = "streaming";
  state.generating = true;
  state.controller = new AbortController();
  elements.sendButton.disabled = true;
  elements.runBadge.textContent = "STARTING";
  try {
    if (state.mode === "demo") {
      await runDemo(text, assistant);
      setConnection("demo", "本地事件流");
    } else {
      await runBackend(text, assistant);
      setConnection("online", "后端已连接");
    }
    state.messages.push({ role: "assistant", content: assistant.content.textContent });
  } catch (error) {
    assistant.content.textContent = error.name === "AbortError" ? "已停止本次运行。" : `请求失败：${error.message}`;
    assistant.article.dataset.state = "error";
    elements.runBadge.textContent = "ERROR";
    if (error.name !== "AbortError") setConnection("offline", "连接失败");
  } finally {
    assistant.article.dataset.state = "complete";
    state.controller = null;
    state.generating = false;
    elements.sendButton.disabled = false;
    elements.messageInput.focus();
  }
}

function updateComposer() {
  const length = elements.messageInput.value.length;
  elements.characterCount.textContent = `${length} / 2000`;
  elements.sendButton.disabled = state.generating || length === 0;
  elements.messageInput.style.height = "auto";
  elements.messageInput.style.height = `${Math.min(elements.messageInput.scrollHeight, 120)}px`;
}

function clearConversation() {
  state.controller?.abort();
  state.messages = [];
  elements.transcript.replaceChildren();
  elements.messageInput.value = "";
  elements.threadValue.textContent = "未开始";
  elements.runValue.textContent = "未开始";
  elements.runBadge.textContent = "READY";
  resetEvents();
  updateComposer();
}

elements.modeSelect.value = state.mode;
elements.endpointInput.value = new URLSearchParams(location.search).get("endpoint") || localStorage.getItem("agui-endpoint") || elements.endpointInput.value;
elements.modeSelect.addEventListener("change", (event) => setMode(event.target.value));
elements.endpointInput.addEventListener("change", () => localStorage.setItem("agui-endpoint", elements.endpointInput.value.trim()));
elements.composer.addEventListener("submit", submit);
elements.clearButton.addEventListener("click", clearConversation);
elements.messageInput.addEventListener("input", updateComposer);
elements.messageInput.addEventListener("keydown", (event) => {
  if (event.key === "Enter" && !event.shiftKey && !event.isComposing) {
    event.preventDefault();
    elements.composer.requestSubmit();
  }
});
setMode(state.mode);
updateComposer();
appendMessage("assistant", "欢迎来到 AG-UI Protocol Lab。发送消息，观察一次完整的流式事件。 ");
