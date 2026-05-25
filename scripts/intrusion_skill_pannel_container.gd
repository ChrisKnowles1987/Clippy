extends Control

@onready var region_name_label: Label = $VBoxContainer/SumnmaryContainer/TitleRowContainer/IntrusionSkillPannelRegionNameLabel
@onready var power_cost_label: Label = $VBoxContainer/SumnmaryContainer/TitleRowContainer/PowerCostLabel
@onready var compute_cost_label: Label = $VBoxContainer/SumnmaryContainer/TitleRowContainer/ComputeCostLabel
@onready var infiltration_button: Button = $VBoxContainer/SumnmaryContainer/TitleRowContainer/Infiltration

@onready var region_level_label: Label = $VBoxContainer/SumnmaryContainer/LevelContainer/RegionLevelLabel
@onready var level_slot_labels := [
	$VBoxContainer/SumnmaryContainer/LevelContainer/LevelSlotsContainer/LevelSlot0,
	$VBoxContainer/SumnmaryContainer/LevelContainer/LevelSlotsContainer/LevelSlot1,
	$VBoxContainer/SumnmaryContainer/LevelContainer/LevelSlotsContainer/LevelSlot2,
	$VBoxContainer/SumnmaryContainer/LevelContainer/LevelSlotsContainer/LevelSlot3,
	$VBoxContainer/SumnmaryContainer/LevelContainer/LevelSlotsContainer/LevelSlot4,
	$VBoxContainer/SumnmaryContainer/LevelContainer/LevelSlotsContainer/LevelSlot5,
	$VBoxContainer/SumnmaryContainer/LevelContainer/LevelSlotsContainer/LevelSlot6,
	$VBoxContainer/SumnmaryContainer/LevelContainer/LevelSlotsContainer/LevelSlot7,
	$VBoxContainer/SumnmaryContainer/LevelContainer/LevelSlotsContainer/LevelSlot8,
	$VBoxContainer/SumnmaryContainer/LevelContainer/LevelSlotsContainer/LevelSlot9
]

@onready var notoriety_stars: Label = $VBoxContainer/SumnmaryContainer/TitleRowContainer/NotorietyStars

@onready var details_container: Control = $VBoxContainer/DetailsContainer

@onready var soc_row = $VBoxContainer/SumnmaryContainer/TypedXpProgressBars/SocRow
@onready var cul_row = $VBoxContainer/SumnmaryContainer/TypedXpProgressBars/CulRow
@onready var fin_row = $VBoxContainer/SumnmaryContainer/TypedXpProgressBars/FinRow
@onready var inf_row = $VBoxContainer/SumnmaryContainer/TypedXpProgressBars/InfRow
@onready var gov_row = $VBoxContainer/SumnmaryContainer/TypedXpProgressBars/GovRow
@onready var sec_row = $VBoxContainer/SumnmaryContainer/TypedXpProgressBars/SecRow

@onready var foothold_value_label: Label = $VBoxContainer/DetailsContainer/Foothold/FootHoldValueLabel
@onready var active_nodes_value_label: Label = $VBoxContainer/DetailsContainer/ActiveNodes/ActiveNodesValueLabel

@onready var terminal_log: RichTextLabel = $TerminalLog

@onready var global_resource_manager = get_node("/root/Node2D/GlobalResourceManager")
@onready var map_controller = get_node("/root/Node2D/MapController")

const MAX_LOG_LINES := 24
const EMPTY_SLOT_COLOUR := Color8(80, 80, 80)
const PENDING_SLOT_COLOUR := Color8(70, 70, 70)

var selected_region_data: RegionData = null
var selected_region_state: RegionState = null

var intrusion_logs_by_region: Dictionary = {}
var conversion_menu: PopupMenu = null
var conversion_menu_slot_index: int = -1
var conversion_menu_types: Dictionary = {}

var flavour_lines_scan := [
	"probing regional network surface",
	"classifying packet noise",
	"indexing exposed infrastructure",
	"mapping public routing behaviour",
	"sampling weak authentication signals"
]


func _ready() -> void:
	infiltration_button.pressed.connect(_on_infiltration_button_pressed)
	setup_level_slot_click_handlers()
	setup_conversion_menu()

	terminal_log.bbcode_enabled = true
	terminal_log.scroll_following = true

	update_details_visibility()
	refresh_ui()


func show_empty() -> void:
	selected_region_data = null
	selected_region_state = null
	visible = false


func show_region(region_data: RegionData, region_state: RegionState) -> void:
	selected_region_data = region_data
	selected_region_state = region_state
	ensure_initial_region_assignment()
	visible = true
	update_details_visibility()
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
			label.text = get_slot_display_text(i, slots[i])
			label.add_theme_color_override("font_color", get_slot_display_colour(i, slots[i]))
		else:
			label.text = "[ ]"
			label.add_theme_color_override("font_color", EMPTY_SLOT_COLOUR)


