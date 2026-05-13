extends Camera2D

@export var pan_speed: float = 900.0
@export var zoom_step: float = 0.1
@export var min_zoom: float = 0.4
@export var max_zoom: float = 2.5

func _ready() -> void:
	enabled = true

func _process(delta: float) -> void:
	var direction := Vector2.ZERO

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0

	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0

	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0

	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0

	if direction != Vector2.ZERO:
		position += direction.normalized() * pan_speed * delta / zoom.x

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var new_zoom = clamp(zoom.x + zoom_step, min_zoom, max_zoom)
			zoom = Vector2(new_zoom, new_zoom)

		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var new_zoom = clamp(zoom.x - zoom_step, min_zoom, max_zoom)
			zoom = Vector2(new_zoom, new_zoom)
