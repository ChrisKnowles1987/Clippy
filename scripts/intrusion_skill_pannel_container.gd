extends Control

@onready var region_name_label: Label = $"SumnmaryContainer/TitleRowContainer/IntrusionSkillPannelRegionNameLabel"
@onready var power_cost_label: Label = $"SumnmaryContainer/TitleRowContainer/PowerCostLabel"
@onready var compute_cost_label: Label = $"SumnmaryContainer/TitleRowContainer/ComputeCostLabel"
@onready var infiltration_button: Button = $"SumnmaryContainer/TitleRowContainer/Infiltration"
@onready var expand_button: Button = $"SumnmaryContainer/TitleRowContainer/ExpandCollapseButton"

@onready var intelligence_progress_bar: ProgressBar = $SumnmaryContainer/TitleRowContainer2/IntelligenceProgressBar

@onready var details_container: Control = $DetailsContainer
@onready var foothold_value_label: Label = $DetailsContainer/Foothold/FootHoldValueLabel
@onready var active_nodes_value_label: Label = $DetailsContainer/ActiveNodes/ActiveNodesValueLabel
@onready var notoriety_value_label: Label = $DetailsContainer/DiscoveryChance/NotorietyChanceValueLabel
@onready var exploit_activity_value_label: Label = $DetailsContainer/ExploitActivity/ExploitActivityValueLabel
@onready var terminal_log: RichTextLabel = $DetailsContainer/TerminalContainer/TerminalLog

@onready var global_resource_manager = get_node("/root/Node2D/GlobalResourceManager")

const MAX_LOG_LINES := 24

var selected_region_data: RegionData = null
var selected_region_state: RegionState = null

var expanded: bool = false
var intrusion_logs_by_region: Dictionary = {}

var flavour_lines_scan := [
	"probing regional network surface",
	"classifying packet noise",
	"indexing exposed infrastructure",
	"mapping public routing behaviour",
	"sampling weak authentication signals"
]


func _ready() -> void:
	infiltration_button.pressed.connect(_on_infiltration_button_pressed)
	expand_button.pressed.connect(_on_expand_button_pressed)

	terminal_log.bbcode_enabled = true
	terminal_log.scroll_following = true

	expanded = false
	update_details_visibility()
	refresh_ui()


func show_empty() -> void:
	selected_region_data = null
	selected_region_state = null
	visible = false


func show_region(region_data: RegionData, region_state: RegionState) -> void:
	selected_region_data = region_data
	selected_region_state = region_state
	visible = true
	refresh_ui()


func refresh_ui() -> void:
	if selected_region_data == null:
		return

	if selected_region_state == null:
		return

	refresh_region_label()
	refresh_infiltration_ui()
	refresh_intelligence_ui()
	refresh_details_ui()
	refresh_terminal_log()


func refresh_region_label() -> void:
	region_name_label.text = str(selected_region_data.display_name)


func refresh_infiltration_ui() -> void:
	var power_cost := get_infiltration_power_cost()
	var compute_cost := get_infiltration_compute_cost()

	power_cost_label.text = str(snapped(power_cost, 0.1))
	compute_cost_label.text = str(snapped(compute_cost, 0.1))

	if selected_region_state.infiltration_enabled:
		infiltration_button.text = "online"
	else:
		infiltration_button.text = "offline"


func refresh_intelligence_ui() -> void:
	intelligence_progress_bar.min_value = 0.0
	intelligence_progress_bar.max_value = 100.0
	intelligence_progress_bar.value = selected_region_state.intelligence_percent


func refresh_details_ui() -> void:
	foothold_value_label.text = get_network_foothold_title(selected_region_state.network_visibility)
	active_nodes_value_label.text = str(selected_region_state.active_node_ids.size())
	notoriety_value_label.text = get_notoriety_title()
	exploit_activity_value_label.text = get_exploit_activity_title()


func refresh_terminal_log() -> void:
	var region_id := selected_region_state.region_id

	if intrusion_logs_by_region.has(region_id) == false:
		intrusion_logs_by_region[region_id] = [
			"network offline"
		]

	var lines: Array = intrusion_logs_by_region[region_id]
	var output := ""

	for line in lines:
		output += "> " + str(line) + "\n"

	terminal_log.text = output


func _on_infiltration_button_pressed() -> void:
	if selected_region_state == null:
		return

	if selected_region_state.infiltration_enabled:
		disable_infiltration()
	else:
		enable_infiltration()

	refresh_ui()


