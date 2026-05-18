extends PanelContainer
class_name DecisionPopup

signal choice_selected(hack_node_id: String, choice_id: String)

@onready var hero_image: TextureRect = $MarginContainer/VBoxContainer/DecisionHeroImage

@onready var region_id_label: Label = $"MarginContainer/VBoxContainer/Title row/RegionIDLabel"
@onready var decision_id_label: Label = $"MarginContainer/VBoxContainer/Title row/DecisionIDLabel"
@onready var days_left_label: Label = $"MarginContainer/VBoxContainer/Title row/DaysLeftVariableLabel"

@onready var hack_node_terminal: RichTextLabel = $MarginContainer/VBoxContainer/HackNodeTerminal

@onready var cost_rich_text: RichTextLabel = $"MarginContainer/VBoxContainer/Cost container/CostRichTextLabel"
@onready var success_outcome_rich_text: RichTextLabel = $MarginContainer/VBoxContainer/OutcomeContainer/VBoxContainer/SuccessOutcomeRichTextLabel
@onready var failure_outcome_rich_text: RichTextLabel = $MarginContainer/VBoxContainer/OutcomeContainer/VBoxContainer2/FailureOutcomeRichTextLabel

@onready var success_chance_label: Label = $MarginContainer/VBoxContainer/SuccessChanceContainer/SuccessChanceVariableLabel

@onready var warning_label: Label = $MarginContainer/VBoxContainer/WarningLabel

@onready var proceed_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/Proceed
@onready var defer_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/Defer
@onready var cancel_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/Cancel

var active_hack_node_id: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false

	setup_rich_text_label(hack_node_terminal)
	setup_rich_text_label(cost_rich_text)
	setup_rich_text_label(success_outcome_rich_text)
	setup_rich_text_label(failure_outcome_rich_text)

	proceed_button.pressed.connect(_on_proceed_pressed)
	defer_button.pressed.connect(_on_defer_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)


func show_decision(
	hack_node: HackNodeData,
	terminal_line: String,
	cost_items: Array[String],
	success_outcomes: Array[String],
	failure_outcomes: Array[String],
	days_left: int
) -> void:
	if hack_node == null:
		return

	active_hack_node_id = hack_node.id

	region_id_label.text = hack_node.region_id
	decision_id_label.text = hack_node.id
	days_left_label.text = str(days_left) + " days left"

	hack_node_terminal.text = terminal_line
	cost_rich_text.text = build_rich_text_lines(cost_items)
	success_outcome_rich_text.text = build_rich_text_lines(success_outcomes)
	failure_outcome_rich_text.text = build_rich_text_lines(failure_outcomes)

	success_chance_label.text = str(snapped(hack_node.success_chance * 100.0, 0.1))
	warning_label.text = ""

	visible = true


func hide_decision() -> void:
	visible = false
	active_hack_node_id = ""


func set_warning_text(text: String) -> void:
	warning_label.text = text


func setup_rich_text_label(label: RichTextLabel) -> void:
	if label == null:
		return

	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.custom_minimum_size = Vector2.ZERO
	label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN


func build_rich_text_lines(items: Array[String]) -> String:
	if items.is_empty():
		return "[color=#999999]None[/color]"

	return "\n".join(items)


func _on_proceed_pressed() -> void:
	choice_selected.emit(active_hack_node_id, "execute")


func _on_defer_pressed() -> void:
	choice_selected.emit(active_hack_node_id, "defer")


func _on_cancel_pressed() -> void:
	choice_selected.emit(active_hack_node_id, "ignore")
