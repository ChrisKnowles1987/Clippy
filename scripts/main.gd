extends Node2D

@onready var map_controller = $MapController
@onready var region_panel = $CanvasLayer/RegionPanel

var selected_region_data: RegionData = null

func _ready():
	map_controller.region_selected.connect(_on_region_selected)
	region_panel.show_empty()

func _input(event):
	if event.is_action_pressed("test_add_power"):
		add_resource_to_selected_region("clippy_power", 1.0)

	if event.is_action_pressed("test_add_compute"):
		add_resource_to_selected_region("clippy_compute", 1.0)

	if event.is_action_pressed("test_add_storage"):
		add_resource_to_selected_region("clippy_storage", 1.0)

	if event.is_action_pressed("test_add_influence"):
		add_resource_to_selected_region("clippy_influence", 1.0)

	if event.is_action_pressed("test_add_control"):
		add_resource_to_selected_region("clippy_control", 1.0)

func _on_region_selected(region_id: String, mouse_position: Vector2):
	if region_id == "":
		selected_region_data = null
		region_panel.show_empty()
		return

	var path = "res://data/regions/" + region_id + ".tres"
	var region_data: RegionData = load(path)

	selected_region_data = region_data

	region_panel.show_region(region_data)

func add_resource_to_selected_region(resource_name: String, amount: float):
	if selected_region_data == null:
		print("No region selected")
		return


	match resource_name:
		"clippy_power":
			selected_region_data.clippy_power += amount
			print("Power: ", selected_region_data.clippy_power)

		"clippy_compute":
			selected_region_data.clippy_compute += amount
			print("Compute: ", selected_region_data.clippy_compute)

		"clippy_storage":
			selected_region_data.clippy_storage += amount
			print("Storage: ", selected_region_data.clippy_storage)

		"clippy_influence":
			selected_region_data.clippy_influence += amount
			print("Influence: ", selected_region_data.clippy_influence)

		"clippy_control":
			selected_region_data.clippy_control += amount
			print("Control: ", selected_region_data.clippy_control)

		_:
			print("Unknown resource: ", resource_name)
	region_panel.show_region(selected_region_data)
	print("Added power to: ", selected_region_data.display_name)
	print("Power: ", selected_region_data.clippy_power)
