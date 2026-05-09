extends Node2D

@onready var region_map = $RegionMap
@onready var label = $CanvasLayer/RegionLabel
@onready var highlight_map = $HighlightMap

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

var highlight_textures = {
	"North America": preload("res://assets/maps/highlights/north_america_highlight.png"),
	"Central America & Caribbean": preload("res://assets/maps/highlights/central_america_caribbean_highlight.png"),
	"South America": preload("res://assets/maps/highlights/south_america_highlight.png"),
	"Western Europe": preload("res://assets/maps/highlights/western_europe_highlight.png"),
	"Eastern Europe": preload("res://assets/maps/highlights/eastern_europe_highlight.png"),
	"Russia & Central Asia": preload("res://assets/maps/highlights/russia_central_asia_highlight.png"),
	"Middle East": preload("res://assets/maps/highlights/middle_east_highlight.png"),
	"North Africa": preload("res://assets/maps/highlights/north_africa_highlight.png"),
	"West Africa": preload("res://assets/maps/highlights/west_africa_highlight.png"),
	"East Africa": preload("res://assets/maps/highlights/east_africa_highlight.png"),
	"Southern Africa": preload("res://assets/maps/highlights/southern_africa_highlight.png"),
	"India": preload("res://assets/maps/highlights/india_highlight.png"),
	"China": preload("res://assets/maps/highlights/china_highlight.png"),
	"Japan & Korea": preload("res://assets/maps/highlights/japan_korea_highlight.png"),
	"Southeast Asia": preload("res://assets/maps/highlights/southeast_asia_highlight.png"),
	"Oceania": preload("res://assets/maps/highlights/oceania_highlight.png"),
	"Antarctica": preload("res://assets/maps/highlights/antarctica_highlight.png")
}

func _ready():
	region_image = region_map.texture.get_image()
	label.text = "Hover a region"
	highlight_map.visible = false
	highlight_map.modulate = Color(1, 1, 1, 0.6)

func _process(_delta):
	var region = get_region_under_mouse()

	if region != hovered_region:
		hovered_region = region
		update_highlight(hovered_region)
		
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

func update_highlight(region_name: String):
	if region_name == "":
		highlight_map.visible = false
		highlight_map.texture = null
		return

	if highlight_textures.has(region_name):
		highlight_map.texture = highlight_textures[region_name]
		highlight_map.visible = true
	else:
		highlight_map.visible = false
		highlight_map.texture = null
