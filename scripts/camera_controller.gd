extends Camera2D

@export var pan_speed: float = 900.0
@export var zoom_step: float = 0.1
@export var min_zoom: float = 0.4
@export var max_zoom: float = 2.5

@export var map_center: Vector2 = Vector2(960, 540)
@export var map_size: Vector2 = Vector2(5000, 2000)

var right_mouse_dragging: bool = false
var last_mouse_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	enabled = true
	clamp_to_map_edges()


func _process(delta: float) -> void:
	var direction = Vector2.ZERO

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
		clamp_to_map_edges()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			right_mouse_dragging = event.pressed
			last_mouse_position = get_viewport().get_mouse_position()

		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var new_zoom = clamp(zoom.x + zoom_step, min_zoom, max_zoom)
			zoom = Vector2(new_zoom, new_zoom)
			clamp_to_map_edges()

		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var new_zoom = clamp(zoom.x - zoom_step, min_zoom, max_zoom)
			zoom = Vector2(new_zoom, new_zoom)
			clamp_to_map_edges()

	if event is InputEventMouseMotion and right_mouse_dragging:
		var current_mouse_position = get_viewport().get_mouse_position()
		var mouse_delta = current_mouse_position - last_mouse_position

		position -= mouse_delta / zoom.x
		last_mouse_position = current_mouse_position

		clamp_to_map_edges()


func clamp_to_map_edges() -> void:
	var viewport_size = get_viewport_rect().size
	var visible_size = viewport_size / zoom

	var map_left = map_center.x - map_size.x * 0.5
	var map_right = map_center.x + map_size.x * 0.5
	var map_top = map_center.y - map_size.y * 0.5
	var map_bottom = map_center.y + map_size.y * 0.5

	var half_visible_width = visible_size.x * 0.5
	var half_visible_height = visible_size.y * 0.5

	var min_x = map_left + half_visible_width
	var max_x = map_right - half_visible_width
	var min_y = map_top + half_visible_height
	var max_y = map_bottom - half_visible_height

	if min_x > max_x:
		position.x = map_center.x
	else:
		position.x = clamp(position.x, min_x, max_x)

	if min_y > max_y:
		position.y = map_center.y
	else:
		position.y = clamp(position.y, min_y, max_y)
