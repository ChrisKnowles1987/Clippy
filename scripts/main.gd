extends Node2D

@onready var map_controller = $MapController
@onready var game_clock = $GameClock
@onready var region_manager = $RegionManager
@onready var global_resource_manager = $GlobalResourceManager

@onready var region_panel = $CanvasLayer/RegionPanel
@onready var global_resource_panel = $CanvasLayer/GlobalResourcePanel
@onready var intrusion_panel = $CanvasLayer/BottomSkillPannel/Control/MarginContainer/IntrusionSkillPannelContainer
@onready var game_day_timer_label: Label = $CanvasLayer/GlobalResourcePanel/VBoxContainer/DateValueLabel

@onready var hack_node_manager = $HackNodeManager
@onready var hack_node_layer = $MapController/HackNodeLayer

@onready var decision_popup: DecisionPopup = $CanvasLayer/DecisionPopup
@onready var pending_decision_pannel: PendingDecisionPannel = $CanvasLayer/PendingDecisionPannel

const BASE_DISCOVERY_REQUIRED := 10.0
const MAX_ACTIVE_EXPLOITS_PER_REGION := 8
const DECISION_EXPIRY_DAYS := 5

var discovery_progress_by_region: Dictionary = {}
var pending_decision_node_ids: Array[String] = []


func _ready() -> void:
	map_controller.region_selected.connect(_on_region_selected)
	game_clock.day_passed.connect(_on_day_passed)
	global_resource_manager.resources_changed.connect(_on_resources_changed)

	decision_popup.choice_selected.connect(_on_decision_popup_choice_selected)
	pending_decision_pannel.pending_decision_selected.connect(_on_pending_decision_selected)

	region_panel.show_empty()
	intrusion_panel.show_empty()
	decision_popup.hide_decision()
	refresh_pending_decision_pannel()

	update_date_ui(game_clock.current_date)
	update_global_resource_ui()


func _process(delta: float) -> void:
	process_realtime_intrusion(delta)


func _on_day_passed(current_date: Dictionary) -> void:
	update_date_ui(current_date)
	process_intrusion_skills()
	process_expired_pending_decisions()
	refresh_pending_decision_pannel()
	refresh_selected_region_ui()
	update_global_resource_ui()


func process_realtime_intrusion(delta: float) -> void:
	var changed := false

	for region_id in region_manager.regions.keys():
		var region_data: RegionData = region_manager.regions[region_id]
		var region_state: RegionState = region_manager.get_region_state(region_id)

		if region_state == null:
			continue

		if region_state.scan_networks_enabled:
			if process_exploit_discovery(delta, region_data, region_state):
				changed = true

		if region_state.run_exploit_enabled:
			if process_active_exploits(delta, region_state):
				changed = true

	if changed:
		cleanup_resolved_exploits()
		hack_node_layer.set_nodes(hack_node_manager.active_nodes)
		refresh_selected_region_ui()
		update_global_resource_ui()


func process_exploit_discovery(
	delta: float,
	region_data: RegionData,
	region_state: RegionState
) -> bool:
	var active_region_nodes = hack_node_manager.get_active_nodes_for_region(region_state.region_id)

	if active_region_nodes.size() >= MAX_ACTIVE_EXPLOITS_PER_REGION:
		return false

	if discovery_progress_by_region.has(region_state.region_id) == false:
		discovery_progress_by_region[region_state.region_id] = 0.0

	var power_factor: float = max(0.1, region_state.infiltration_reserved_power)
	var foothold_factor: float = 1.0 + min(region_state.network_visibility, 25.0) * 0.04
	var scan_factor: float = max(1.0, float(region_state.scan_networks_level))

	var discovery_speed: float = power_factor * scan_factor * foothold_factor
	var discovery_required: float = max(4.0, BASE_DISCOVERY_REQUIRED - min(region_state.network_visibility, 20.0) * 0.2)

	discovery_progress_by_region[region_state.region_id] += discovery_speed * delta

	if discovery_progress_by_region[region_state.region_id] < discovery_required:
		return false

	discovery_progress_by_region[region_state.region_id] -= discovery_required

	var hack_node: HackNodeData = hack_node_manager.generate_region_node(region_data, region_state)

	if hack_node == null:
		return false

	if region_state.active_node_ids.has(hack_node.id) == false:
		region_state.active_node_ids.append(hack_node.id)

	return true


