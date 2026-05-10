extends Panel

@onready var content = $MarginContainer/Content

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_empty()

func show_empty():
	clear_content()
	add_row("No region selected")
	show()

func show_region(region_data: RegionData):
	clear_content()
	for child in content.get_children():
		child.queue_free()
	for property in region_data.get_property_list():
		if not  (property.usage  & PROPERTY_USAGE_SCRIPT_VARIABLE) :
			continue
		var property_name = String(property.name)
		
		if property_name == 'id':
			continue
		
		var value = region_data.get(property_name)
		
		if property_name == 'display_name':
			add_row(str(value))
		else:
			add_row(property_name.capitalize() + ": " + str(value))

	show()
	
func clear_content():
	for child in content.get_children():
		child.queue_free()
		
func add_row(text_value: String):
	var label = Label.new()
	label.text = text_value
	content.add_child(label)
