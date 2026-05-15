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

	add_row(region_data.display_name)
	add_row("")

	add_row("Cities: " + str(region_data.cities.size()))

	add_row("")
	add_row("Intelligence: %.1f%%" % region_state.intelligence_percent)
	add_row("Influence Level: " + str(region_state.influence_level))

	add_row("")
	add_row("Blue Power: %.1f" % region_state.blue_power)
	add_row("Blue Compute: %.1f" % region_state.blue_compute)

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