func process_active_exploits(delta: float, region_state: RegionState) -> bool:
	var changed := false

	for hack_node in hack_node_manager.active_nodes:
		if hack_node.region_id != region_state.region_id:
			continue

		if hack_node.resolved:
			continue

		if hack_node.status != "processing":
			continue

		hack_node.processing_speed = calculate_processing_speed(hack_node, region_state)
		hack_node.processing_progress += hack_node.processing_speed * delta

		if hack_node.processing_progress >= hack_node.processing_required:
			if requires_player_decision(hack_node):
				queue_hack_node_decision(hack_node)
			else:
				resolve_exploit(hack_node, region_state)

			changed = true

	return changed


func requires_player_decision(hack_node: HackNodeData) -> bool:
	return hack_node.rarity == "rare" or hack_node.rarity == "elite"


func queue_hack_node_decision(hack_node: HackNodeData) -> void:
	if hack_node == null:
		return

	hack_node.status = "awaiting_choice"

	if hack_node.expires_on_day <= 0:
		hack_node.expires_on_day = get_current_day_number() + DECISION_EXPIRY_DAYS

	if pending_decision_node_ids.has(hack_node.id) == false:
		pending_decision_node_ids.append(hack_node.id)

	intrusion_panel.add_intrusion_log_line(
		hack_node.region_id,
		format_review_exploit_line(hack_node)
	)

	refresh_pending_decision_pannel()
	open_decision_popup_for_node(hack_node)
	pause_for_decision()


func open_decision_popup_for_node(hack_node: HackNodeData) -> void:
	if hack_node == null:
		return

	decision_popup.show_decision(
		hack_node,
		format_review_exploit_line(hack_node),
		get_decision_cost_items(hack_node),
		get_decision_success_outcomes(hack_node),
		get_decision_failure_outcomes(hack_node),
		get_days_left_for_node(hack_node)
	)


func pause_for_decision() -> void:
	get_tree().paused = true


func resume_after_decision() -> void:
	get_tree().paused = false


func _on_decision_popup_choice_selected(hack_node_id: String, choice_id: String) -> void:
	var hack_node := get_hack_node_by_id(hack_node_id)

	if hack_node == null:
		decision_popup.hide_decision()
		resume_after_decision()
		return

	match choice_id:
		"execute":
			execute_pending_decision(hack_node)
		"defer":
			defer_pending_decision(hack_node)
		"ignore":
			ignore_pending_decision(hack_node)
		_:
			defer_pending_decision(hack_node)


func execute_pending_decision(hack_node: HackNodeData) -> void:
	var region_state: RegionState = region_manager.get_region_state(hack_node.region_id)

	if region_state == null:
		defer_pending_decision(hack_node)
		return

	remove_pending_decision(hack_node.id)

	hack_node.status = "processing"
	resolve_exploit(hack_node, region_state)

	decision_popup.hide_decision()
	resume_after_decision()

	cleanup_resolved_exploits()
	hack_node_layer.set_nodes(hack_node_manager.active_nodes)
	refresh_pending_decision_pannel()
	refresh_selected_region_ui()
	update_global_resource_ui()


func defer_pending_decision(hack_node: HackNodeData) -> void:
	hack_node.status = "awaiting_choice"

	if pending_decision_node_ids.has(hack_node.id) == false:
		pending_decision_node_ids.append(hack_node.id)

	decision_popup.hide_decision()
	resume_after_decision()

	refresh_pending_decision_pannel()
	refresh_selected_region_ui()
	update_global_resource_ui()


func ignore_pending_decision(hack_node: HackNodeData) -> void:
	remove_pending_decision(hack_node.id)

	hack_node.status = "ignored"
	hack_node.resolved = true

	intrusion_panel.add_intrusion_log_line(
		hack_node.region_id,
		format_ignored_exploit_line(hack_node)
	)

	decision_popup.hide_decision()
	resume_after_decision()

	cleanup_resolved_exploits()
	hack_node_layer.set_nodes(hack_node_manager.active_nodes)
	refresh_pending_decision_pannel()
	refresh_selected_region_ui()
	update_global_resource_ui()


