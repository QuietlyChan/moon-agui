///|
/// A synchronous event transform used by a buffered emitter.
pub type Middleware = (@core.AgUiEvent) -> @core.AgUiEvent

///|
/// Minimal event emitter contract for agent integrations.
pub(open) trait EventEmitter {
  fn emit(Self, @core.AgUiEvent) -> Unit
  fn events(Self) -> Array[@core.AgUiEvent]
  fn clear(Self) -> Unit
}

///|
/// In-memory emitter useful for tests, replay, and adapters that own flushing.
pub struct BufferedEmitter {
  values : Array[@core.AgUiEvent]
  middleware : Array[Middleware]
}

///|
/// Create an empty buffered emitter.
pub fn BufferedEmitter::new() -> BufferedEmitter {
  { values: [], middleware: [], }
}

///|
/// Add a middleware transform. Middleware runs in registration order.
pub fn BufferedEmitter::add_middleware(
  self : BufferedEmitter,
  middleware : Middleware,
) -> Unit {
  self.middleware.push(middleware)
}

///|
impl EventEmitter for BufferedEmitter with fn emit(self, event) {
  let mut current = event
  for transform in self.middleware {
    current = transform(current)
  }
  self.values.push(current)
}

///|
impl EventEmitter for BufferedEmitter with fn events(self) {
  self.values
}

///|
impl EventEmitter for BufferedEmitter with fn clear(self) {
  self.values.clear()
}

///|
pub extend BufferedEmitter with EventEmitter::{emit, events, clear}

///|
/// Emit an event after applying a one-off middleware transform.
pub fn emit_with(
  emitter : BufferedEmitter,
  event : @core.AgUiEvent,
  middleware : Middleware,
) -> Unit {
  EventEmitter::emit(emitter, middleware(event))
}
