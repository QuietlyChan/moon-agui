///|
/// A deterministic AG-UI backend for the browser example and GitHub Pages demo.
struct DemoAgent {}

///|
fn latest_user_text(input : @core.RunAgentInput) -> String {
  let mut text = ""
  for message in input.messages() {
    match message {
      { "role": "user", "content": String(value), .. } => text = value
      _ => ()
    }
  }
  text
}

///|
impl @server.AgUiAgent for DemoAgent with fn run(self, input, emit) {
  ignore(self)
  let thread_id = input.thread_id()
  let run_id = input.run_id()
  let tool_call_id = run_id + "-lookup"
  let tool_message_id = run_id + "-tool-result"
  let message_id = run_id + "-assistant"
  let text = latest_user_text(input)
  let tool_result = "Lookup complete for: " + text
  let reply = "MoonBit received: " + text + ". " + tool_result
  let state : Json = {
    "lastTool": "lookup",
    "query": text,
    "result": tool_result,
  }
  emit(@core.AgUiEvent::run_started(thread_id~, run_id~))
  emit(@core.AgUiEvent::step_started(step_name="lookup"))
  emit(@core.AgUiEvent::tool_call_start(tool_call_id~, tool_call_name="lookup"))
  emit(
    @core.AgUiEvent::tool_call_args(
      tool_call_id~,
      delta="{\"query\":\"\{text}\"}",
    ),
  )
  emit(@core.AgUiEvent::tool_call_end(tool_call_id~))
  emit(
    @core.AgUiEvent::tool_call_result(
      message_id=tool_message_id,
      tool_call_id~,
      content=Json::string(tool_result),
    ),
  )
  emit(@core.AgUiEvent::state_snapshot(state))
  emit(@core.AgUiEvent::text_message_start(message_id~, role="assistant"))
  emit(@core.AgUiEvent::text_message_content(message_id~, delta=reply))
  emit(@core.AgUiEvent::text_message_end(message_id~))
  emit(@core.AgUiEvent::step_finished(step_name="lookup"))
  emit(@core.AgUiEvent::run_finished(thread_id~, run_id~))
}

///|
extend DemoAgent with @server.AgUiAgent::{run}

///|
fn response_headers(content_type : String) -> Map[String, String] {
  {
    "Content-Type": content_type,
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type, Accept",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Cache-Control": "no-store",
  }
}

///|
async fn send_json(
  conn : @http.ServerConnection,
  status : Int,
  reason : String,
  value : Json,
) -> Unit {
  conn.send_response(
    status,
    reason,
    extra_headers=response_headers("application/json; charset=utf-8"),
  )
  conn.write(value.stringify())
  conn.end_response()
}

///|
async fn send_error(
  conn : @http.ServerConnection,
  status : Int,
  reason : String,
  message : String,
) -> Unit {
  send_json(conn, status, reason, { "error": message })
}

///|
async fn send_options(conn : @http.ServerConnection) -> Unit {
  let headers = response_headers("text/plain; charset=utf-8")
  headers["Content-Length"] = "0"
  conn.send_response(204, "No Content", extra_headers=headers)
  conn.end_response()
}

///|
async fn handle_agent(
  body : &@io.Reader,
  conn : @http.ServerConnection,
) -> Unit {
  let input = @core.RunAgentInput::from_json_string(body.read_all().text()) catch {
    error => {
      send_error(conn, 400, "Bad Request", "Invalid AG-UI input: \{error}")
      return
    }
  }
  conn.send_response(200, "OK", extra_headers={
    "Content-Type": "text/event-stream; charset=utf-8",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type, Accept",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Cache-Control": "no-cache, no-transform",
    "Connection": "keep-alive",
    "X-Accel-Buffering": "no",
  })
  let agent = DemoAgent::{ }
  agent.run(input, event => {
    conn.write(@sse.frame(event))
    conn.flush()
  }) catch {
    error => {
      conn.write(
        @sse.frame(@core.AgUiEvent::run_error(message="Agent failed: \{error}")),
      )
      conn.flush()
    }
  }
  conn.end_response()
}

///|
async fn handle_request(
  request : @http.Request,
  body : &@io.Reader,
  conn : @http.ServerConnection,
) -> Unit {
  if request.meth is @http.Options {
    send_options(conn)
    return
  }
  match (request.meth, request.path) {
    (@http.Get, "/api/health") =>
      send_json(conn, 200, "OK", {
        "status": "ok",
        "protocolVersion": "1.0",
        "transport": "sse",
        "demo": true,
      })
    (@http.Post, "/agent") => handle_agent(body, conn)
    (@http.Get, _) | (@http.Post, _) =>
      send_error(conn, 404, "Not Found", "Route not found")
    _ =>
      send_error(
        conn, 405, "Method Not Allowed", "Use GET /api/health or POST /agent",
      )
  }
}

///|
fn configured_port() -> Int {
  match @env.get_env_var("AGUI_PORT") {
    Some(value) => @string.parse_int(value) catch { _ => 8087 }
    None => 8087
  }
}

///|
async fn main {
  let host = @env.get_env_var("AGUI_HOST").unwrap_or("127.0.0.1")
  let port = configured_port()
  let server = @http.Server(@socket.Addr::parse(host + ":" + port.to_string()))
  println("AG-UI web agent listening at http://\{host}:\{port}/agent")
  server.run_forever(handle_request) catch {
    error => println("Server stopped: \{error}")
  }
}
