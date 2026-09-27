///|
/// Agent implementation accepted by the AG-UI HTTP endpoint.
pub(open) trait AgUiAgent {
  async fn run(
    Self,
    input : @core.RunAgentInput,
    emit : async (@core.AgUiEvent) -> Unit,
  ) -> Unit
}

///|
fn response_headers(content_type : String) -> Map[String, String] {
  {
    "Content-Type": content_type,
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type, Accept",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Cache-Control": "no-store",
  }
}

///|
async fn write_json_error(
  conn : @http.ServerConnection,
  status : Int,
  reason : String,
  message : String,
) -> Unit {
  conn.send_response(
    status,
    reason,
    extra_headers=response_headers("application/json; charset=utf-8"),
  )
  conn.write(Json::object(Map([("error", Json::string(message))])).stringify())
  conn.end_response()
}

///|
async fn write_event(
  conn : @http.ServerConnection,
  event : @core.AgUiEvent,
) -> Unit {
  conn.write(@sse.frame(event))
  conn.flush()
}

///|
async fn handle_agent(
  body : &@io.Reader,
  conn : @http.ServerConnection,
  agent : &AgUiAgent,
) -> Unit {
  let input = @core.RunAgentInput::from_json_string(body.read_all().text()) catch {
    error => {
      write_json_error(
        conn,
        400,
        "Bad Request",
        "Invalid AG-UI input: \{error}",
      )
      return
    }
  }
  conn.send_response(200, "OK", extra_headers={
    "Content-Type": "text/event-stream; charset=utf-8",
    "Cache-Control": "no-cache, no-transform",
    "Connection": "keep-alive",
    "X-Accel-Buffering": "no",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type, Accept",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  })
  agent.run(input, event => write_event(conn, event)) catch {
    error =>
      write_event(
        conn,
        @core.AgUiEvent::run_error(message="Agent failed: \{error}"),
      )
  }
  conn.end_response()
}

///|
async fn handle_request(
  request : @http.Request,
  body : &@io.Reader,
  conn : @http.ServerConnection,
  agent : &AgUiAgent,
) -> Unit {
  if request.meth is @http.Options {
    let headers = response_headers("text/plain; charset=utf-8")
    headers["Content-Length"] = "0"
    conn.send_response(204, "No Content", extra_headers=headers)
    conn.end_response()
    return
  }
  match (request.meth, request.path) {
    (@http.Post, "/agent") => handle_agent(body, conn, agent)
    (@http.Post, _) =>
      write_json_error(conn, 404, "Not Found", "Route not found")
    _ => write_json_error(conn, 405, "Method Not Allowed", "Use POST /agent")
  }
}

///|
/// Start a native HTTP server exposing `POST /agent` as an AG-UI SSE stream.
pub async fn serve(
  agent : &AgUiAgent,
  host? : String = "127.0.0.1",
  port? : Int = 8087,
) -> Unit {
  let server = @http.Server(@socket.Addr::parse(host + ":" + port.to_string()))
  println("AG-UI endpoint listening at http://\{host}:\{port}/agent")
  server.run_forever((request, body, conn) => {
    handle_request(request, body, conn, agent)
  }) catch {
    error => println("AG-UI server stopped: \{error}")
  }
}
