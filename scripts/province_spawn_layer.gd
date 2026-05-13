extends Node2D

@export var dot_radius: float = 3.0
@export var dot_color: Color = Color(0.1, 0.8, 1.0, 0.85)

var spawn_points: Array[Dictionary] = []

func set_spawn_points(new_spawn_points: Array[Dictionary]) -> void:
	spawn_points = new_spawn_points
	queue_redraw()

func _draw() -> void:
	for spawn_point in spawn_points:
		draw_circle(spawn_point["position"], dot_radius, dot_color)
