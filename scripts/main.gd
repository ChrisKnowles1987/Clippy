extends Node2D

@onready var map_controller = $MapController
@onready var game_clock = $GameClock
@onready var region_manager = $RegionManager
@onready var global_resource_manager = $GlobalResourceManager

@onready var region_panel = $CanvasLayer/RegionPanel
@onready var global_resource_panel = $CanvasLayer/GlobalResourcePanel
@onready var intrusion_panel = $CanvasLayer/BottomSkillPannel/Control/MarginContainer/IntrusionSkillPannelContainer
@onready var game_day_timer_label: Label = $CanvasLayer/GlobalResourcePanel/DateValueLabel

@onready var hack_node_manager = $HackNodeManager
@onready var hack_node_layer = $MapController/HackNodeLayer

func _ready() -> void:
	map_controller.region_selected.connect(_on_region_selected)
	game_clock.day_passed.connect(_on_day_passed)
	global_resource_manager.resources_changed.connect(_on_resources_changed)

	region_panel.show_empty()
	intrusion_panel.show_empty()

	update_date_ui(game_clock.current_date)
	update_global_resource_ui()

func _process(_delta: float) -> void: 
	var day_progress = game_clock.get_day_progress_percent()
	intrusion_panel.update_day_progress(day_progress)
	
func _on_day_passed(current_date: Dictionary) -> void:
	update_date_ui(current_date)
	process_intrusion_skills()
	generate_daily_nodes()



func generate_daily_nodes() -> void:
	for region_id in region_manager.regions.keys():
		var region_data: RegionData = region_manager.regions[region_id]
		var region_state: RegionState = region_manager.get_region_state(region_id)

		if region_state == null:
			continue

		if region_state.scan_networks_enabled == false:
			continue

		hack_node_manager.generate_region_nodes(
			region_data,
			region_state
		)

	hack_node_layer.set_nodes(
		hack_node_manager.active_nodes
	)


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

	var region_state = region_manager.get_region_state(region_id)
	region_panel.show_region(selected_region_data, region_state)
	intrusion_panel.show_region(selected_region_data, region_state)
	

func process_intrusion_skills() -> void:
	for region_id in region_manager.region_states.keys():
		var region_state: RegionState = region_manager.get_region_state(region_id)

		if region_state == null:
			continue

		process_run_exploit_state(region_state)
		process_scan_networks_state(region_state)

	if region_manager.selected_region_data == null:
		return

	var selected_region_id = region_manager.selected_region_data.id
	var selected_region_state = region_manager.get_region_state(selected_region_id)

	if selected_region_state == null:
		return

	region_panel.show_region(region_manager.selected_region_data, selected_region_state)
	intrusion_panel.show_region(region_manager.selected_region_data, selected_region_state)


func process_run_exploit_state(region_state: RegionState) -> void:
	if region_state.run_exploit_enabled == false:
		return

	var paid:bool  = global_resource_manager.spend(
		region_state.run_exploit_power_per_day,
		region_state.run_exploit_compute_per_day
	)

	if paid == false:
		region_state.run_exploit_enabled = false


func process_scan_networks_state(region_state: RegionState) -> void:
	if region_state.scan_networks_enabled == false:
		return

	region_state.network_visibility += region_state.scan_networks_level
