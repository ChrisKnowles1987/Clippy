@tool
extends Node2D

func _ready() -> void:
	set_notify_transform(true)
	_update_parent_line()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_update_parent_line()

func _update_parent_line() -> void:
	var socket := get_parent()

	if socket == null:
		return

	if socket.has_method("update_line"):
		socket.update_line()
