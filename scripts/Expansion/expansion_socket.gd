@tool
extends Node2D

signal expansion_socket_clicked(socket)

@export var id: String = ""
@export var region_id: String = ""
@export var city_id: String = ""
@export var display_name: String = ""

@export var node_type: String = "empty"
@export var points_invested: int = 0
@export var max_points: int = 5
@export var minimum_points_required: int = 1
@export var node_box_offset: Vector2 = Vector2(0, -35)

func _ready() -> void:
	update_node_box()
	update_line()

	var area := get_node_or_null("NodeBox/Area2D") as Area2D
	if area != null:
		area.input_pickable = true
		if area.input_event.is_connected(_on_area_input_event) == false:
			area.input_event.connect(_on_area_input_event)

func _process(_delta: float) -> void:
	update_node_box()
	update_line()

func update_node_box() -> void:
	var node_box := get_node_or_null("NodeBox") as Node2D
	if node_box == null:
		return

	node_box.position = node_box_offset

func update_line() -> void:
	var line := get_node_or_null("Line2D") as Line2D
	if line == null:
		return

	line.points = PackedVector2Array([
		Vector2.ZERO,
		node_box_offset
	])

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if Engine.is_editor_hint():
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Clicked expansion socket: ", id, " region: ", region_id, " city: ", city_id)
		expansion_socket_clicked.emit(self)
