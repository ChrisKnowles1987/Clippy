extends VBoxContainer

const NODE_TYPE_EMPTY := "empty"
const NODE_TYPE_POWER := "power"
const NODE_TYPE_COMPUTE := "compute"
const POWER_NODE_DISPLAY_NAME := "Power network"
const COMPUTE_NODE_DISPLAY_NAME := "Compute cluster"
const EMPTY_NODE_DISPLAY_NAME := "empty"
const BASE_RESOURCE_VALUE := 5

@onready var pannel_region_name_label: Label = $SumnmaryContainer/TitleRowContainer/PannelRegionNameLabel
@onready var expansion_points_value_label: Label = $"DetailsContainer/Expansion Points/ExpansionPointsValueLabel"

@onready var power_slot_assignment_count_value_label: Label = $DetailsContainer/ExpansionSlotAssignmentContainer/PowerSlotAssignmentCountValueLabel
@onready var increase_power_button: Button = $DetailsContainer/ExpansionSlotAssignmentContainer/IncreasePowerButton

@onready var compute_slot_assignment_count_value_label: Label = $DetailsContainer/ExpansionSlotAssignmentContainer/ComputeSlotAssignmentCountValueLabel
@onready var increase_compute_button: Button = $DetailsContainer/ExpansionSlotAssignmentContainer/IncreaseComputeButton
@onready var available_sockets_log: RichTextLabel = $DetailsContainer/TerminalContainer/AvailableSocketsLog

var region_manager = null
var expansion_node_layer: Node = null
var selected_region_id: String = ""


func _ready() -> void:
	increase_power_button.pressed.connect(_on_increase_power_pressed)
	increase_compute_button.pressed.connect(_on_increase_compute_pressed)
	show_empty()


func setup(region_manager_ref, expansion_node_layer_ref: Node) -> void:
	region_manager = region_manager_ref
	expansion_node_layer = expansion_node_layer_ref
	connect_expansion_sockets()
	show_empty()


func connect_expansion_sockets() -> void:
	if expansion_node_layer == null:
		return

	for child in expansion_node_layer.get_children():
		if child.has_signal("expansion_socket_clicked") == false:
			continue

		if child.expansion_socket_clicked.is_connected(_on_expansion_socket_clicked) == false:
			child.expansion_socket_clicked.connect(_on_expansion_socket_clicked)


func show_empty() -> void:
	selected_region_id = ""
	pannel_region_name_label.text = "No expansion region selected"
	expansion_points_value_label.text = "0"
	power_slot_assignment_count_value_label.text = "0"
	compute_slot_assignment_count_value_label.text = "0"
	available_sockets_log.text = "Available Sockets >"
	increase_power_button.disabled = false
	increase_compute_button.disabled = false


func show_region(region_id: String) -> void:
	selected_region_id = region_id
	refresh()


func refresh() -> void:
	if selected_region_id == "":
		show_empty()
		return

	var region_state: RegionState = get_selected_region_state()
	if region_state == null:
		show_empty()
		return

	pannel_region_name_label.text = get_region_display_name(selected_region_id)
	expansion_points_value_label.text = str(region_state.expansion_points)
	power_slot_assignment_count_value_label.text = str(get_total_resource_value_for_type(NODE_TYPE_POWER))
	compute_slot_assignment_count_value_label.text = str(get_total_resource_value_for_type(NODE_TYPE_COMPUTE))	
	available_sockets_log.text = build_available_sockets_text()
	increase_power_button.disabled = false
	increase_compute_button.disabled = false


func _on_expansion_socket_clicked(socket) -> void:
	if socket == null:
		return

	show_region(socket.region_id)


func _on_increase_power_pressed() -> void:
	assign_expansion_point(NODE_TYPE_POWER)


func _on_increase_compute_pressed() -> void:
	assign_expansion_point(NODE_TYPE_COMPUTE)


func assign_expansion_point(target_node_type: String) -> bool:
	var region_state: RegionState = get_selected_region_state()
	if region_state == null:
		return false

	if region_state.expansion_points <= 0:
		refresh()
		return false

	var socket = get_next_assignment_socket(target_node_type)
	if socket == null:
		refresh()
		return false

	if socket.node_type == NODE_TYPE_EMPTY:
		socket.node_type = target_node_type
		socket.points_invested = 0

	socket.points_invested = min(socket.points_invested + 1, socket.max_points)
	region_state.expansion_points -= 1
	refresh()
	return true


func get_next_assignment_socket(target_node_type: String):
	var sockets := get_selected_region_sockets_sorted_by_population()

	for socket in sockets:
		if socket.node_type == target_node_type and socket.points_invested < socket.max_points:
			return socket

	for socket in sockets:
		if socket.node_type == NODE_TYPE_EMPTY:
			return socket

	return null


func get_selected_region_sockets_sorted_by_population() -> Array:
	var sockets := get_selected_region_sockets()
	sockets.sort_custom(_sort_socket_by_population_ascending)
	return sockets


func get_selected_region_sockets() -> Array:
	var sockets := []

	if expansion_node_layer == null:
		return sockets

	for child in expansion_node_layer.get_children():
		if child.has_method("update_line") == false:
			continue

		if child.region_id == selected_region_id:
			sockets.append(child)

	return sockets


func build_available_sockets_text() -> String:
	var text := "Available Sockets >\n"
	var sockets := get_selected_region_sockets_sorted_by_population()

	for socket in sockets:
		text += "%s | %s | %s\n" % [
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

	for socket in get_selected_region_sockets():
		if socket.node_type != node_type:
			continue

		total += get_resource_value_for_assignment_count(socket.points_invested)

	return total


func get_resource_value_for_assignment_count(points: int) -> int:
	if points <= 0:
		return 0

	return BASE_RESOURCE_VALUE * int(pow(2.0, float(points - 1)))


func get_selected_region_state() -> RegionState:
	if region_manager == null:
		return null

	return region_manager.get_region_state(selected_region_id)


func get_region_display_name(region_id: String) -> String:
	if region_manager != null and region_manager.regions.has(region_id):
		return region_manager.regions[region_id].display_name

	return region_id.replace("_", " ").capitalize()


func get_city_population_weight(city_id: String) -> float:
	if region_manager == null:
		return 0.0

	if region_manager.regions.has(selected_region_id) == false:
		return 0.0

	var region_data: RegionData = region_manager.regions[selected_region_id]

	for city in region_data.cities:
		if city.id == city_id:
			return city.population_weight

	return 0.0


func _sort_socket_by_population_ascending(a, b) -> bool:
	return get_city_population_weight(a.city_id) < get_city_population_weight(b.city_id)
