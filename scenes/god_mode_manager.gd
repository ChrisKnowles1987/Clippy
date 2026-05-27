extends Node
class_name GodModeManager

@export var enabled: bool = false
@export var resource_amount: float = 100.0

var main_controller = null
var region_manager = null
var global_resource_manager = null


func setup(
	main_controller_ref: Node,
	region_manager_ref: Node,
	global_resource_manager_ref: Node
) -> void:
	main_controller = main_controller_ref
	region_manager = region_manager_ref
	global_resource_manager = global_resource_manager_ref


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey == false:
		return

	if event.pressed == false:
		return

	if event.echo:
		return

	if event.keycode == KEY_F1:
		enabled = !enabled
		print("God mode: ", enabled)
		return

	if enabled == false:
		return

	match event.keycode:
		KEY_1:
			add_power()
		KEY_2:
			add_compute()
		KEY_3:
			add_coin()
		KEY_4:
			add_slot(NodeTypeDefinitions.SOCIAL)
		KEY_5:
			add_slot(NodeTypeDefinitions.CULTURAL)
		KEY_6:
			add_slot(NodeTypeDefinitions.FINANCIAL)
		KEY_7:
			add_slot(NodeTypeDefinitions.INFRASTRUCTURE)
		KEY_8:
			add_slot(NodeTypeDefinitions.GOVERNMENT)
		KEY_9:
			add_slot(NodeTypeDefinitions.SECURITY)


func add_power() -> void:
	if global_resource_manager == null:
		return

	global_resource_manager.add_power(resource_amount)
	print("God mode added Power: ", resource_amount)
	refresh_ui()


func add_compute() -> void:
	if global_resource_manager == null:
		return

	global_resource_manager.add_compute(resource_amount)
	print("God mode added Compute: ", resource_amount)
	refresh_ui()


func add_coin() -> void:
	if global_resource_manager == null:
		return

	global_resource_manager.add_coin(resource_amount)
	print("God mode added Coin: ", resource_amount)
	refresh_ui()


func add_slot(slot_type: String) -> void:
	var region_state := get_selected_region_state()

	if region_state == null:
		print("God mode: no selected region")
		return

	if region_state.level_slots.size() >= region_state.MAX_REGION_LEVEL:
		print("God mode: selected region slots full")
		return

	region_state.level_slots.append(slot_type)

	var new_level := region_state.level_slots.size()

	region_state.confirmed_region_level = new_level
	region_state.pending_level_ups = 0
	region_state.scan_networks_level = new_level + 1
	region_state.expansion_points = max(region_state.expansion_points, new_level)

	print("God mode added slot: ", slot_type)
	print("God mode selected region: ", region_manager.selected_region_data.id)
	print("God mode state region: ", region_state.region_id)
	print("God mode level_slots: ", region_state.level_slots)
	print("God mode confirmed_region_level: ", region_state.confirmed_region_level)

	refresh_ui()


func clear_slots() -> void:
	var region_state := get_selected_region_state()

	if region_state == null:
		print("God mode: no selected region")
		return

	region_state.level_slots.clear()
	region_state.confirmed_region_level = 0
	region_state.pending_level_ups = 0
	region_state.scan_networks_level = 1
	region_state.expansion_points = 0

	print("God mode cleared selected region slots")

	refresh_ui()


func get_selected_region_state() -> RegionState:
	if region_manager == null:
		return null

	if region_manager.selected_region_data == null:
		return null

	return region_manager.get_region_state(region_manager.selected_region_data.id)


func refresh_ui() -> void:
	if main_controller == null:
		return

	if main_controller.has_method("refresh_selected_region_ui"):
		main_controller.refresh_selected_region_ui()

	if main_controller.has_method("update_global_resource_ui"):
		main_controller.update_global_resource_ui()

	if "campaigns_panel" in main_controller:
		main_controller.campaigns_panel.refresh()