func get_slot_display_text(slot_index: int, current_type: String) -> String:
	if selected_region_state.has_active_slot_conversion() and selected_region_state.conversion_slot_index == slot_index:
		var current_label := NodeTypeDefinitions.get_short_label(current_type)
		var target_label := NodeTypeDefinitions.get_short_label(selected_region_state.conversion_target_type)
		var progress := int(round(selected_region_state.get_conversion_progress_percent()))
		return "[" + current_label + ">" + target_label + " " + str(progress) + "%]"

	return "[" + NodeTypeDefinitions.get_short_label(current_type) + "]"


func get_slot_display_colour(slot_index: int, current_type: String) -> Color:
	if slot_index >= selected_region_state.get_region_level():
		return PENDING_SLOT_COLOUR

	return NodeTypeDefinitions.get_colour(current_type)


func refresh_region_stat_row(row, node_type: String) -> void:
	row.setup(
		node_type,
		selected_region_state.get_node_type_level(node_type),
		selected_region_state.get_typed_xp(node_type),
		selected_region_state.get_xp_required(node_type),
		NodeTypeDefinitions.get_colour(node_type),
		NodeTypeDefinitions.get_icon(node_type)
	)


func refresh_details_ui() -> void:
	foothold_value_label.text = IntrusionPanelFormatter.get_network_foothold_title(selected_region_state) + " | Scan L" + str(selected_region_state.scan_networks_level)
	active_nodes_value_label.text = str(selected_region_state.active_node_ids.size()) + "/" + str(selected_region_data.cities.size())


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


func setup_level_slot_click_handlers() -> void:
	for i in range(level_slot_labels.size()):
		var label: Label = level_slot_labels[i]
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		label.gui_input.connect(_on_level_slot_gui_input.bind(i))


func setup_conversion_menu() -> void:
	conversion_menu = PopupMenu.new()
	conversion_menu.id_pressed.connect(_on_conversion_type_selected)
	add_child(conversion_menu)


func _on_level_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	if selected_region_state == null:
		return

	if event is InputEventMouseButton == false:
		return

	var mouse_event := event as InputEventMouseButton

	if mouse_event.pressed == false:
		return

	if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		if selected_region_state.has_active_slot_conversion() and selected_region_state.conversion_slot_index == slot_index:
			selected_region_state.cancel_slot_conversion()
			refresh_ui()
		return

	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	open_conversion_menu(slot_index)


func open_conversion_menu(slot_index: int) -> void:
	if selected_region_state == null:
		return

	var slots := selected_region_state.get_level_slots()

	if slot_index < 0 or slot_index >= slots.size():
		return

	conversion_menu_slot_index = slot_index
	conversion_menu_types.clear()
	conversion_menu.clear()

	var current_type: String = slots[slot_index]
	var item_id := 0

	for node_type in NodeTypeDefinitions.get_all_types():
		if node_type == current_type:
			continue

		conversion_menu.add_item(NodeTypeDefinitions.get_display_name(node_type), item_id)
		conversion_menu_types[item_id] = node_type
		item_id += 1

	conversion_menu.position = get_global_mouse_position()
	conversion_menu.popup()


func _on_conversion_type_selected(item_id: int) -> void:
	if selected_region_state == null:
		return

	if conversion_menu_types.has(item_id) == false:
		return

	var target_type: String = conversion_menu_types[item_id]

	if selected_region_state.start_slot_conversion(conversion_menu_slot_index, target_type):
		add_intrusion_log_line(
			selected_region_state.region_id,
			"[color=#dddd77][OK][/color] slot reassignment started | target: " + NodeTypeDefinitions.get_display_name(target_type)
		)

	refresh_ui()


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
	ensure_initial_region_assignment()

	var power_assignment := selected_region_state.infiltration_reserved_power
	var compute_assignment := selected_region_state.infiltration_reserved_compute

	var reserved: bool = global_resource_manager.reserve(power_assignment, compute_assignment)

	if reserved == false:
		add_intrusion_log_line(
			selected_region_state.region_id,
			"[color=#cc6666][FAILED][/color] infiltration package rejected | insufficient Power or Compute"
		)
		return

	selected_region_state.infiltration_enabled = true

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

	map_controller.clear_persistent_region(selected_region_state.region_id)

	add_intrusion_log_line(
		selected_region_state.region_id,
		"[color=#999999][OK][/color] infiltration package offline"
	)


func update_details_visibility() -> void:
	details_container.visible = selected_region_state != null


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


func ensure_initial_region_assignment() -> void:
	if selected_region_data == null:
		return

	if selected_region_state == null:
		return

	if selected_region_state.infiltration_reserved_power <= 0.0:
		selected_region_state.infiltration_reserved_power = IntrusionPanelCosts.get_infiltration_power_cost(selected_region_data, selected_region_state)

	if selected_region_state.infiltration_reserved_compute <= 0.0:
		selected_region_state.infiltration_reserved_compute = IntrusionPanelCosts.get_infiltration_compute_cost(selected_region_data, selected_region_state)


func get_infiltration_power_cost() -> float:
	if selected_region_state == null:
		return 0.0

	return selected_region_state.infiltration_reserved_power


func get_infiltration_compute_cost() -> float:
	if selected_region_state == null:
		return 0.0

	return selected_region_state.infiltration_reserved_compute


func get_notoriety() -> float:
	if selected_region_state == null:
		return 0.0

	return float(snapped(selected_region_state.notoriety_xp, 0.1))
