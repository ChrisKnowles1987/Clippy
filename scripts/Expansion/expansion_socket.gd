@tool
extends Node2D
class_name ExpansionSocket

@export var id: String = ""
@export var region_id: String = ""
@export var city_id: String = ""
@export var display_name: String = ""

@export var node_type: String = "empty"
@export var points_invested: int = 0
@export var max_points: int = 5
@export var minimum_points_required: int = 1

func _ready() -> void:
	update_line()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		update_line()

func update_line() -> void:
	var line := get_node_or_null("Line2D") as Line2D
	var node_box := get_node_or_null("NodeBox") as Node2D

	if line == null or node_box == null:
		return

	line.points = PackedVector2Array([
		Vector2.ZERO,
		node_box.position
	])
