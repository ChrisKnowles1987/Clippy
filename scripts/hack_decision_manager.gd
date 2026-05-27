extends Node
class_name HackDecisionManager

const DECISION_EXPIRY_DAYS := 5
const HACK_NODE_DECISION_PREFIX := "hack_node:"

var main_controller: Node = null
var game_clock = null
var region_manager = null
var global_resource_manager = null
var hack_node_manager = null
var hack_node_layer = null
var intrusion_panel = null
var decision_popup: DecisionPopup = null
var pending_decision_pannel: PendingDecisionPannel = null
var hack_exploit_processor: HackExploitProcessor = null

var pending_decision_ids: Array[String] = []


func setup(
	main_controller_ref: Node,
	game_clock_ref: Node,
	region_manager_ref: Node,
	hack_node_manager_ref: Node,
	hack_node_layer_ref: Node,
	intrusion_panel_ref: Node,
	decision_popup_ref: DecisionPopup,
	pending_decision_pannel_ref: PendingDecisionPannel,
	hack_exploit_processor_ref: HackExploitProcessor
) -> void:
	main_controller = main_controller_ref
	game_clock = game_clock_ref
	region_manager = region_manager_ref
	global_resource_manager = main_controller_ref.global_resource_manager
	hack_node_manager = hack_node_manager_ref
	hack_node_layer = hack_node_layer_ref
	intrusion_panel = intrusion_panel_ref
	decision_popup = decision_popup_ref
	pending_decision_pannel = pending_decision_pannel_ref
	hack_exploit_processor = hack_exploit_processor_ref

	decision_popup.choice_selected.connect(_on_decision_popup_choice_selected)
	pending_decision_pannel.pending_decision_selected.connect(_on_pending_decision_selected)

	decision_popup.hide_decision()
	refresh_pending_decision_pannel()


func queue_hack_node_decision(hack_node: HackNodeData) -> void:
	if hack_node == null:
		return

	hack_node.status = "awaiting_choice"

	if hack_node.expires_on_day <= 0:
		hack_node.expires_on_day = get_current_day_number() + DECISION_EXPIRY_DAYS

	add_pending_decision(get_hack_node_decision_id(hack_node.id))

	intrusion_panel.add_intrusion_log_line(
		hack_node.region_id,
		HackNodeTextFormatter.format_review_exploit_line(hack_node)
	)

	refresh_pending_decision_pannel()
	open_decision_popup_for_node(hack_node)
	pause_for_decision()


func queue_regional_level_up_decision(region_id: String) -> void:
	var region_state: RegionState = region_manager.get_region_state(region_id)

	if region_state == null:
		return

	if region_state.has_pending_level_up() == false:
		return

	var decision_id := RegionalLevelUpDecisionBuilder.get_decision_id(region_id)
	add_pending_decision(decision_id)
	refresh_pending_decision_pannel()
	pause_for_decision()


func open_decision_popup_for_node(hack_node: HackNodeData) -> void:
	if hack_node == null:
		return

	var terminal_line := HackNodeTextFormatter.format_review_exploit_line(hack_node)
	var days_left := get_days_left_for_node(hack_node)
	var decision := HackDecisionBuilder.build_decision(hack_node, terminal_line, days_left)

	decision.id = get_hack_node_decision_id(hack_node.id)
	decision_popup.show_decision(decision)


func open_regional_level_up_popup(region_id: String) -> void:
	var region_state: RegionState = region_manager.get_region_state(region_id)

	if region_state == null:
		return

	var region_data: RegionData = region_manager.regions.get(region_id, null)
	var decision := RegionalLevelUpDecisionBuilder.build_decision(region_data, region_state)

	decision_popup.show_decision(decision)


func pause_for_decision() -> void:
	get_tree().paused = true


func resume_after_decision() -> void:
	get_tree().paused = false


func _on_decision_popup_choice_selected(decision_id: String, choice_id: String) -> void:
	if is_hack_node_decision_id(decision_id):
		handle_hack_node_choice(decision_id, choice_id)
		return

	if RegionalLevelUpDecisionBuilder.is_level_up_decision_id(decision_id):
		handle_regional_level_up_choice(decision_id, choice_id)
		return

	decision_popup.hide_decision()
	resume_after_decision()


func handle_hack_node_choice(decision_id: String, choice_id: String) -> void:
	var hack_node_id := get_hack_node_id_from_decision_id(decision_id)
	var hack_node := get_hack_node_by_id(hack_node_id)

	if hack_node == null:
		decision_popup.hide_decision()
		resume_after_decision()
		return

	var decision := HackDecisionBuilder.build_decision(
		hack_node,
		HackNodeTextFormatter.format_review_exploit_line(hack_node),
		get_days_left_for_node(hack_node)
	)

	var choice := get_choice_by_id(decision, choice_id)

	if choice == null:
		defer_pending_hack_node_decision(hack_node)
		return

	if global_resource_manager.apply_decision_choice(choice) == false:
		open_decision_popup_for_node(hack_node)
		decision_popup.set_warning_text("Insufficient resources")
		return

	match choice_id:
		"execute":
			execute_pending_hack_node_decision(hack_node)
		"defer":
			defer_pending_hack_node_decision(hack_node)
		"ignore":
			ignore_pending_hack_node_decision(hack_node)
		_:
			defer_pending_hack_node_decision(hack_node)


