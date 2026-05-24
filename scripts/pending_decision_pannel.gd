extends PanelContainer
class_name PendingDecisionPannel

signal pending_decision_selected(decision_id: String)

@onready var count_label: Label = $MarginContainer/VBoxContainer/TitleRow/PendingEventsVariableLabel
@onready var pending_list: RichTextLabel = $MarginContainer/VBoxContainer/RichTextLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP

	visible = false

	pending_list.process_mode = Node.PROCESS_MODE_ALWAYS
	pending_list.mouse_filter = Control.MOUSE_FILTER_STOP
	pending_list.bbcode_enabled = true
	pending_list.selection_enabled = false
	pending_list.scroll_active = false

	if pending_list.meta_clicked.is_connected(_on_pending_list_meta_clicked) == false:
		pending_list.meta_clicked.connect(_on_pending_list_meta_clicked)


func update_pending_decisions(lines: Array[String], count: int) -> void:
	count_label.text = str(count)

	if count <= 0:
		pending_list.text = ""
		visible = false
		return

	pending_list.text = "\n".join(lines)
	visible = true


func _on_pending_list_meta_clicked(meta: Variant) -> void:
	print("Pending decision clicked: ", str(meta))
	pending_decision_selected.emit(str(meta))