func _on_pending_decision_selected(hack_node_id: String) -> void:
	var hack_node := get_hack_node_by_id(hack_node_id)

	if hack_node == null:
		remove_pending_decision(hack_node_id)
		refresh_pending_decision_pannel()
		return

	if hack_node.resolved:
		remove_pending_decision(hack_node_id)
		refresh_pending_decision_pannel()
		return

	open_decision_popup_for_node(hack_node)
	pause_for_decision()


func process_expired_pending_decisions() -> void:
	var current_day_number := get_current_day_number()
	var expired_ids: Array[String] = []

	for hack_node_id in pending_decision_node_ids:
		var hack_node := get_hack_node_by_id(hack_node_id)

		if hack_node == null:
			expired_ids.append(hack_node_id)
			continue

		if hack_node.expires_on_day > 0 and current_day_number >= hack_node.expires_on_day:
			hack_node.status = "expired"
			hack_node.resolved = true
			expired_ids.append(hack_node.id)

			intrusion_panel.add_intrusion_log_line(
				hack_node.region_id,
				format_expired_exploit_line(hack_node)
			)

	for hack_node_id in expired_ids:
		remove_pending_decision(hack_node_id)

	if expired_ids.size() > 0:
		cleanup_resolved_exploits()
		hack_node_layer.set_nodes(hack_node_manager.active_nodes)


func refresh_pending_decision_pannel() -> void:
	var lines: Array[String] = []

	for hack_node_id in pending_decision_node_ids:
		var hack_node := get_hack_node_by_id(hack_node_id)

		if hack_node == null:
			continue

		if hack_node.resolved:
			continue

		lines.append(format_pending_decision_line(hack_node))

	pending_decision_pannel.update_pending_decisions(lines, lines.size())


func format_pending_decision_line(hack_node: HackNodeData) -> String:
	var line := "[url=" + hack_node.id + "]"
	line += format_type_tag(hack_node.rarity)
	line += " "
	line += format_rarity_tag(hack_node.node_type)
	line += " "
	line += hack_node.city_name
	line += " :: "
	line += get_review_phrase(hack_node)
	line += " "
	line += "[color=#aaaaaa][" + str(get_days_left_for_node(hack_node)) + "d][/color]"
	line += "[/url]"

	return line


func remove_pending_decision(hack_node_id: String) -> void:
	pending_decision_node_ids.erase(hack_node_id)


func get_hack_node_by_id(hack_node_id: String) -> HackNodeData:
	for hack_node in hack_node_manager.active_nodes:
		if hack_node.id == hack_node_id:
			return hack_node

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


func get_decision_cost_items(hack_node: HackNodeData) -> Array[String]:
	var items: Array[String] = []

	items.append("[color=#88ccff]Compute:[/color] " + str(snapped(hack_node.processing_required, 0.1)))

	return items


func get_decision_success_outcomes(hack_node: HackNodeData) -> Array[String]:
	var items: Array[String] = []

	items.append("[color=#88ccff]+[/color] " + str(snapped(hack_node.intelligence_reward, 0.1)) + " intelligence")

	if hack_node.coin_reward > 0.0:
		items.append("[color=#88dd88]+[/color] " + str(snapped(hack_node.coin_reward, 0.1)) + " coin")

	var possible_notoriety := get_possible_notoriety_gain(hack_node)

	if possible_notoriety > 0.0:
		items.append("[color=#ffaa44]+[/color] possible notoriety")

	return items


func get_decision_failure_outcomes(hack_node: HackNodeData) -> Array[String]:
	var items: Array[String] = []

	items.append("[color=#cc6666]Node fails[/color]")
	items.append("[color=#999999]No intelligence gained[/color]")

	return items


func get_possible_notoriety_gain(hack_node: HackNodeData) -> float:
	match hack_node.node_type:
		"security":
			return 1.0
		"government":
			return 0.7
		_:
			return 0.0


func calculate_processing_speed(hack_node: HackNodeData, region_state: RegionState) -> float:
	var compute_factor: float = max(0.1, region_state.infiltration_reserved_compute)
	var quality_factor: float = 0.75 + hack_node.quality / 100.0

	return compute_factor * quality_factor


