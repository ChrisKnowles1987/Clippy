extends MarginContainer
class_name CampaignsPannelContainer

const DEFAULT_CAMPAIGN_ROW_SCENE := preload("res://scenes/CampaignRow.tscn")

@export var campaign_row_scene: PackedScene

@onready var level_slots_container: HBoxContainer = $VBoxContainer/FilterRow/LevelSlotsContainer
@onready var campaign_list: VBoxContainer = $VBoxContainer/CampaignScrollContainer/CampaignList

var campaign_manager: CampaignManager = null
var region_manager = null
var current_region_id: String = ""


func setup(campaign_manager_ref: CampaignManager, region_manager_ref: Node) -> void:
	campaign_manager = campaign_manager_ref
	region_manager = region_manager_ref
	clear_rows()
	refresh_level_slots(null)


func show_region(region_id: String) -> void:
	current_region_id = region_id
	refresh()


func refresh() -> void:
	clear_rows()

	if campaign_manager == null:
		return

	for campaign in campaign_manager.get_available_campaigns(current_region_id):
		add_campaign_row(campaign)

	if region_manager != null:
		refresh_level_slots(region_manager.get_region_state(current_region_id))


func clear_rows() -> void:
	for child in campaign_list.get_children():
		child.queue_free()


func add_campaign_row(campaign: CampaignData) -> void:
	var scene := campaign_row_scene

	if scene == null:
		scene = preload("res://scenes/CampaignRow.tscn")

	var row := scene.instantiate() as CampaignRow

	if row == null:
		return

	campaign_list.add_child(row)

	var can_activate := campaign_manager.can_activate_campaign_id(current_region_id, campaign.id)
	row.setup(campaign, can_activate)

	row.activate_pressed.connect(_on_campaign_activate_pressed)


func refresh_level_slots(region_state: RegionState) -> void:
	var slot_labels := level_slots_container.get_children()
	var slots: Array[String] = []

	if region_state != null:
		slots = region_state.get_level_slots()

	for index in slot_labels.size():
		var label := slot_labels[index] as Label

		if label == null:
			continue

		label.text = ""

		if index >= slots.size():
			continue

		var slot_type := slots[index]

		if slot_type == "":
			label.text = "-"
		else:
			label.text = NodeTypeDefinitions.get_short_label(slot_type)


func _on_campaign_activate_pressed(campaign_id: String) -> void:
	if campaign_manager == null:
		return

	if campaign_manager.try_activate_campaign(current_region_id, campaign_id):
		refresh()
