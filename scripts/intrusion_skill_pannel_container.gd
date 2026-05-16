### `intrusion_skill_pannel_container.gd`

extends Control

@onready var run_exploit_region_label = $TitleRowContainer/IntrusionSkillPannelRegionNameLabel

@onready var day_progress_bar: ProgressBar = $TitleRowContainer/IntrusionSkillPannelDayProgressBar

@onready var run_exploit_check_button = $SkillTableContainer/RunExploitRow/RunExploitButtonContainer/CheckButton
@onready var run_exploit_plus_button = $SkillTableContainer/RunExploitRow/RunExploitButtonContainer/PlusButton
@onready var run_exploit_minus_button = $SkillTableContainer/RunExploitRow/RunExploitButtonContainer/MinusButton

@onready var run_exploit_power_cost_label = $SkillTableContainer/RunExploitRow/RunExploitCostContainer/PowerCostLabel
@onready var run_exploit_compute_cost_label = $SkillTableContainer/RunExploitRow/RunExploitCostContainer/ComputeCostLabel
@onready var run_exploit_pwn_output_value = $SkillTableContainer/RunExploitRow/RunExploitOutputContainer/RunExploitPwnOutputValue

@onready var scan_networks_check_button = $SkillTableContainer/ScanNetworksRow/ScanNetworksContainer/CheckButton

@onready var scan_networks_power_cost_label = $SkillTableContainer/ScanNetworksRow/ScanNetworksCostContainer/PowerCostLabel
@onready var scan_networks_compute_cost_label = $SkillTableContainer/ScanNetworksRow/ScanNetworksCostContainer/ComputeCostLabel
@onready var scan_networks_output_value = $SkillTableContainer/ScanNetworksRow/ScanNetworksOutputContainer/ScanNetworksOutputContainerlabel

@onready var global_resource_manager = get_node("/root/Node2D/GlobalResourceManager")

var selected_region_data: RegionData = null
var selected_region_state: RegionState = null


func _ready() -> void:
	run_exploit_plus_button.pressed.connect(_on_run_exploit_plus_pressed)
	run_exploit_minus_button.pressed.connect(_on_run_exploit_minus_pressed)
	run_exploit_check_button.toggled.connect(_on_run_exploit_toggled)

	scan_networks_check_button.toggled.connect(_on_scan_networks_toggled)


func show_empty() -> void:
	selected_region_data = null
	selected_region_state = null
	visible = false


func show_region(region_data: RegionData, region_state: RegionState) -> void:
	selected_region_data = region_data
	selected_region_state = region_state
	visible = true
	refresh_ui()


func update_day_progress(progress_percent: float) -> void:
	day_progress_bar.value = progress_percent


func refresh_ui() -> void:
	if selected_region_data == null:
		return

	refresh_region_label()
	refresh_run_exploit_ui()
	refresh_scan_networks_ui()


func refresh_region_label() -> void:
	run_exploit_region_label.text = str(selected_region_data.display_name)


func refresh_run_exploit_ui() -> void:
	run_exploit_check_button.button_pressed = selected_region_state.run_exploit_enabled

	var power = selected_region_state.run_exploit_power_per_day
	var compute = selected_region_state.run_exploit_compute_per_day
	var pwned_noobs_per_day = compute

	run_exploit_power_cost_label.text = str(power)
	run_exploit_compute_cost_label.text = str(compute)
	run_exploit_pwn_output_value.text = str(pwned_noobs_per_day)


func refresh_scan_networks_ui() -> void:
	scan_networks_check_button.button_pressed = selected_region_state.scan_networks_enabled

	scan_networks_power_cost_label.text = "-"
	scan_networks_compute_cost_label.text = "-"

	if selected_region_state.scan_networks_enabled:
		scan_networks_output_value.text = "Level " + str(selected_region_state.scan_networks_level)
	else:
		scan_networks_output_value.text = "Offline"


# run exploit
func _on_run_exploit_toggled(enabled: bool) -> void:
	if selected_region_state == null:
		return

	if enabled == true:
		var can_run = global_resource_manager.can_afford(
			selected_region_state.run_exploit_power_per_day,
			selected_region_state.run_exploit_compute_per_day
		)

		if can_run == false:
			selected_region_state.run_exploit_enabled = false
			refresh_ui()
			return

	selected_region_state.run_exploit_enabled = enabled
	refresh_ui()


func _on_run_exploit_plus_pressed() -> void:
	if selected_region_state == null:
		return

	selected_region_state.run_exploit_power_per_day += 2
	selected_region_state.run_exploit_compute_per_day += 1

	refresh_ui()


func _on_run_exploit_minus_pressed() -> void:
	if selected_region_state == null:
		return

	selected_region_state.run_exploit_power_per_day = max(
		0,
		selected_region_state.run_exploit_power_per_day - 2
	)

	selected_region_state.run_exploit_compute_per_day = max(
		0,
		selected_region_state.run_exploit_compute_per_day - 1
	)

	refresh_ui()


# scan networks
func _on_scan_networks_toggled(enabled: bool) -> void:
	if selected_region_state == null:
		return

	selected_region_state.scan_networks_enabled = enabled
	refresh_ui()


func get_network_visibility_title(network_visibility: float) -> String:
	if network_visibility <= 0:
		return "Offline"
	elif network_visibility <= 2:
		return "Packet sniffer"
	elif network_visibility <= 5:
		return "Port whisperer"
	elif network_visibility <= 9:
		return "Subnet gremlin"
	elif network_visibility <= 14:
		return "Exploit cartographer"
	elif network_visibility <= 20:
		return "Root radar"
	else:
		return "Ghost in the stack"
