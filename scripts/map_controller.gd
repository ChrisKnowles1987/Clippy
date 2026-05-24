extends Node2D

@onready var region_map: Sprite2D = $RegionMap
@onready var scan_overlay_layer: Node2D = $ScanOverlayMap
@onready var selected_highlight_map: Sprite2D = $SelectedHighlightMap
@onready var hover_highlight_map: Sprite2D = $HoverHighlightMap


signal region_selected(region_id: String, mouse_position: Vector2)

var region_ids = {
	"North America": "north_america",
	"Central America & Caribbean": "central_america_caribbean",
	"South America": "south_america",
	"Western Europe": "western_europe",
	"Eastern Europe": "eastern_europe",
	"Russia & Central Asia": "russia_central_asia",
	"Middle East": "middle_east",
	"North Africa": "north_africa",
	"West Africa": "west_africa",
	"East Africa": "east_africa",
	"Southern Africa": "southern_africa",
	"India": "india",
	"China": "china",
	"East Asia": "east_asia",
	"Southeast Asia": "southeast_asia",
	"Oceania": "oceania"
}

var region_lookup = {
	Color8(230, 25, 75): "north_america",
	Color8(245, 130, 48): "central_america_caribbean",
	Color8(255, 225, 25): "south_america",
	Color8(60, 180, 75): "western_europe",
	Color8(0, 200, 80): "eastern_europe",
	Color8(0, 130, 200): "russia_central_asia",
	Color8(145, 30, 180): "middle_east",
	Color8(70, 240, 240): "north_africa",
	Color8(210, 245, 60): "west_africa",
	Color8(250, 190, 190): "east_africa",
	Color8(0, 128, 128): "southern_africa",
	Color8(230, 190, 255): "india",
	Color8(170, 110, 40): "china",
	Color8(255, 215, 180): "east_asia",
	Color8(128, 0, 0): "southeast_asia",
	Color8(170, 255, 195): "oceania",
}

var region_image: Image
var hovered_region_id: String = ""
var selected_region_id: String = ""
var scanned_region_ids: Array[String] = []

func _ready() -> void:
	print("map controller ready")
	set_process_input(true)

	region_image = region_map.texture.get_image()

	selected_highlight_map.texture = null
	hover_highlight_map.texture = null

	update_region_overlays()

func _process(_delta: float) -> void:
	var region_id := get_region_under_mouse()

	if region_id != hovered_region_id:
		hovered_region_id = region_id
		update_region_overlays()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked_region_id := get_region_under_mouse()

		if clicked_region_id != "":
			selected_region_id = clicked_region_id
			update_region_overlays()
			region_selected.emit(clicked_region_id, get_viewport().get_mouse_position())
		else:
			selected_region_id = ""
			update_region_overlays()
			region_selected.emit("", get_viewport().get_mouse_position())
			
func set_map_view(view_name: String) -> void:
	var infiltration_view := view_name == "infiltration"
	var expansion_view := view_name == "expansion"

	$WorldMap.visible = expansion_view
	$PopDensityMap.visible = infiltration_view

	$ScanOverlayMap.visible = infiltration_view
	$HackNodeLayer.visible = infiltration_view

	$SelectedHighlightMap.visible = true
	$HoverHighlightMap.visible = true

func _set_overlay_texture(sprite: Sprite2D, folder_path: String, region_id: String) -> void:
	if region_id == "":
		sprite.texture = null
		return

	var texture_path := "%s/%s.png" % [folder_path, region_id]

	if ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
	else:
		sprite.texture = null

func update_region_overlays() -> void:
	update_scan_overlay_layer()

	_set_overlay_texture(
		selected_highlight_map,
		"res://assets/Nasa/selected_highlights",
		selected_region_id
	)

	_set_overlay_texture(
		hover_highlight_map,
		"res://assets/Nasa/outline_highlights",
		hovered_region_id
	)

func update_scan_overlay_layer() -> void:
	for child in scan_overlay_layer.get_children():
		child.queue_free()

	for region_id in scanned_region_ids:
		var texture_path := "res://assets/Nasa/scan_overlays/%s.png" % region_id

		if ResourceLoader.exists(texture_path) == false:
			continue

		var sprite := Sprite2D.new()
		sprite.texture = load(texture_path)
		sprite.position = Vector2.ZERO
		sprite.scale = Vector2.ONE
		sprite.rotation = 0.0
		sprite.centered = region_map.centered
		sprite.modulate = Color.WHITE

		scan_overlay_layer.add_child(sprite)

func get_region_under_mouse() -> String:
	var local_pos := region_map.to_local(get_global_mouse_position())
	var texture_size := region_map.texture.get_size()

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

func set_scanned_region(region_id: String) -> void:
	if region_id == "":
		return

	if scanned_region_ids.has(region_id) == false:
		scanned_region_ids.append(region_id)

	update_region_overlays()

func clear_scanned_region(region_id: String) -> void:
	if scanned_region_ids.has(region_id):
		scanned_region_ids.erase(region_id)
		update_region_overlays()

func set_persistent_region(region_id: String) -> void:
	set_scanned_region(region_id)

func clear_persistent_region(region_id: String) -> void:
	clear_scanned_region(region_id)
