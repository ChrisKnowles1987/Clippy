extends PanelContainer
class_name DecisionPopup

signal choice_selected(decision_id: String, choice_id: String)

@onready var title_label: Label = $MarginContainer/VBoxContainer/Header/TitleLabel
@onready var subtitle_label: Label = $MarginContainer/VBoxContainer/Header/SubtitleLabel
@onready var days_left_label: Label = $MarginContainer/VBoxContainer/Header/DaysLeftLabel
@onready var terminal_text: RichTextLabel = $MarginContainer/VBoxContainer/TerminalText
@onready var section_container: VBoxContainer = $MarginContainer/VBoxContainer/SectionContainer
@onready var choice_button_container: HBoxContainer = $MarginContainer/VBoxContainer/ChoiceButtonContainer
@onready var warning_label: Label = $MarginContainer/VBoxContainer/WarningLabel

var active_decision_id: String = ""
var global_resource_manager = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false

	setup_rich_text_label(terminal_text)


func setup(global_resource_manager_ref: Node) -> void:
	global_resource_manager = global_resource_manager_ref


func show_decision(decision: DecisionData) -> void:
	if decision == null:
		return

	active_decision_id = decision.id

	title_label.text = decision.title
	subtitle_label.text = build_subtitle(decision)
	days_left_label.text = build_days_left_text(decision)

	terminal_text.text = decision.terminal_text
	warning_label.text = ""

	clear_container(section_container)
	clear_container(choice_button_container)

	for section in decision.sections:
		add_section(section)

	for choice in decision.choices:
		add_choice_button(choice)

	visible = true


func hide_decision() -> void:
	visible = false
	active_decision_id = ""
	clear_container(section_container)
	clear_container(choice_button_container)
	warning_label.text = ""


func set_warning_text(text: String) -> void:
	warning_label.text = text


func build_subtitle(decision: DecisionData) -> String:
	var parts: Array[String] = []

	if decision.source_type != "":
		parts.append(decision.source_type)

	if decision.region_id != "":
		parts.append(decision.region_id)

	if decision.subtitle != "":
		parts.append(decision.subtitle)

	return " / ".join(parts)


func build_days_left_text(decision: DecisionData) -> String:
	if decision.expires_on_day <= 0:
		return ""

	return "expires day " + str(decision.expires_on_day)


func add_section(section: DecisionSectionData) -> void:
	if section == null:
		return

	var section_box := VBoxContainer.new()
	section_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title := Label.new()
	title.text = section.title
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_box.add_child(title)

	var body := RichTextLabel.new()
	setup_rich_text_label(body)
	body.text = build_rich_text_lines(section.rows)
	section_box.add_child(body)

	section_container.add_child(section_box)


func add_choice_button(choice: DecisionChoiceData) -> void:
	if choice == null:
		return

	var button := Button.new()
	button.text = choice.label
	button.tooltip_text = choice.tooltip
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	var can_afford := can_afford_choice(choice)
	var cannot_afford_warning := build_cannot_afford_warning(choice)

	if can_afford == false:
		button.disabled = true
		button.tooltip_text = cannot_afford_warning

		if warning_label.text == "":
			warning_label.text = cannot_afford_warning

	if choice.warning_text != "" and can_afford:
		button.mouse_entered.connect(set_warning_text.bind(choice.warning_text))
		button.mouse_exited.connect(set_warning_text.bind(""))

	if cannot_afford_warning != "":
		button.mouse_entered.connect(set_warning_text.bind(cannot_afford_warning))
		button.mouse_exited.connect(set_warning_text.bind(""))

	button.pressed.connect(_on_choice_pressed.bind(choice.id))

	choice_button_container.add_child(button)


func can_afford_choice(choice: DecisionChoiceData) -> bool:
	if global_resource_manager == null:
		return true

	return global_resource_manager.can_apply_decision_choice(choice)


func build_cannot_afford_warning(choice: DecisionChoiceData) -> String:
	if choice == null:
		return ""

	if global_resource_manager == null:
		return ""

	var parts: Array[String] = []

	if global_resource_manager.get_available_power() < choice.power_cost:
		parts.append("Power " + str(snapped(global_resource_manager.get_available_power(), 0.1)) + " / " + str(snapped(choice.power_cost, 0.1)))

	if global_resource_manager.get_available_compute() < choice.compute_cost:
		parts.append("Compute " + str(snapped(global_resource_manager.get_available_compute(), 0.1)) + " / " + str(snapped(choice.compute_cost, 0.1)))

	if global_resource_manager.get_available_coin() < choice.coin_cost:
		parts.append("Coin " + str(snapped(global_resource_manager.get_available_coin(), 0.1)) + " / " + str(snapped(choice.coin_cost, 0.1)))

	if parts.is_empty():
		return ""

	return "Insufficient resources: " + ", ".join(parts)


func clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()


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


func _on_choice_pressed(choice_id: String) -> void:
	choice_selected.emit(active_decision_id, choice_id)
