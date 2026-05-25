extends Node2D

@onready var map_controller: Node2D = $MapController
@onready var map_view_tabs: PanelContainer = $CanvasLayer/MapViewTabs

@onready var game_clock = $GameClock
@onready var region_manager = $RegionManager
@onready var global_resource_manager = $GlobalResourceManager

@onready var global_resource_panel = $CanvasLayer/GlobalResourcePanel
@onready var bottom_skill_pannel: Control = $CanvasLayer/BottomSkillPannel
@onready var intrusion_panel = $CanvasLayer/BottomSkillPannel/Control/MarginContainer/IntrusionSkillPannelContainer
@onready var expansion_panel = $CanvasLayer/BottomSkillPannel/Control/MarginContainer/ExpansionPannelContainer
@onready var game_day_timer_label: Label = $CanvasLayer/GlobalResourcePanel/VBoxContainer/DateValueLabel
@onready var notoriety_panel: NotorietyPanel = $CanvasLayer/NotorietyPannelContainer

@onready var hack_node_manager = $HackNodeManager
@onready var hack_node_layer = $MapController/HackNodeLayer
@onready var expansion_node_layer = $MapController/ExpansionNodeLayer

@onready var decision_popup: DecisionPopup = $CanvasLayer/DecisionPopup
@onready var pending_decision_pannel: PendingDecisionPannel = $CanvasLayer/PendingDecisionPannel

var hack_decision_manager: HackDecisionManager = null
var hack_exploit_processor: HackExploitProcessor = null
var hack_discovery_processor: HackDiscoveryProcessor = null
var infiltration_processor: InfiltrationProcessor = null
var notoriety_manager: NotorietyManager = null
var current_map_view: String = "infiltration"


func _ready() -> void:
	map_view_tabs.map_view_selected.connect(set_map_view)
	set_map_view("infiltration")
	
	map_controller.region_selected.connect(_on_region_selected)
	map_controller.expansion_region_selected.connect(_on_expansion_region_selected)
	game_clock.day_passed.connect(_on_day_passed)
	global_resource_manager.resources_changed.connect(_on_resources_changed)
	decision_popup.setup(global_resource_manager)
	expansion_panel.setup(region_manager, expansion_node_layer, global_resource_manager)
	notoriety_manager = NotorietyManager.new()
	add_child(notoriety_manager)

	notoriety_panel.refresh(region_manager.region_states, notoriety_manager)

	hack_decision_manager = HackDecisionManager.new()
	add_child(hack_decision_manager)

	hack_exploit_processor = HackExploitProcessor.new()
	add_child(hack_exploit_processor)

	hack_exploit_processor.setup(
		hack_node_manager,
		region_manager,
		global_resource_manager,
		intrusion_panel,
		hack_decision_manager
	)
	
	hack_discovery_processor = HackDiscoveryProcessor.new()
	add_child(hack_discovery_processor)
	
	infiltration_processor = InfiltrationProcessor.new()
	add_child(infiltration_processor)

	infiltration_processor.setup(
		hack_discovery_processor,
		hack_exploit_processor
)
	
	

	hack_discovery_processor.setup(hack_node_manager)

	hack_decision_manager.setup(
		self,
		game_clock,
		region_manager,
		hack_node_manager,
		hack_node_layer,
		intrusion_panel,
		decision_popup,
		pending_decision_pannel,
		hack_exploit_processor
	)

	
	intrusion_panel.show_empty()
	expansion_panel.show_empty()

	update_date_ui(game_clock.current_date)
	update_global_resource_ui()


func _process(delta: float) -> void:
	process_realtime_intrusion(delta)


func set_map_view(view_name: String) -> void:
	current_map_view = view_name
	map_controller.set_map_view(view_name)

	var infiltration_view := view_name == "infiltration"
	var expansion_view := view_name == "expansion"

	bottom_skill_pannel.visible = infiltration_view or expansion_view
	intrusion_panel.visible = infiltration_view
	expansion_panel.visible = expansion_view


func _on_day_passed(current_date: Dictionary) -> void:
	update_date_ui(current_date)
	hack_decision_manager.process_expired_pending_decisions()
	hack_decision_manager.refresh_pending_decision_pannel()
	refresh_selected_region_ui()
	expansion_panel.refresh()
	refresh_notoriety_ui()
	update_global_resource_ui()
	


func process_realtime_intrusion(delta: float) -> void:
	var changed := false

	for region_id in region_manager.regions.keys():
		var region_data: RegionData = region_manager.regions[region_id]
		var region_state: RegionState = region_manager.get_region_state(region_id)

		if region_state == null:
			continue

		if infiltration_processor.process_region(delta, region_data, region_state):
			changed = true

	if changed:
		hack_exploit_processor.cleanup_resolved_exploits()
		hack_node_layer.set_nodes(hack_node_manager.active_nodes)
		refresh_selected_region_ui()
		expansion_panel.refresh()
		update_global_resource_ui()
		refresh_notoriety_ui()

	if changed:
		hack_exploit_processor.cleanup_resolved_exploits()
		hack_node_layer.set_nodes(hack_node_manager.active_nodes)
		refresh_selected_region_ui()
		expansion_panel.refresh()
		update_global_resource_ui()
		refresh_notoriety_ui()



func refresh_notoriety_ui() -> void:
	notoriety_panel.refresh(region_manager.region_states, notoriety_manager)
	
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

	intrusion_panel.show_region(selected_region_data, region_state)


func _on_expansion_region_selected(region_id: String) -> void:
	if region_id == "":
		return

	expansion_panel.show_region(region_id)


func refresh_selected_region_ui() -> void:
	if current_map_view != "infiltration":
		return

	if region_manager.selected_region_data == null:
		return

	var selected_region_id: String = region_manager.selected_region_data.id
	var selected_region_state: RegionState = region_manager.get_region_state(selected_region_id)

	if selected_region_state == null:
		return


	intrusion_panel.show_region(region_manager.selected_region_data, selected_region_state)
