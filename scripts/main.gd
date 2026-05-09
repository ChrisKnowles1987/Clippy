extends Node2D

@onready var map_controller = $MapController
@onready var region_panel = $CanvasLayer/RegionPanel

func _ready():
	print("MAIN READY")
	map_controller.region_selected.connect(_on_region_selected)
	region_panel.hide()


func _on_region_selected(region_id: String, mouse_position: Vector2):
	print("REGION CLICKED: ", region_id)

	if region_id == "":
		region_panel.hide()
		return

	var path = "res://data/regions/" + region_id + ".tres"
	var region_data = load(path)

	print("LOADED DATA: ", region_data)

	region_panel.show_region(region_data, mouse_position)
