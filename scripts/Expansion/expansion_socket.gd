@tool
extends Node2D

signal expansion_socket_clicked(socket)

const NODE_TYPE_EMPTY := "empty"
const NODE_TYPE_POWER := "power"
const NODE_TYPE_COMPUTE := "compute"

@export var id: String = ""
@export var region_id: String = ""
@export var city_id: String = ""
@export var display_name: String = ""

@export var node_type: String = NODE_TYPE_EMPTY
@export var points_invested: int = 0
@export var max_points: int = 5
@export var minimum_points_required: int = 1
@export var node_box_offset: Vector2 = Vector2(0, -35)
@export var power_icon_texture: Texture2D
@export var compute_icon_texture: Texture2D

func _ready() -> void:
	update_node_box()
	update_line()
	update_visual_state()

	var area := get_node_or_null("NodeBox/Area2D") as Area2D
	if area != null:
		area.input_pickable = false


func _process(_delta: float) -> void:
	update_node_box()
	update_line()
	update_visual_state()


func refresh_visual() -> void:
	update_node_box()
	update_line()
	update_visual_state()


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


func update_visual_state() -> void:
	var active := node_type != NODE_TYPE_EMPTY and points_invested > 0
	var line := get_node_or_null("Line2D") as Line2D
	var node_box := get_node_or_null("NodeBox") as Node2D
	var sprite := get_node_or_null("NodeBox/Sprite2D") as Sprite2D

	if Engine.is_editor_hint():
		visible = true
	else:
		visible = active

	if line != null:
		line.visible = active or Engine.is_editor_hint()

	if node_box != null:
		node_box.visible = active or Engine.is_editor_hint()

	if sprite == null:
		return

	match node_type:
		NODE_TYPE_POWER:
			if power_icon_texture != null:
				sprite.texture = power_icon_texture
		NODE_TYPE_COMPUTE:
			if compute_icon_texture != null:
				sprite.texture = compute_icon_texture
