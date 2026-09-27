///|
test "buffered emitter applies middleware in order" {
  let emitter = @emitter.BufferedEmitter::new()
  emitter.add_middleware(event => {
    @core.AgUiEvent::custom(name="wrapped", value=event.to_json())
  })
  emitter.emit(@core.AgUiEvent::run_started(thread_id="t1", run_id="r1"))
  assert_eq(emitter.events().length(), 1)
  assert_true(emitter.events()[0].event_type() is @core.EventType::Custom)
  emitter.clear()
  assert_eq(emitter.events().length(), 0)
}
