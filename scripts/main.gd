extends Node2D

@onready var map_controller = $MapController
@onready var region_panel = $CanvasLayer/RegionPanel

func _ready():
	map_controller.region_selected.connect(_on_region_selected)
	region_panel.show_empty()


func _on_region_selected(region_id: String, mouse_position: Vector2):
	if region_id == "":
		region_panel.show_empty()
		return

	var path = "res://data/regions/" + region_id + ".tres"
	var region_data = load(path)

	region_panel.show_region(region_data)
