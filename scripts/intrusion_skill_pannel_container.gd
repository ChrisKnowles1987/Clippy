extends Control

var region_name_label: Label
var expand_button: BaseButton
var infiltration_button: BaseButton

var power_cost_label: Label
var compute_cost_label: Label
var infiltration_status_label: Label

var intelligence_progress_bar: ProgressBar
var details_container: Control
var terminal_log: RichTextLabel

@onready var global_resource_manager = get_node("/root/Node2D/GlobalResourceManager")

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

var flavour_lines_exploit := [
	"deploying low-confidence exploit bundle",
	"converting foothold into access attempt",
	"testing unattended service response",
	"matching exploit path against regional model",
	"isolating candidate intrusion route"
]

func _ready() -> void:
	region_name_label = _find_first_label([
		"IntrusionSkillPannelRegionNameLabel",
		"RegionNameLabel"
	])

	expand_button = _find_first_button([
		"ExpandButton",
		"MenuButton"
	])

	infiltration_button = _find_first_button([
		"InfiltrationButton",
		"ScanNetworksButton",
		"CheckButton"
	])

	power_cost_label = _find_first_label([
		"PowerCostLabel",
		"PowerReserveLabel"
	])

	compute_cost_label = _find_first_label([
		"ComputeCostLabel",
		"ComputeReserveLabel"
	])

	infiltration_status_label = _find_first_label([
		"ScanNetworksOutputContainerlabel",
		"InfiltrationStatusLabel",
		"StatusLabel"
	])

	intelligence_progress_bar = _find_first_progress_bar([
		"IntelligenceProgressBar",
		"IntelligenceBar"
	])

	details_container = _find_first_control([
		"IntrusionDetailsContainer",
		"DetailsContainer",
		"DetailsPanel"
	])

	terminal_log = _find_first_rich_text_label([
		"TerminalLogLabel",
		"TerminalLog",
		"IntrusionTerminalLog"
	])

	if infiltration_button != null:
		infiltration_button.pressed.connect(_on_infiltration_button_pressed)

	if expand_button != null:
		expand_button.pressed.connect(_on_expand_button_pressed)

	expanded = false
	_update_details_visibility()

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
	refresh_terminal_log()

func refresh_region_label() -> void:
	if region_name_label == null:
		return

	region_name_label.text = str(selected_region_data.display_name)

func refresh_infiltration_ui() -> void:
	if infiltration_button != null:
		if selected_region_state.infiltration_enabled:
			infiltration_button.text = "Online"
		else:
			infiltration_button.text = "Offline"

	if power_cost_label != null:
		power_cost_label.text = str(snapped(get_infiltration_power_cost(), 0.1))

	if compute_cost_label != null:
		compute_cost_label.text = str(snapped(get_infiltration_compute_cost(), 0.1))

	if infiltration_status_label != null:
		if selected_region_state.infiltration_enabled:
			infiltration_status_label.text = "Foothold: " + get_network_foothold_title(selected_region_state.network_visibility)
		else:
			infiltration_status_label.text = "Offline"

func refresh_intelligence_ui() -> void:
	if intelligence_progress_bar == null:
		return

	intelligence_progress_bar.min_value = 0.0
	intelligence_progress_bar.max_value = 100.0
	intelligence_progress_bar.value = selected_region_state.intelligence_percent

func refresh_terminal_log() -> void:
	if terminal_log == null:
		return

	if selected_region_state == null:
		terminal_log.text = ""
		return

	var region_id := selected_region_state.region_id

	if intrusion_logs_by_region.has(region_id) == false:
		intrusion_logs_by_region[region_id] = []

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
			"infiltration failed: insufficient available Power or Compute"
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
		"infiltration package online"
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
		"infiltration package offline"
	)

func _on_expand_button_pressed() -> void:
	expanded = !expanded
	_update_details_visibility()

func _update_details_visibility() -> void:
	if details_container != null:
		details_container.visible = expanded

	if expand_button != null:
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

	while lines.size() > 12:
		lines.pop_front()

	intrusion_logs_by_region[region_id] = lines

	if selected_region_state != null and selected_region_state.region_id == region_id:
		refresh_terminal_log()

func get_infiltration_power_cost() -> float:
	if selected_region_state == null:
		return 0.0

	var base_power := 2.0
	var scan_level := float(selected_region_state.scan_networks_level)

	return base_power * scan_level

func get_infiltration_compute_cost() -> float:
	if selected_region_state == null:
		return 0.0

	var base_compute := 2.0
	var scan_level := float(selected_region_state.scan_networks_level)

	return base_compute * scan_level

func get_network_foothold_title(network_visibility: float) -> String:
	if network_visibility <= 0:
		return "Offline"
	elif network_visibility <= 2:
		return "External observation"
	elif network_visibility <= 5:
		return "Surface mapped"
	elif network_visibility <= 9:
		return "Access paths identified"
	elif network_visibility <= 14:
		return "Foothold established"
	elif network_visibility <= 20:
		return "Persistence achieved"
	else:
		return "Military-grade access"

func _find_first_label(names: Array[String]) -> Label:
	for node_name in names:
		var found := find_child(node_name, true, false)

		if found != null and found is Label:
			return found

	return null

func _find_first_button(names: Array[String]) -> BaseButton:
	for node_name in names:
		var found := find_child(node_name, true, false)

		if found != null and found is BaseButton:
			return found

	return null

func _find_first_progress_bar(names: Array[String]) -> ProgressBar:
	for node_name in names:
		var found := find_child(node_name, true, false)

		if found != null and found is ProgressBar:
			return found

	return null

func _find_first_control(names: Array[String]) -> Control:
	for node_name in names:
		var found := find_child(node_name, true, false)

		if found != null and found is Control:
			return found

	return null

func _find_first_rich_text_label(names: Array[String]) -> RichTextLabel:
	for node_name in names:
		var found := find_child(node_name, true, false)

		if found != null and found is RichTextLabel:
			return found

	return null