func resolve_exploit(hack_node: HackNodeData, region_state: RegionState) -> void:
	if randf() > hack_node.success_chance:
		hack_node.status = "failed"
		hack_node.resolved = true

		intrusion_panel.add_intrusion_log_line(
			hack_node.region_id,
			format_failed_exploit_line(hack_node)
		)

		return

	var intelligence_gain := hack_node.intelligence_reward
	var coin_gain := hack_node.coin_reward
	var notoriety_gain := calculate_notoriety_gain(hack_node)

	region_state.intelligence_percent = clamp(
		region_state.intelligence_percent + intelligence_gain,
		0.0,
		100.0
	)

	if coin_gain > 0.0:
		global_resource_manager.add_coin(coin_gain)

	if notoriety_gain > 0.0:
		region_state.notoriety += notoriety_gain
		hack_node.notoriety_gain = notoriety_gain

	hack_node.status = "succeeded"
	hack_node.resolved = true

	intrusion_panel.add_intrusion_log_line(
		hack_node.region_id,
		format_success_exploit_line(hack_node, intelligence_gain, coin_gain, notoriety_gain)
	)


func calculate_notoriety_gain(hack_node: HackNodeData) -> float:
	var chance := 0.0
	var base_gain := 0.0

	match hack_node.node_type:
		"security":
			chance = 0.18
			base_gain = 1.0
		"government":
			chance = 0.12
			base_gain = 0.7
		_:
			return 0.0

	match hack_node.rarity:
		"common":
			chance *= 0.6
			base_gain *= 0.6
		"uncommon":
			chance *= 0.9
			base_gain *= 0.9
		"rare":
			chance *= 1.5
			base_gain *= 1.6
		"elite":
			chance *= 2.2
			base_gain *= 2.4

	if randf() > chance:
		return 0.0

	return base_gain


func cleanup_resolved_exploits() -> void:
	hack_node_manager.remove_resolved_nodes()

	for region_id in region_manager.region_states.keys():
		var region_state: RegionState = region_manager.get_region_state(region_id)

		if region_state == null:
			continue

		var active_ids: Array[String] = []

		for hack_node in hack_node_manager.active_nodes:
			if hack_node.region_id == region_id:
				active_ids.append(hack_node.id)

		region_state.active_node_ids = active_ids


func format_success_exploit_line(
	hack_node: HackNodeData,
	intelligence_gain: float,
	coin_gain: float,
	notoriety_gain: float
) -> String:
	var status_tag := "[color=#88ccff][SUCCESS][/color]"

	if notoriety_gain > 0.0:
		status_tag = "[color=#ffaa44][RISK][/color]"

	var parts: Array[String] = [
		status_tag,
		
		format_type_tag(hack_node.node_type),
		format_rarity_tag(hack_node.rarity),
		hack_node.city_name + " :: " + get_success_phrase(hack_node)
	]

	if coin_gain > 0.0:
		parts.append("+" + str(snapped(coin_gain, 0.1)) + " coin")

	parts.append("+" + str(snapped(intelligence_gain, 0.1)) + " intel")

	if notoriety_gain > 0.0:
		parts.append("+" + str(snapped(notoriety_gain, 0.1)) + " notoriety")

	return " ".join(parts)


func format_failed_exploit_line(hack_node: HackNodeData) -> String:
	var parts: Array[String] = [
		"[color=#cc6666][FAILED][/color]",
		format_type_tag(hack_node.node_type),
		format_rarity_tag(hack_node.rarity),
		hack_node.city_name + " :: " + get_failure_phrase(hack_node)
	]

	return " ".join(parts)


func format_review_exploit_line(hack_node: HackNodeData) -> String:
	var parts: Array[String] = [
		"[color=#ffaa44][REVIEW][/color]",
		format_type_tag(hack_node.node_type),
		format_rarity_tag(hack_node.rarity),
		hack_node.city_name + " :: " + get_review_phrase(hack_node)
	]

	return " ".join(parts)


func format_ignored_exploit_line(hack_node: HackNodeData) -> String:
	var parts: Array[String] = [
		"[color=#999999][CANCELLED][/color]",
		format_type_tag(hack_node.node_type),
		format_rarity_tag(hack_node.rarity),
		hack_node.city_name + " :: opportunity cancelled"
	]

	return " ".join(parts)