func enable_infiltration() -> void:
	var power_cost := get_infiltration_power_cost()
	var compute_cost := get_infiltration_compute_cost()

	var reserved: bool = global_resource_manager.reserve(power_cost, compute_cost)

	if reserved == false:
		add_intrusion_log_line(
			selected_region_state.region_id,
			"[color=#cc6666][FAILED][/color] infiltration package rejected | insufficient Power or Compute"
		)
		return

	selected_region_state.infiltration_enabled = true
	selected_region_state.scan_networks_enabled = true
	selected_region_state.run_exploit_enabled = true
	selected_region_state.infiltration_reserved_power = power_cost
	selected_region_state.infiltration_reserved_compute = compute_cost

	var map_controller = get_node("/root/Node2D/MapController")
	map_controller.set_persistent_region(selected_region_state.region_id)

	add_intrusion_log_line(
		selected_region_state.region_id,
		"[color=#88ccff][OK][/color] infiltration package online"
	)

	add_intrusion_log_line(
		selected_region_state.region_id,
		flavour_lines_scan.pick_random()
	)


func disable_infiltration() -> void:
	global_resource_manager.release(
		selected_region_state.infiltration_reserved_power,
		selected_region_state.infiltration_reserved_compute
	)

	selected_region_state.infiltration_enabled = false
	selected_region_state.scan_networks_enabled = false
	selected_region_state.run_exploit_enabled = false
	selected_region_state.infiltration_reserved_power = 0.0
	selected_region_state.infiltration_reserved_compute = 0.0

	var map_controller = get_node("/root/Node2D/MapController")
	map_controller.clear_persistent_region(selected_region_state.region_id)

	add_intrusion_log_line(
		selected_region_state.region_id,
		"[color=#999999][OK][/color] infiltration package offline"
	)


func _on_expand_button_pressed() -> void:
	expanded = !expanded
	update_details_visibility()


func update_details_visibility() -> void:
	details_container.visible = expanded

	if expanded:
		expand_button.text = "-"
	else:
		expand_button.text = "+"


func add_intrusion_log_line(region_id: String, line: String) -> void:
	if region_id == "":
		return

	if intrusion_logs_by_region.has(region_id) == false:
		intrusion_logs_by_region[region_id] = []

	var lines: Array = intrusion_logs_by_region[region_id]
	lines.append(line)

	while lines.size() > MAX_LOG_LINES:
		lines.pop_front()

	intrusion_logs_by_region[region_id] = lines

	if selected_region_state != null and selected_region_state.region_id == region_id:
		refresh_terminal_log()


func get_infiltration_power_cost() -> float:
	if selected_region_state == null:
		return 0.0

	var scan_level := float(selected_region_state.scan_networks_level)

	return get_average_city_network_weight() * scan_level


func get_infiltration_compute_cost() -> float:
	if selected_region_state == null:
		return 0.0

	var scan_level := float(selected_region_state.scan_networks_level)

	return get_average_city_security_weight() * scan_level


func get_average_city_network_weight() -> float:
	if selected_region_data == null:
		return 2.0

	if selected_region_data.cities.is_empty():
		return 2.0

	var total := 0.0

	for city in selected_region_data.cities:
		total += city.network_weight

	return total / float(selected_region_data.cities.size())


func get_average_city_security_weight() -> float:
	if selected_region_data == null:
		return 2.0

	if selected_region_data.cities.is_empty():
		return 2.0

	var total := 0.0

	for city in selected_region_data.cities:
		total += city.security_weight

	return total / float(selected_region_data.cities.size())


func get_network_foothold_title(network_visibility: int) -> String:
	if selected_region_state == null:
		return "Offline"
	if selected_region_state.scan_networks_enabled == false:
		return "Offline"
		
	var visibility_level: int 	=	clamp(network_visibility, 0,6)
	
	match visibility_level:
		
		0:
			return "Passive"
		1:
			return "Observing"
		2:
			return "Modelling"
		3:
			return "Interfacing"
		4:
			return "Embedded"
		5:
			return "Persistent"
		6:
			return "Omnipresent"
		_:
			return "Offline"


func get_notoriety_title() -> String:
	if selected_region_state == null:
		return "0"

	return str(snapped(selected_region_state.notoriety, 0.1))


func get_exploit_activity_title() -> String:
	if selected_region_state == null:
		return "Offline"

	if selected_region_state.run_exploit_enabled:
		return "Active"

	return "Offline"
