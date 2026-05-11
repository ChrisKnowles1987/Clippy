extends Node2D

@onready var map_controller = $MapController
@onready var game_clock = $GameClock
@onready var region_manager = $RegionManager
@onready var global_resource_manager = $GlobalResourceManager

@onready var region_panel = $CanvasLayer/RegionPanel
@onready var global_resource_panel = $CanvasLayer/GlobalResourcePanel
@onready var intrusion_panel = $CanvasLayer/BottomSkillPannel/Control/MarginContainer/IntrusionSkillPannelContainer
@onready var game_day_timer_label: Label = $CanvasLayer/GlobalResourcePanel/DateValueLabel

func _ready() -> void:
	map_controller.region_selected.connect(_on_region_selected)
	game_clock.day_passed.connect(_on_day_passed)
	global_resource_manager.resources_changed.connect(_on_resources_changed)

	region_panel.show_empty()
	intrusion_panel.show_empty()

	update_date_ui(game_clock.current_date)
	update_global_resource_ui()

func _input(event) -> void:
	if event.is_action_pressed("test_run_exploit"):
		run_exploit()

func _on_day_passed(current_date: Dictionary) -> void:
	update_date_ui(current_date)

func update_date_ui(current_date: Dictionary) -> void:
	game_day_timer_label.text = "%02d/%02d/%04d" % [
		current_date.day,
		current_date.month,
		current_date.year
	]

func update_global_resource_ui() -> void:
	global_resource_panel.update_values(
		global_resource_manager.clippy_power,
		global_resource_manager.clippy_compute,
		global_resource_manager.clippy_storage
	)

func _on_resources_changed(power: float, compute: float, storage: float) -> void:
	global_resource_panel.update_values(power, compute, storage)

func _on_region_selected(region_id: String, mouse_position: Vector2) -> void:
	if region_id == "":
		return

	var selected_region_data: RegionData = region_manager.select_region(region_id)

	region_panel.show_region(selected_region_data)
	intrusion_panel.show_region(selected_region_data)

func run_exploit() -> void:
	var selected_region_data: RegionData = region_manager.selected_region_data

	if selected_region_data == null:
		print("No region selected")
		return

	var power_cost: float = 1.0
	var compute_cost: float = 2.0

	var paid = global_resource_manager.spend(power_cost, compute_cost)

	if paid == false:
		return

	selected_region_data.pwned_noobs += 1.0

	print("Ran exploit in: ", selected_region_data.display_name)
	print("Pwned noobs: ", selected_region_data.pwned_noobs)

	region_panel.show_region(selected_region_data)
	intrusion_panel.show_region(selected_region_data)
