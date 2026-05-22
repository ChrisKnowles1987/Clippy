extends Control

@onready var region_name_label: Label = $"SumnmaryContainer/TitleRowContainer/IntrusionSkillPannelRegionNameLabel"
@onready var power_cost_label: Label = $"SumnmaryContainer/TitleRowContainer/PowerCostLabel"
@onready var compute_cost_label: Label = $"SumnmaryContainer/TitleRowContainer/ComputeCostLabel"
@onready var infiltration_button: Button = $"SumnmaryContainer/TitleRowContainer/Infiltration"
@onready var expand_button: Button = $"SumnmaryContainer/TitleRowContainer/ExpandCollapseButton"

@onready var region_level_label: Label = $SumnmaryContainer/LevelContainer/RegionLevelLabel
@onready var level_slot_labels := [
	$SumnmaryContainer/LevelContainer/LevelSlotsContainer/LevelSlot0,
	$SumnmaryContainer/LevelContainer/LevelSlotsContainer/LevelSlot1,
	$SumnmaryContainer/LevelContainer/LevelSlotsContainer/LevelSlot2,
	$SumnmaryContainer/LevelContainer/LevelSlotsContainer/LevelSlot3,
	$SumnmaryContainer/LevelContainer/LevelSlotsContainer/LevelSlot4,
	$SumnmaryContainer/LevelContainer/LevelSlotsContainer/LevelSlot5,
	$SumnmaryContainer/LevelContainer/LevelSlotsContainer/LevelSlot6,
	$SumnmaryContainer/LevelContainer/LevelSlotsContainer/LevelSlot7,
	$SumnmaryContainer/LevelContainer/LevelSlotsContainer/LevelSlot8,
	$SumnmaryContainer/LevelContainer/LevelSlotsContainer/LevelSlot9
]

@onready var notoriety_stars: Label = $SumnmaryContainer/TitleRowContainer3/NotorietyStars

@onready var details_container: Control = $DetailsContainer

@onready var soc_row =$SumnmaryContainer/TypedXpProgressBars/SocRow
@onready var cul_row = $SumnmaryContainer/TypedXpProgressBars/CulRow
@onready var fin_row = $SumnmaryContainer/TypedXpProgressBars/FinRow
@onready var inf_row = $SumnmaryContainer/TypedXpProgressBars/InfRow
@onready var gov_row = $SumnmaryContainer/TypedXpProgressBars/GovRow
@onready var sec_row = $SumnmaryContainer/TypedXpProgressBars/SecRow


@onready var foothold_value_label: Label = $DetailsContainer/Foothold/FootHoldValueLabel
@onready var active_nodes_value_label: Label = $DetailsContainer/ActiveNodes/ActiveNodesValueLabel
@onready var exploit_activity_value_label: RichTextLabel = $DetailsContainer/ExploitActivity/ExploitActivityValueLabel

@onready var terminal_log: RichTextLabel = $DetailsContainer/TerminalContainer/TerminalLog

@onready var global_resource_manager = get_node("/root/Node2D/GlobalResourceManager")
@onready var map_controller = get_node("/root/Node2D/MapController")

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
	refresh_progress_ui()
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


func refresh_progress_ui() -> void:
	notoriety_stars.text = IntrusionPanelFormatter.get_star_text_from_notoriety(selected_region_state.notoriety_xp)
	refresh_region_stat_rows()
	refresh_region_level_ui()

func refresh_region_stat_rows() -> void:
	if selected_region_data == null:
		return

	if selected_region_state == null:
		return

	refresh_region_stat_row(soc_row, NodeTypeDefinitions.SOCIAL)
	refresh_region_stat_row(cul_row, NodeTypeDefinitions.CULTURAL)
	refresh_region_stat_row(fin_row, NodeTypeDefinitions.FINANCIAL)
	refresh_region_stat_row(inf_row, NodeTypeDefinitions.INFRASTRUCTURE)
	refresh_region_stat_row(gov_row, NodeTypeDefinitions.GOVERNMENT)
	refresh_region_stat_row(sec_row, NodeTypeDefinitions.SECURITY)

func refresh_region_level_ui() -> void:
	if selected_region_state == null:
		return

	region_level_label.text = "Region Level " + str(selected_region_state.get_region_level()) + "/" + str(selected_region_state.get_max_region_level())

	var slots := selected_region_state.get_level_slots()

	for i in range(level_slot_labels.size()):
		var label: Label = level_slot_labels[i]

		if i < slots.size():
			label.text = "[" + NodeTypeDefinitions.get_short_label(slots[i]) + "]"
		else:
			label.text = "[ ]"


func refresh_region_stat_row(row, node_type: String) -> void:
	row.setup(
		node_type,
		selected_region_data.get_node_type_score(node_type),
		selected_region_state.get_typed_xp(node_type),
		selected_region_state.get_xp_required(node_type),
		NodeTypeDefinitions.get_colour(node_type),
		NodeTypeDefinitions.get_icon(node_type)
	)


func refresh_details_ui() -> void:
	foothold_value_label.text = IntrusionPanelFormatter.get_network_foothold_title(selected_region_state)
	active_nodes_value_label.text = str(selected_region_state.active_node_ids.size()) + "/" + str(selected_region_data.cities.size())
	exploit_activity_value_label.text = IntrusionPanelFormatter.get_rarity_chance_text(selected_region_state)


func refresh_terminal_log() -> void:
	if selected_region_state == null:
		return

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

	update_details_visibility()
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
	selected_region_state.infiltration_reserved_power = power_cost
	selected_region_state.infiltration_reserved_compute = compute_cost

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
	selected_region_state.infiltration_reserved_power = 0.0
	selected_region_state.infiltration_reserved_compute = 0.0

	map_controller.clear_persistent_region(selected_region_state.region_id)

	add_intrusion_log_line(
		selected_region_state.region_id,
		"[color=#999999][OK][/color] infiltration package offline"
	)


func _on_expand_button_pressed() -> void:
	expanded = !expanded
	update_details_visibility()


func update_details_visibility() -> void:
	details_container.visible = selected_region_state != null and selected_region_state.infiltration_enabled

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
	return IntrusionPanelCosts.get_infiltration_power_cost(selected_region_data, selected_region_state)


func get_infiltration_compute_cost() -> float:
	return IntrusionPanelCosts.get_infiltration_compute_cost(selected_region_data, selected_region_state)


func get_notoriety() -> float:
	if selected_region_state == null:
		return 0.0

	return float(snapped(selected_region_state.notoriety_xp, 0.1))
