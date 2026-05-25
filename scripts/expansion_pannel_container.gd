extends VBoxContainer

const NODE_TYPE_EMPTY := "empty"
const NODE_TYPE_POWER := "power"
const NODE_TYPE_COMPUTE := "compute"
const POWER_NODE_DISPLAY_NAME := "Power network"
const COMPUTE_NODE_DISPLAY_NAME := "Compute cluster"
const EMPTY_NODE_DISPLAY_NAME := "empty"
const BASE_RESOURCE_VALUE := 10

@onready var pannel_region_name_label: Label = $SumnmaryContainer/TitleRowContainer/PannelRegionNameLabel
@onready var expansion_points_value_label: Label = $"DetailsContainer/Expansion Points/ExpansionPointsValueLabel"

@onready var power_slot_assignment_count_value_label: Label = $DetailsContainer/ExpansionSlotAssignmentContainer/PowerSlotAssignmentCountValueLabel
@onready var increase_power_button: Button = $DetailsContainer/ExpansionSlotAssignmentContainer/IncreasePowerButton

@onready var compute_slot_assignment_count_value_label: Label = $DetailsContainer/ExpansionSlotAssignmentContainer/ComputeSlotAssignmentCountValueLabel
@onready var increase_compute_button: Button = $DetailsContainer/ExpansionSlotAssignmentContainer/IncreaseComputeButton
@onready var available_sockets_log: RichTextLabel = $DetailsContainer/TerminalContainer/AvailableSocketsLog

var region_manager = null
var global_resource_manager = null
var expansion_node_layer: Node = null
var selected_socket_id: String = ""


func _ready() -> void:
	increase_power_button.pressed.connect(_on_increase_power_pressed)
	increase_compute_button.pressed.connect(_on_increase_compute_pressed)
	available_sockets_log.bbcode_enabled = true
	available_sockets_log.meta_clicked.connect(_on_available_socket_meta_clicked)
	show_empty()


func setup(region_manager_ref, expansion_node_layer_ref: Node, global_resource_manager_ref = null) -> void:
	region_manager = region_manager_ref
	expansion_node_layer = expansion_node_layer_ref
	global_resource_manager = global_resource_manager_ref
	connect_expansion_sockets()
	show_empty()
	refresh()


func connect_expansion_sockets() -> void:
	if expansion_node_layer == null:
		return

	for child in expansion_node_layer.get_children():
		if child.has_signal("expansion_socket_clicked") == false:
			continue

		if child.expansion_socket_clicked.is_connected(_on_expansion_socket_clicked) == false:
			child.expansion_socket_clicked.connect(_on_expansion_socket_clicked)


func show_empty() -> void:
	selected_socket_id = ""
	pannel_region_name_label.text = "Expansion Queue"
	expansion_points_value_label.text = "0"
	power_slot_assignment_count_value_label.text = "0"
	compute_slot_assignment_count_value_label.text = "0"
	available_sockets_log.text = "Available Sockets >"
	increase_power_button.disabled = false
	increase_compute_button.disabled = false


func show_region(region_id: String) -> void:
	select_first_available_socket_for_region(region_id)
	refresh()


func refresh() -> void:
	var sockets := get_available_expansion_sockets_sorted()
	validate_selected_socket(sockets)

	var selected_socket = get_selected_socket()

	if selected_socket == null:
		pannel_region_name_label.text = "Expansion Queue | Selected: none"
	else:
		pannel_region_name_label.text = "Expansion Queue | Selected: %s / %s" % [
			get_region_display_name(selected_socket.region_id),
			selected_socket.display_name
		]

	expansion_points_value_label.text = str(get_total_expansion_points())
	power_slot_assignment_count_value_label.text = str(get_total_resource_value_for_type(NODE_TYPE_POWER))
	compute_slot_assignment_count_value_label.text = str(get_total_resource_value_for_type(NODE_TYPE_COMPUTE))
	available_sockets_log.text = build_available_sockets_text(sockets)
	increase_power_button.disabled = false
	increase_compute_button.disabled = false


func _on_expansion_socket_clicked(socket) -> void:
	if socket == null:
		return

	selected_socket_id = socket.id
	refresh()


func _on_available_socket_meta_clicked(meta) -> void:
	selected_socket_id = str(meta)
	refresh()


func _on_increase_power_pressed() -> void:
	assign_expansion_point(NODE_TYPE_POWER)


func _on_increase_compute_pressed() -> void:
	assign_expansion_point(NODE_TYPE_COMPUTE)


func assign_expansion_point(target_node_type: String) -> bool:
	var socket = get_selected_socket()
	if socket == null:
		refresh()
		return false

	if socket.node_type != NODE_TYPE_EMPTY and socket.node_type != target_node_type:
		refresh()
		return false

	if socket.points_invested >= socket.max_points:
		refresh()
		return false

	var region_state: RegionState = get_socket_region_state(socket)
	if region_state == null:
		refresh()
		return false

	if region_state.expansion_points <= 0:
		refresh()
		return false

	var previous_value := get_resource_value_for_assignment_count(socket.points_invested)

	if socket.node_type == NODE_TYPE_EMPTY:
		socket.node_type = target_node_type
		socket.points_invested = 0

	socket.points_invested = min(socket.points_invested + 1, socket.max_points)

	var new_value := get_resource_value_for_assignment_count(socket.points_invested)
	var added_value := float(max(0, new_value - previous_value))
	apply_global_resource_gain(target_node_type, added_value)

	region_state.expansion_points -= 1
	refresh_socket_visual(socket)
	refresh()
	return true