func handle_regional_level_up_choice(decision_id: String, choice_id: String) -> void:
	var region_id := RegionalLevelUpDecisionBuilder.get_region_id_from_decision_id(decision_id)
	var region_state: RegionState = region_manager.get_region_state(region_id)

	if region_state == null:
		remove_pending_decision(decision_id)
		decision_popup.hide_decision()
		resume_after_decision()
		refresh_after_decision_change()
		return

	var region_data: RegionData = region_manager.regions.get(region_id, null)
	var decision := RegionalLevelUpDecisionBuilder.build_decision(region_data, region_state)
	var choice := get_choice_by_id(decision, choice_id)

	if choice_id == "defer" or choice == null:
		defer_regional_level_up_decision(region_id)
		return

	if choice_id == "confirm_level_up" and can_assign_level_up_resources(region_state) == false:
		open_regional_level_up_popup(region_id)
		decision_popup.set_warning_text("Insufficient resources")
		return

	match choice_id:
		"confirm_level_up":
			confirm_regional_level_up_decision(region_id)
		_:
			defer_regional_level_up_decision(region_id)


func can_assign_level_up_resources(region_state: RegionState) -> bool:
	var power_assignment := region_state.get_next_level_up_power_cost()
	var compute_assignment := region_state.get_next_level_up_compute_cost()

	return global_resource_manager.can_reserve(power_assignment, compute_assignment)


func execute_pending_hack_node_decision(hack_node: HackNodeData) -> void:
	var region_state: RegionState = region_manager.get_region_state(hack_node.region_id)

	if region_state == null:
		defer_pending_hack_node_decision(hack_node)
		return

	remove_pending_decision(get_hack_node_decision_id(hack_node.id))

	hack_node.status = "processing"
	hack_exploit_processor.resolve_exploit(hack_node, region_state)

	decision_popup.hide_decision()
	resume_after_decision()

	hack_exploit_processor.cleanup_resolved_exploits()
	hack_node_layer.set_nodes(hack_node_manager.active_nodes)
	refresh_after_decision_change()


func defer_pending_hack_node_decision(hack_node: HackNodeData) -> void:
	hack_node.status = "awaiting_choice"
	add_pending_decision(get_hack_node_decision_id(hack_node.id))

	decision_popup.hide_decision()
	resume_after_decision()

	refresh_after_decision_change()


func ignore_pending_hack_node_decision(hack_node: HackNodeData) -> void:
	remove_pending_decision(get_hack_node_decision_id(hack_node.id))

	hack_node.status = "ignored"
	hack_node.resolved = true

	intrusion_panel.add_intrusion_log_line(
		hack_node.region_id,
		HackNodeTextFormatter.format_ignored_exploit_line(hack_node)
	)

	decision_popup.hide_decision()
	resume_after_decision()

	hack_exploit_processor.cleanup_resolved_exploits()
	hack_node_layer.set_nodes(hack_node_manager.active_nodes)
	refresh_after_decision_change()


func defer_regional_level_up_decision(region_id: String) -> void:
	var decision_id := RegionalLevelUpDecisionBuilder.get_decision_id(region_id)
	add_pending_decision(decision_id)

	decision_popup.hide_decision()
	resume_after_decision()

	refresh_after_decision_change()


func confirm_regional_level_up_decision(region_id: String) -> void:
	var region_state: RegionState = region_manager.get_region_state(region_id)

	if region_state == null:
		return

	var decision_id := RegionalLevelUpDecisionBuilder.get_decision_id(region_id)
	var power_assignment := region_state.get_next_level_up_power_cost()
	var compute_assignment := region_state.get_next_level_up_compute_cost()

	if region_state.infiltration_enabled:
		global_resource_manager.reserve(power_assignment, compute_assignment)

	if region_state.confirm_level_up():
		region_state.infiltration_reserved_power += power_assignment
		region_state.infiltration_reserved_compute += compute_assignment

		intrusion_panel.add_intrusion_log_line(
			region_id,
			"[color=#88ccff][LEVEL][/color] regional level authorised | Power +" + str(snapped(power_assignment, 0.1)) + " | Compute +" + str(snapped(compute_assignment, 0.1)) + " | scan networks +1 | expansion point +1"
		)

	if region_state.has_pending_level_up() == false:
		remove_pending_decision(decision_id)
	else:
		add_pending_decision(decision_id)

	decision_popup.hide_decision()
	resume_after_decision()

	refresh_after_decision_change()


