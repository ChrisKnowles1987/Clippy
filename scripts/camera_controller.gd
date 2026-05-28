extends Camera2D

@export var pan_speed: float = 900.0
@export var zoom_step: float = 0.1
@export var min_zoom: float = 0.4
@export var max_zoom: float = 2.5

@export var map_center: Vector2 = Vector2(960, 540)
@export var map_size: Vector2 = Vector2(5000, 2700)

@export var map_bounds_sprite: Sprite2D

var right_mouse_dragging: bool = false
var last_mouse_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	enabled = true
	clamp_to_map_edges()


func _process(delta: float) -> void:
	var direction: Vector2 = Vector2.ZERO

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
	if event is InputEventMouseButton == false:
		return

	var mouse_event := event as InputEventMouseButton

	if mouse_event.pressed == false:
		return

	if mouse_event.button_index != MOUSE_BUTTON_WHEEL_UP and mouse_event.button_index != MOUSE_BUTTON_WHEEL_DOWN:
		return

	if is_mouse_over_map(mouse_event.position) == false:
		return

	if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoom_at_mouse(zoom.x + zoom_step)

	if mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoom_at_mouse(zoom.x - zoom_step)


func is_mouse_over_map(mouse_screen_position: Vector2) -> bool:
	if map_bounds_sprite == null:
		return false

	if map_bounds_sprite.texture == null:
		return false

	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	var mouse_world_position: Vector2 = canvas_transform.affine_inverse() * mouse_screen_position
	var mouse_local_position: Vector2 = map_bounds_sprite.to_local(mouse_world_position)

	var texture_size: Vector2 = map_bounds_sprite.texture.get_size()
	var top_left: Vector2 = map_bounds_sprite.offset

	if map_bounds_sprite.centered:
		top_left -= texture_size * 0.5

	var map_rect: Rect2 = Rect2(top_left, texture_size)

	return map_rect.has_point(mouse_local_position)


func zoom_at_mouse(target_zoom: float) -> void:
	var new_zoom_value: float = clampf(target_zoom, min_zoom, max_zoom)

	if is_equal_approx(new_zoom_value, zoom.x):
		return

	var before_zoom: Vector2 = get_global_mouse_position()

	zoom = Vector2(new_zoom_value, new_zoom_value)

	var after_zoom: Vector2 = get_global_mouse_position()
	position += before_zoom - after_zoom

	clamp_to_map_edges()


func clamp_to_map_edges() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var visible_size: Vector2 = viewport_size / zoom

	var map_left: float = map_center.x - map_size.x * 0.5
	var map_right: float = map_center.x + map_size.x * 0.5
	var map_top: float = map_center.y - map_size.y * 0.5
	var map_bottom: float = map_center.y + map_size.y * 0.5

	var half_visible_width: float = visible_size.x * 0.5
	var half_visible_height: float = visible_size.y * 0.5

	var min_x: float = map_left + half_visible_width
	var max_x: float = map_right - half_visible_width
	var min_y: float = map_top + half_visible_height
	var max_y: float = map_bottom - half_visible_height

	if min_x > max_x:
		position.x = map_center.x
	else:
		position.x = clampf(position.x, min_x, max_x)

	if min_y > max_y:
		position.y = map_center.y
	else:
		position.y = clampf(position.y, min_y, max_y)
