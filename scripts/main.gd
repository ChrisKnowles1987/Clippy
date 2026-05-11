extends Node2D

@onready var map_controller = $MapController
@onready var region_panel = $CanvasLayer/RegionPanel
@onready var global_resource_panel = $CanvasLayer/GlobalResourcePanel
@onready var intrusion_panel = $CanvasLayer/BottomSkillPannel/Control/MarginContainer/IntrusionSkillPannelContainer

@onready var game_day_timer: Timer = $GameDayTimer
@onready var game_day_timer_label: Label = $CanvasLayer/GlobalResourcePanel/DateValueLabel

var current_date: Dictionary = {}

var selected_region_data: RegionData = null
var region_runtime_data := {}

var clippy_power: float = 10.0
var clippy_compute: float = 10.0
var clippy_storage: float = 0.0

func _ready():
	initialize_game_date()
	update_date_ui()
	game_day_timer.timeout.connect(_on_game_day_timer_timeout)
	
	map_controller.region_selected.connect(_on_region_selected)
	region_panel.show_empty()
	intrusion_panel.show_empty()
	update_global_resource_ui()
	
func initialize_game_date():
	current_date = Time.get_date_dict_from_system()
	
func _on_game_day_timer_timeout() -> void:
	advance_one_day()
	update_date_ui()


func advance_one_day() -> void:
	var unix_time := Time.get_unix_time_from_datetime_dict(current_date)

	unix_time += 86400

	current_date = Time.get_datetime_dict_from_unix_time(unix_time)


func update_date_ui() -> void:
	game_day_timer_label.text = "%02d/%02d/%04d" % [
		current_date.day,
		current_date.month,
		current_date.year
	]	


func update_global_resource_ui():
	global_resource_panel.update_values(
		clippy_power,
		clippy_compute,
		clippy_storage
	)


func _input(event):
	if event.is_action_pressed("test_run_exploit"):
		run_exploit()

func _on_region_selected(region_id: String, mouse_position: Vector2):
	if region_id == "":
		#selected_region_data = null
		#region_panel.show_empty()
		#intrusion_panel.show_empty()
		return
	if region_runtime_data.has(region_id):
		selected_region_data = region_runtime_data[region_id]
	else:
		var path = "res://data/regions/" + region_id + ".tres"
		var region_data: RegionData = load(path).duplicate(true)
		region_runtime_data[region_id] = region_data
		selected_region_data = region_data
		
	region_panel.show_region(selected_region_data)
	intrusion_panel.show_region(selected_region_data)

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
	update_global_resource_ui()

	print("Ran exploit in: ", selected_region_data.display_name)
	print("Global power: ", clippy_power)
	print("Global compute: ", clippy_compute)
	print("Pwned noobs: ", selected_region_data.pwned_noobs)

	region_panel.show_region(selected_region_data)
