extends PanelContainer
class_name CampaignRow

signal activate_pressed(campaign_id: String)

@onready var name_label: Label = get_node("MarginContainer/VBoxContainer/HBoxContainer/Activate")
@onready var slot_cost_label: RichTextLabel = get_node("MarginContainer/VBoxContainer/HBoxContainer/SlotCostRichTextLabel")
@onready var coin_cost_value_label: Label = get_node("MarginContainer/VBoxContainer/HBoxContainer/CoinCostValueLabel")
@onready var days_value_label: Label = get_node("MarginContainer/VBoxContainer/HBoxContainer/DaysValueLabel")
@onready var activate_button: Button = get_node("MarginContainer/VBoxContainer/HBoxContainer/ActivateButton")
@onready var description_label: Label = get_node("MarginContainer/VBoxContainer/HBoxContainer2/CampaignDescriptionLabel")
@onready var min_req_label: Label = get_node("MarginContainer/VBoxContainer/HBoxContainer2/MinReqLabel")

var campaign_id: String = ""


func _ready() -> void:
	activate_button.pressed.connect(_on_activate_button_pressed)


func setup(campaign: CampaignData, can_activate: bool) -> void:
	campaign_id = campaign.id

	name_label.text = campaign.display_name
	slot_cost_label.text = format_slot_cost(campaign.required_slots)
	coin_cost_value_label.text = str(snapped(campaign.coin_cost, 0.1))
	days_value_label.text = format_duration(campaign.duration_days)
	description_label.text = campaign.description
	description_label.visible = true
	min_req_label.text = format_min_requirements(campaign)

	activate_button.disabled = can_activate == false
	activate_button.text = "Activate" if can_activate else "Locked"

	tooltip_text = ""
	name_label.tooltip_text = ""
	slot_cost_label.tooltip_text = ""
	coin_cost_value_label.tooltip_text = ""
	days_value_label.tooltip_text = ""
	activate_button.tooltip_text = ""
	description_label.tooltip_text = ""
	min_req_label.tooltip_text = ""


func format_slot_cost(required_slots: Array[String]) -> String:
	var parts: Array[String] = []

	for slot_type in required_slots:
		parts.append(NodeTypeDefinitions.format_short_tag(slot_type))

	return " ".join(parts)


func format_min_requirements(campaign: CampaignData) -> String:
	var parts: Array[String] = []

	append_min_requirement(parts, NodeTypeDefinitions.SOCIAL, campaign.min_soc)
	append_min_requirement(parts, NodeTypeDefinitions.CULTURAL, campaign.min_cul)
	append_min_requirement(parts, NodeTypeDefinitions.FINANCIAL, campaign.min_fin)
	append_min_requirement(parts, NodeTypeDefinitions.INFRASTRUCTURE, campaign.min_inf)
	append_min_requirement(parts, NodeTypeDefinitions.GOVERNMENT, campaign.min_gov)
	append_min_requirement(parts, NodeTypeDefinitions.SECURITY, campaign.min_sec)

	if parts.is_empty():
		return "Req: none"

	return "Req: " + " ".join(parts)


func append_min_requirement(parts: Array[String], node_type: String, required_level: int) -> void:
	if required_level <= 0:
		return

	parts.append(NodeTypeDefinitions.get_short_label(node_type) + " " + str(required_level))


func format_duration(duration_days: int) -> String:
	if duration_days < 0:
		return "ON"

	return str(duration_days)


func _on_activate_button_pressed() -> void:
	activate_pressed.emit(campaign_id)
