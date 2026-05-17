extends Panel

@onready var content = $MarginContainer/Content

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_empty()

func show_empty() -> void:
	clear_content()
	add_row("No region selected")
	show()

func show_region(region_data: RegionData, region_state: RegionState) -> void:
	clear_content()

	if region_data == null:
		add_row("No region selected")
		show()
		return

	if region_state == null:
		add_row(region_data.display_name)
		add_row("")
		add_row("No region state found")
		show()
		return

	add_row(region_data.display_name)
	add_row("")

	add_row("Cities: " + str(region_data.cities.size()))

	add_row("")
	add_row("Intelligence: %.1f%%" % region_state.intelligence_percent)
	add_row("Influence Level: " + str(region_state.influence_level))

	add_row("")
	add_row("Infiltration: " + get_enabled_text(region_state.infiltration_enabled))
	add_row("Reserved Power: %.1f" % region_state.infiltration_reserved_power)
	add_row("Reserved Compute: %.1f" % region_state.infiltration_reserved_compute)

	add_row("")
	add_row("Notoriety: %.1f" % region_state.notoriety)
	add_row("Shutdown Progress: %.1f" % region_state.shutdown_progress)

	show()

func clear_content() -> void:
	for child in content.get_children():
		child.queue_free()

func add_row(text_value: String) -> void:
	var label := Label.new()
	label.text = text_value
	content.add_child(label)

func get_enabled_text(enabled: bool) -> String:
	if enabled:
		return "Online"

	return "Offline"
