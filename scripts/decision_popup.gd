extends PanelContainer
class_name DecisionPopup

signal choice_selected(hack_node_id: String, choice_id: String)

@onready var hero_image: TextureRect = $MarginContainer/VBoxContainer/DecisionHeroImage

@onready var region_id_label: Label = $"MarginContainer/VBoxContainer/Title row/RegionIDLabel"
@onready var decision_id_label: Label = $"MarginContainer/VBoxContainer/Title row/DecisionIDLabel"
@onready var days_left_label: Label = $"MarginContainer/VBoxContainer/Title row/DaysLeftVariableLabel"

@onready var cost_items_container: HBoxContainer = $"MarginContainer/VBoxContainer/Cost container/CostItemsContainer"


@onready var hack_node_terminal: RichTextLabel = $MarginContainer/VBoxContainer/HackNodeTerminal
@onready var success_chance_label: Label = $MarginContainer/VBoxContainer/SuccessChanceContainer/SuccessChanceVariableLabel
@onready var success_item_container: HBoxContainer = $MarginContainer/VBoxContainer/OutcomeContainer/VBoxContainer/SuccessItemContainer
@onready var failure_item_container: VBoxContainer = $MarginContainer/VBoxContainer/OutcomeContainer/VBoxContainer2/FailItemContainer


@onready var warning_label: Label = $MarginContainer/VBoxContainer/WarningLabel

@onready var proceed_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/Proceed
@onready var defer_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/Defer
@onready var cancel_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/Cancel

var active_hack_node_id: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false

	hack_node_terminal.bbcode_enabled = true

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

	success_chance_label.text = str(snapped(hack_node.success_chance * 100.0, 0.1))

	rebuild_text_items(cost_items_container, cost_items)
	rebuild_text_items(success_item_container, success_outcomes)
	rebuild_text_items(failure_item_container, failure_outcomes)

	warning_label.text = ""

	visible = true


func hide_decision() -> void:
	visible = false
	active_hack_node_id = ""


func set_warning_text(text: String) -> void:
	warning_label.text = text


func rebuild_text_items(container: Container, items: Array[String]) -> void:
	for child in container.get_children():
		child.queue_free()

	for item in items:
		var label := RichTextLabel.new()
		label.bbcode_enabled = true
		label.fit_content = true
		label.scroll_active = false
		label.text = item
		container.add_child(label)


func _on_proceed_pressed() -> void:
	choice_selected.emit(active_hack_node_id, "execute")


func _on_defer_pressed() -> void:
	choice_selected.emit(active_hack_node_id, "defer")


func _on_cancel_pressed() -> void:
	choice_selected.emit(active_hack_node_id, "ignore")