func apply_global_resource_gain(target_node_type: String, amount: float) -> void:
	if global_resource_manager == null:
		return

	if amount <= 0.0:
		return

	match target_node_type:
		NODE_TYPE_POWER:
			global_resource_manager.add_power(amount)
		NODE_TYPE_COMPUTE:
			global_resource_manager.add_compute(amount)


func refresh_socket_visual(socket) -> void:
	if socket == null:
		return

	if socket.has_method("refresh_visual"):
		socket.refresh_visual()


func validate_selected_socket(sockets: Array) -> void:
	if selected_socket_id != "":
		for socket in sockets:
			if socket.id == selected_socket_id:
				return

	if sockets.is_empty():
		selected_socket_id = ""
		return

	selected_socket_id = sockets[0].id


func select_first_available_socket_for_region(region_id: String) -> void:
	var sockets := get_available_expansion_sockets_sorted()

	for socket in sockets:
		if socket.region_id == region_id:
			selected_socket_id = socket.id
			return

	selected_socket_id = ""


func get_selected_socket():
	if selected_socket_id == "":
		return null

	if expansion_node_layer == null:
		return null

	for child in expansion_node_layer.get_children():
		if child.has_method("update_line") == false:
			continue

		if child.id == selected_socket_id:
			return child

	return null


func get_available_expansion_sockets_sorted() -> Array:
	var sockets := get_all_available_expansion_sockets()
	sockets.sort_custom(_sort_socket_for_global_queue)
	return sockets


func get_all_available_expansion_sockets() -> Array:
	var sockets := []

	if expansion_node_layer == null:
		return sockets

	for child in expansion_node_layer.get_children():
		if child.has_method("update_line") == false:
			continue

		var region_state: RegionState = get_socket_region_state(child)
		if region_state == null:
			continue

		if region_state.expansion_points <= 0:
			continue

		if child.points_invested >= child.max_points:
			continue

		sockets.append(child)

	return sockets


func build_available_sockets_text(sockets: Array) -> String:
	var text := "Available Sockets >\n"

	for socket in sockets:
		var selected_prefix := "  "

		if socket.id == selected_socket_id:
			selected_prefix = "> "

		text += "[url=%s]%s%s | %s | %s | %s[/url]\n" % [
			socket.id,
			selected_prefix,
			get_region_display_name(socket.region_id),
			socket.display_name,
			get_socket_type_display_name(socket.node_type),
			get_socket_assignment_display_text(socket)
		]

	return text.strip_edges()


func get_socket_type_display_name(node_type: String) -> String:
	match node_type:
		NODE_TYPE_POWER:
			return POWER_NODE_DISPLAY_NAME
		NODE_TYPE_COMPUTE:
			return COMPUTE_NODE_DISPLAY_NAME
		_:
			return EMPTY_NODE_DISPLAY_NAME


func get_socket_assignment_display_text(socket) -> String:
	if socket.node_type == NODE_TYPE_EMPTY:
		return ""

	return "%d/%d" % [socket.points_invested, socket.max_points]


func get_total_resource_value_for_type(node_type: String) -> int:
	var total := 0

	if expansion_node_layer == null:
		return total

	for child in expansion_node_layer.get_children():
		if child.has_method("update_line") == false:
			continue

		if child.node_type != node_type:
			continue

		total += get_resource_value_for_assignment_count(child.points_invested)

	return total


func get_resource_value_for_assignment_count(points: int) -> int:
	if points <= 0:
		return 0

	return BASE_RESOURCE_VALUE * int(pow(2.0, float(points - 1)))


func get_total_expansion_points() -> int:
	var total := 0

	if region_manager == null:
		return total

	for region_id in region_manager.region_states.keys():
		var region_state: RegionState = region_manager.get_region_state(region_id)

		if region_state == null:
			continue

		total += region_state.expansion_points

	return total


func get_socket_region_state(socket) -> RegionState:
	if socket == null:
		return null

	if region_manager == null:
		return null

	return region_manager.get_region_state(socket.region_id)


func get_region_display_name(region_id: String) -> String:
	if region_manager != null and region_manager.regions.has(region_id):
		return region_manager.regions[region_id].display_name

	return region_id.replace("_", " ").capitalize()


func get_city_population_weight(socket) -> float:
	if socket == null:
		return 0.0

	if region_manager == null:
		return 0.0

	if region_manager.regions.has(socket.region_id) == false:
		return 0.0

	var region_data: RegionData = region_manager.regions[socket.region_id]

	for city in region_data.cities:
		if city.id == socket.city_id:
			return city.population_weight

	return 0.0


func _sort_socket_for_global_queue(a, b) -> bool:
	var region_a := get_region_display_name(a.region_id)
	var region_b := get_region_display_name(b.region_id)

	if region_a == region_b:
		return get_city_population_weight(a) < get_city_population_weight(b)

	return region_a < region_b
