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

var discovery_progress_by_region: Dictionary = {}
var hack_decision_manager: HackDecisionManager = null


func _ready() -> void:
	map_controller.region_selected.connect(_on_region_selected)
	game_clock.day_passed.connect(_on_day_passed)
	global_resource_manager.resources_changed.connect(_on_resources_changed)

	hack_decision_manager = HackDecisionManager.new()
	add_child(hack_decision_manager)

	hack_decision_manager.setup(
		self,
		game_clock,
		region_manager,
		hack_node_manager,
		hack_node_layer,
		intrusion_panel,
		decision_popup,
		pending_decision_pannel
	)

	region_panel.show_empty()
	intrusion_panel.show_empty()

	update_date_ui(game_clock.current_date)
	update_global_resource_ui()


func _process(delta: float) -> void:
	process_realtime_intrusion(delta)


func _on_day_passed(current_date: Dictionary) -> void:
	update_date_ui(current_date)
	process_intrusion_skills()
	hack_decision_manager.process_expired_pending_decisions()
	hack_decision_manager.refresh_pending_decision_pannel()
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
				hack_decision_manager.queue_hack_node_decision(hack_node)
			else:
				resolve_exploit(hack_node, region_state)

			changed = true

	return changed


func requires_player_decision(hack_node: HackNodeData) -> bool:
	return hack_node.rarity == "rare" or hack_node.rarity == "elite"


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
			HackNodeTextFormatter.format_failed_exploit_line(hack_node)
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
		HackNodeTextFormatter.format_success_exploit_line(
			hack_node,
			intelligence_gain,
			coin_gain,
			notoriety_gain
		)
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
