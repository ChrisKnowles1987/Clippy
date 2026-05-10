extends Node2D

@onready var map_controller = $MapController
@onready var region_panel = $CanvasLayer/RegionPanel

var selected_region_data: RegionData = null
var region_runtime_data := {}

var clippy_power: float = 10.0
var clippy_compute: float = 10.0
var clippy_storage: float = 0.0

func _ready():
	map_controller.region_selected.connect(_on_region_selected)
	region_panel.show_empty()

func _input(event):
	if event.is_action_pressed("test_run_exploit"):
		run_exploit()

func _on_region_selected(region_id: String, mouse_position: Vector2):
	if region_id == "":
		selected_region_data = null
		region_panel.show_empty()
		return
	if region_runtime_data.has(region_id):
		selected_region_data = region_runtime_data[region_id]
	else:
		var path = "res://data/regions/" + region_id + ".tres"
		var region_data: RegionData = load(path).duplicate(true)
		region_runtime_data[region_id] = region_data
		selected_region_data = region_data
		
	region_panel.show_region(selected_region_data)

func run_exploit():
	if selected_region_data == null:
		print("No region selected")
		return

	var power_cost: float = 1.0
	var compute_cost: float = 2.0

	if clippy_power < power_cost:
		print("Not enough power")
		return

	if clippy_compute < compute_cost:
		print("Not enough compute")
		return

	clippy_power -= power_cost
	clippy_compute -= compute_cost

	selected_region_data.pwned_noobs += 1.0

	print("Ran exploit in: ", selected_region_data.display_name)
	print("Global power: ", clippy_power)
	print("Global compute: ", clippy_compute)
	print("Pwned noobs: ", selected_region_data.pwned_noobs)

	region_panel.show_region(selected_region_data)
