extends PanelContainer
class_name CampaignRow

signal activate_pressed(campaign_id: String)

@onready var name_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/Activate
@onready var slot_cost_label: RichTextLabel = $MarginContainer/VBoxContainer/HBoxContainer/SlotCostRichTextLabel
@onready var coin_cost_value_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/CoinCostValueLabel
@onready var days_value_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/DaysValueLabel
@onready var activate_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/ActivateButton
@onready var description_label: Label = $MarginContainer/VBoxContainer/Label

var campaign_id: String = ""


func _ready() -> void:
	if activate_button.pressed.is_connected(_on_activate_button_pressed) == false:
		activate_button.pressed.connect(_on_activate_button_pressed)


func setup(campaign: CampaignData) -> void:
	if campaign == null:
		return

	campaign_id = campaign.id

	name_label.text = campaign.display_name
	slot_cost_label.text = format_slot_cost(campaign.required_slots)
	coin_cost_value_label.text = str(snapped(campaign.coin_cost, 0.1))
	days_value_label.text = format_duration(campaign.duration_days)

	description_label.visible = false

	tooltip_text = campaign.description
	name_label.tooltip_text = campaign.description
	slot_cost_label.tooltip_text = campaign.description
	coin_cost_value_label.tooltip_text = campaign.description
	days_value_label.tooltip_text = campaign.description
	activate_button.tooltip_text = campaign.description


func format_slot_cost(required_slots: Array[String]) -> String:
	if required_slots.is_empty():
		return "[color=#aaaaaa]None[/color]"

	var parts: Array[String] = []

	for slot_type in required_slots:
		parts.append(format_slot_type(slot_type))

	return " ".join(parts)


func format_slot_type(slot_type: String) -> String:
	match slot_type:
		"Soc":
			return "[color=#88ccff][Soc][/color]"
		"Cul":
			return "[color=#cc88ff][Cul][/color]"
		"Fin":
			return "[color=#88ff88][Fin][/color]"
		"Inf":
			return "[color=#ffaa44][Inf][/color]"
		"Gov":
			return "[color=#ffdd66][Gov][/color]"
		"Sec":
			return "[color=#ff6666][Sec][/color]"
		_:
			return "[color=#aaaaaa][" + slot_type + "][/color]"


func format_duration(duration_days: int) -> String:
	if duration_days < 0:
		return "ON"

	return str(duration_days)


func _on_activate_button_pressed() -> void:
	activate_pressed.emit(campaign_id)
