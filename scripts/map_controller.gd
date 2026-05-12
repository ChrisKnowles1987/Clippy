extends Node2D

@onready var region_map = $RegionMap
@onready var highlight_map = $HighlightMap
@onready var region_panel = $"../CanvasLayer/RegionPanel"

var region_ids = {
	"North America": "north_america",
	"South America": "south_america",
	"Europe": "europe",
	"Russia & Central Asia": "russia_central_asia",
	"Middle East": "middle_east",
	"North Africa": "north_africa",
	"West Africa": "west_africa",
	"East Africa": "east_africa",
	"Southern Africa": "southern_africa",
	"India": "india",
	"China": "china",
	"Japan & Korea": "japan_korea",
	"Southeast Asia": "southeast_asia",
	"Oceania": "oceania"
}

signal region_selected(region_id: String, mouse_position: Vector2)

var region_image: Image
var hovered_region := ""
var selected_region := ""

var region_lookup = {
	Color8(230, 25, 75): "North America",
	Color8(255, 225, 25): "South America",
	Color8(60, 180, 75): "Europe",
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
}

var highlight_textures := {}
var highlight_color := Color(0.2, 0.85, 1.0, 0.65)

func _ready() -> void:
	print("map controller ready")
	set_process_input(true)

	region_image = region_map.texture.get_image()

	highlight_map.visible = false
	highlight_map.texture = null
	highlight_map.modulate = Color.WHITE

	build_highlight_textures()


func _process(_delta: float) -> void:
	var region := get_region_under_mouse()

	if region != hovered_region:
		hovered_region = region
		update_highlight(hovered_region)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected_region = get_region_under_mouse()

		if region_ids.has(selected_region):
			var region_id = region_ids[selected_region]
			region_selected.emit(region_id, get_viewport().get_mouse_position())
		else:
			region_selected.emit("", get_viewport().get_mouse_position())


func get_region_under_mouse() -> String:
	var local_pos = region_map.to_local(get_global_mouse_position())
	var texture_size = region_map.texture.get_size()

	var x := int(local_pos.x + texture_size.x / 2.0)
	var y := int(local_pos.y + texture_size.y / 2.0)

	if x < 0 or y < 0 or x >= region_image.get_width() or y >= region_image.get_height():
		return ""

	var clicked_color := region_image.get_pixel(x, y)

	if clicked_color == Color.BLACK:
		return ""

	for color in region_lookup:
		if clicked_color.is_equal_approx(color):
			return region_lookup[color]

	return ""


func build_highlight_textures() -> void:
	for region_color in region_lookup:
		var region_name: String = region_lookup[region_color]

		var highlight_image := Image.create(
			region_image.get_width(),
			region_image.get_height(),
			false,
			Image.FORMAT_RGBA8
		)

		for y in region_image.get_height():
			for x in region_image.get_width():
				var pixel_color := region_image.get_pixel(x, y)

				if pixel_color.is_equal_approx(region_color):
					highlight_image.set_pixel(x, y, highlight_color)
				else:
					highlight_image.set_pixel(x, y, Color.TRANSPARENT)

		highlight_textures[region_name] = ImageTexture.create_from_image(highlight_image)


func update_highlight(region_name: String) -> void:
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