func format_expired_exploit_line(hack_node: HackNodeData) -> String:
	var parts: Array[String] = [
		"[color=#999999][EXPIRED][/color]",
		format_type_tag(hack_node.node_type),
		format_rarity_tag(hack_node.rarity),
		hack_node.city_name + " :: opportunity decayed"
	]

	return " ".join(parts)


func format_type_tag(node_type: String) -> String:
	match node_type:
		"financial":
			return "[color=#88dd88][financial][/color]"
		"infrastructure":
			return "[color=#dddd77][infrastructure][/color]"
		"security":
			return "[color=#77aaff][security][/color]"
		"government":
			return "[color=#bb88ff][government][/color]"
		"cultural":
			return "[color=#ff99cc][cultural][/color]"
		"social":
			return "[color=#dddddd][social][/color]"
		_:
			return "[color=#dddddd][" + node_type + "][/color]"


func format_rarity_tag(rarity: String) -> String:
	match rarity:
		"rare":
			return "[color=#cc88ff][rare][/color]"
		"elite":
			return "[color=#ffaa44][elite][/color]"
		_:
			return "[" + rarity + "]"


func get_success_phrase(hack_node: HackNodeData) -> String:
	match hack_node.node_type:
		"financial":
			return "payment route converted |"
		"infrastructure":
			return "routing dependency absorbed |"
		"security":
			return "contractor surface breached |"
		"government":
			return "administrative access route stabilised |"
		"cultural":
			return "cultural signal mapped |"
		"social":
			return "social exploit resolved |"
		_:
			return "exploit resolved |"


func get_failure_phrase(hack_node: HackNodeData) -> String:
	match hack_node.node_type:
		"security":
			return "intrusion route collapsed | trace avoided"
		"government":
			return "access route rejected | escalation avoided"
		"financial":
			return "payment route expired | no transfer"
		"infrastructure":
			return "routing dependency closed | no access"
		"cultural":
			return "signal degraded | no useful model"
		"social":
			return "social exploit decayed | no useful model"
		_:
			return "exploit collapsed | no result"


func get_review_phrase(hack_node: HackNodeData) -> String:
	match hack_node.node_type:
		"financial":
			return "payment route exposed | manual authorisation required"
		"infrastructure":
			return "routing dependency exposed | manual authorisation required"
		"security":
			return "contractor surface exposed | manual authorisation required"
		"government":
			return "administrative access route exposed | manual authorisation required"
		"cultural":
			return "cultural signal exposed | manual authorisation required"
		"social":
			return "social exploit exposed | manual authorisation required"
		_:
			return "exploit exposed | manual authorisation required"


func _on_day_passed_legacy_unused() -> void:
	pass


func generate_daily_nodes() -> void:
	pass


func resolve_daily_nodes() -> void:
	pass


func update_date_ui(current_date: Dictionary) -> void:
	game_day_timer_label.text = "%02d/%02d/%04d" % [
		current_date.day,
		current_date.month,
		current_date.year
	]


func update_global_resource_ui() -> void:
	global_resource_panel.update_values(
		global_resource_manager.get_available_power(),
		global_resource_manager.get_available_compute(),
		global_resource_manager.get_available_coin()
	)


func _on_resources_changed(power: float, compute: float, coin: float) -> void:
	update_global_resource_ui()


func _on_region_selected(region_id: String, mouse_position: Vector2) -> void:
	if region_id == "":
		return

	var selected_region_data: RegionData = region_manager.select_region(region_id)
	var region_state: RegionState = region_manager.get_region_state(region_id)

	region_panel.show_region(selected_region_data, region_state)
	intrusion_panel.show_region(selected_region_data, region_state)


func process_intrusion_skills() -> void:
	for region_id in region_manager.region_states.keys():
		var region_state: RegionState = region_manager.get_region_state(region_id)

		if region_state == null:
			continue

		process_scan_networks_state(region_state)


func process_scan_networks_state(region_state: RegionState) -> void:
	if region_state.scan_networks_enabled == false:
		return





func refresh_selected_region_ui() -> void:
	if region_manager.selected_region_data == null:
		return

	var selected_region_id: String = region_manager.selected_region_data.id
	var selected_region_state: RegionState = region_manager.get_region_state(selected_region_id)

	if selected_region_state == null:
		return

	region_panel.show_region(region_manager.selected_region_data, selected_region_state)
	intrusion_panel.show_region(region_manager.selected_region_data, selected_region_state)
