extends Node2D

@export var node_radius: float = 6.0

var active_nodes: Array[HackNodeData] = []


func set_nodes(new_nodes: Array[HackNodeData]) -> void:
	active_nodes = new_nodes
	queue_redraw()


func _draw() -> void:
	for hack_node in active_nodes:
		if hack_node.resolved:
			continue

		draw_circle(hack_node.map_position, node_radius, get_node_color(hack_node))


func get_node_color(hack_node: HackNodeData) -> Color:
	match hack_node.rarity:
		"common":
			return Color(0.3, 0.8, 1.0, 0.9)
		"uncommon":
			return Color(0.3, 1.0, 0.4, 0.9)
		"rare":
			return Color(0.8, 0.4, 1.0, 0.9)
		"elite":
			return Color(1.0, 0.4, 0.2, 0.9)
		_:
			return Color.WHITE