func _on_pending_decision_selected(decision_id: String) -> void:
	if is_hack_node_decision_id(decision_id):
		var hack_node_id := get_hack_node_id_from_decision_id(decision_id)
		var hack_node := get_hack_node_by_id(hack_node_id)

		if hack_node == null:
			remove_pending_decision(decision_id)
			refresh_pending_decision_pannel()
			return

		if hack_node.resolved:
			remove_pending_decision(decision_id)
			refresh_pending_decision_pannel()
			return

		open_decision_popup_for_node(hack_node)
		pause_for_decision()
		return

	if RegionalLevelUpDecisionBuilder.is_level_up_decision_id(decision_id):
		var region_id := RegionalLevelUpDecisionBuilder.get_region_id_from_decision_id(decision_id)
		var region_state: RegionState = region_manager.get_region_state(region_id)

		if region_state == null or region_state.has_pending_level_up() == false:
			remove_pending_decision(decision_id)
			refresh_pending_decision_pannel()
			return

		open_regional_level_up_popup(region_id)
		pause_for_decision()


func process_expired_pending_decisions() -> void:
	var current_day_number := get_current_day_number()
	var expired_ids: Array[String] = []

	for decision_id in pending_decision_ids:
		if is_hack_node_decision_id(decision_id) == false:
			continue

		var hack_node_id := get_hack_node_id_from_decision_id(decision_id)
		var hack_node := get_hack_node_by_id(hack_node_id)

		if hack_node == null:
			expired_ids.append(decision_id)
			continue

		if hack_node.expires_on_day > 0 and current_day_number >= hack_node.expires_on_day:
			hack_node.status = "expired"
			hack_node.resolved = true
			expired_ids.append(decision_id)

			intrusion_panel.add_intrusion_log_line(
				hack_node.region_id,
				HackNodeTextFormatter.format_expired_exploit_line(hack_node)
			)

	for decision_id in expired_ids:
		remove_pending_decision(decision_id)

	if expired_ids.size() > 0:
		hack_exploit_processor.cleanup_resolved_exploits()
		hack_node_layer.set_nodes(hack_node_manager.active_nodes)


func refresh_pending_decision_pannel() -> void:
	var lines: Array[String] = []

	for decision_id in pending_decision_ids:
		if is_hack_node_decision_id(decision_id):
			var hack_node_id := get_hack_node_id_from_decision_id(decision_id)
			var hack_node := get_hack_node_by_id(hack_node_id)

			if hack_node == null:
				continue

			if hack_node.resolved:
				continue

			lines.append(
				HackNodeTextFormatter.format_pending_decision_line(
					hack_node,
					get_days_left_for_node(hack_node),
					decision_id
				)
			)
			continue

		if RegionalLevelUpDecisionBuilder.is_level_up_decision_id(decision_id):
			var region_id := RegionalLevelUpDecisionBuilder.get_region_id_from_decision_id(decision_id)
			var region_state: RegionState = region_manager.get_region_state(region_id)

			if region_state == null:
				continue

			if region_state.has_pending_level_up() == false:
				continue

			var region_data: RegionData = region_manager.regions.get(region_id, null)
			lines.append(format_pending_level_up_line(decision_id, region_data, region_state))

	pending_decision_pannel.update_pending_decisions(lines, lines.size())


func format_pending_level_up_line(decision_id: String, region_data: RegionData, region_state: RegionState) -> String:
	var region_name := region_state.region_id

	if region_data != null:
		region_name = region_data.display_name

	var line := "[url=" + decision_id + "]"
	line += "[color=#88ccff][LEVEL][/color] "
	line += region_name
	line += " :: authorisation pending"
	line += " [color=#aaaaaa](" + str(region_state.pending_level_ups) + ") [/color]"
	line += "[/url]"

	return line


func refresh_after_decision_change() -> void:
	refresh_pending_decision_pannel()
	main_controller.refresh_selected_region_ui()
	main_controller.update_global_resource_ui()
	main_controller.refresh_notoriety_ui()


func add_pending_decision(decision_id: String) -> void:
	if pending_decision_ids.has(decision_id) == false:
		pending_decision_ids.append(decision_id)


func remove_pending_decision(decision_id: String) -> void:
	pending_decision_ids.erase(decision_id)


func get_hack_node_by_id(hack_node_id: String) -> HackNodeData:
	for hack_node in hack_node_manager.active_nodes:
		if hack_node.id == hack_node_id:
			return hack_node

	return null


func get_choice_by_id(decision: DecisionData, choice_id: String) -> DecisionChoiceData:
	for choice in decision.choices:
		if choice.id == choice_id:
			return choice

	return null


func get_current_day_number() -> int:
	var current_date: Dictionary = game_clock.current_date

	var year := int(current_date.year)
	var month := int(current_date.month)
	var day := int(current_date.day)

	return year * 365 + month * 30 + day


func get_days_left_for_node(hack_node: HackNodeData) -> int:
	if hack_node.expires_on_day <= 0:
		return DECISION_EXPIRY_DAYS

	return max(0, hack_node.expires_on_day - get_current_day_number())


func get_hack_node_decision_id(hack_node_id: String) -> String:
	return HACK_NODE_DECISION_PREFIX + hack_node_id


func get_hack_node_id_from_decision_id(decision_id: String) -> String:
	if is_hack_node_decision_id(decision_id) == false:
		return ""

	return decision_id.substr(HACK_NODE_DECISION_PREFIX.length())


func is_hack_node_decision_id(decision_id: String) -> bool:
	return decision_id.begins_with(HACK_NODE_DECISION_PREFIX)
