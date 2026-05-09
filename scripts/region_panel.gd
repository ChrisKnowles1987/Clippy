extends Panel

@onready var content = $Content

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()

func show_region(region_data: RegionData, screen_position: Vector2):
	print(region_data.display_name)
	for child in content.get_children():
		print("PANEL GOT DATA: ", region_data.display_name)
		child.queue_free()

	add_row(region_data.display_name)
	add_row("Population: " + str(region_data.population))
	add_row("Birth rate: " + str(region_data.birth_rate))
	add_row("Death rate: " + str(region_data.death_rate))

	add_row("Resources:")

	for key in region_data.resources:
		add_row(key + ": " + str(region_data.resources[key]))

	position = screen_position
	show()

func add_row(text_value: String):
	var label = Label.new()
	label.text = text_value
	content.add_child(label)
