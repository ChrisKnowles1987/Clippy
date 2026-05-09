extends Node2D

@onready var region_map = $RegionMap
@onready var label = $CanvasLayer/RegionLabel

var region_image: Image
var hovered_region = ""
var selected_region = ""

var region_lookup = {
	Color8(230, 25, 75): "North America",
	Color8(245, 130, 48): "Central America & Caribbean",
	Color8(255, 225, 25): "South America",
	Color8(60, 180, 75): "Western Europe",
	Color8(70, 240, 240): "Eastern Europe",
	Color8(0, 130, 200): "Russia & Central Asia",
	Color8(145, 30, 180): "Middle East",
	Color8(240, 50, 230): "North Africa",
	Color8(210, 245, 60): "West Africa",
	Color8(250, 190, 190): "East Africa",
	Color8(0, 128, 128): "Southern Africa",
	Color8(230, 190, 255): "India",
	Color8(170, 110, 40): "China",
	Color8(255, 250, 200): "Japan & Korea",
	Color8(128, 0, 0): "Southeast Asia",
	Color8(170, 255, 195): "Oceania",
	Color8(128, 128, 128): "Antarctica"
}

func _ready():
	region_image = region_map.texture.get_image()
	label.text = "Hover a region"

func _process(_delta):
	var region = get_region_under_mouse()

	if region != hovered_region:
		hovered_region = region
		
		if selected_region == "":
			label.text = hovered_region if hovered_region != "" else "Ocean"
		else:
			label.text = "Selected: " + selected_region + "\nHover: " + (hovered_region if hovered_region != "" else "Ocean")

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected_region = get_region_under_mouse()
		
		if selected_region == "":
			label.text = "Selected: Ocean"
		else:
			label.text = "Selected: " + selected_region

func get_region_under_mouse() -> String:
	var local_pos = region_map.to_local(get_global_mouse_position())
	var texture_size = region_map.texture.get_size()

	var x = int(local_pos.x + texture_size.x / 2.0)
	var y = int(local_pos.y + texture_size.y / 2.0)

	if x < 0 or y < 0 or x >= region_image.get_width() or y >= region_image.get_height():
		return ""

	var clicked_color = region_image.get_pixel(x, y)

	if clicked_color == Color.BLACK:
		return ""

	for color in region_lookup:
		if clicked_color.is_equal_approx(color):
			return region_lookup[color]

	return ""
