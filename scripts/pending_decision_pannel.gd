extends PanelContainer
class_name PendingDecisionPannel

signal pending_decision_selected(hack_node_id: String)

@onready var count_label: Label = $MarginContainer/VBoxContainer/TitleRow/PendingEventsVariableLabel
@onready var pending_list: RichTextLabel = $MarginContainer/VBoxContainer/RichTextLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false

	pending_list.bbcode_enabled = true
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
	pending_decision_selected.emit(str(meta))
