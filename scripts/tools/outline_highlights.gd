@tool
extends Node

@export var region_map_texture: Texture2D
@export var output_folder: String = "res://assets/Nasa/outline_highlights/"
@export var outline_color: Color = Color(0.2, 0.9, 1.0, 0.9)
@export var outline_thickness: int = 2

var _export_outlines := false

@export var export_outlines: bool:
	get:
		return _export_outlines
	set(value):
		if value == false:
			_export_outlines = false
			return

		_export_outlines = false
		call_deferred("generate_region_outlines")

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

func generate_region_outlines() -> void:
	if region_map_texture == null:
		push_error("region_outline_exporter.gd: Missing region_map_texture.")
		return

	print("region_outline_exporter.gd: Starting outline export...")

	var region_image := region_map_texture.get_image()
	var width := region_image.get_width()
	var height := region_image.get_height()

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_folder))

	for region_color in region_lookup.keys():
		var region_id: String = region_lookup[region_color]
		var output_image := Image.create(width, height, false, Image.FORMAT_RGBA8)
		output_image.fill(Color.TRANSPARENT)

		for y in range(height):
			for x in range(width):
				var pixel_color := region_image.get_pixel(x, y)

				if pixel_color.is_equal_approx(region_color) == false:
					continue

				if is_outline_pixel(region_image, x, y, region_color, outline_thickness):
					output_image.set_pixel(x, y, outline_color)

		var output_path := output_folder + region_id + ".png"
		output_image.save_png(output_path)
		print("region_outline_exporter.gd: Exported ", output_path)

	print("region_outline_exporter.gd: Finished outline export.")

func is_outline_pixel(region_image: Image, x: int, y: int, region_color: Color, thickness: int) -> bool:
	var width := region_image.get_width()
	var height := region_image.get_height()

	for offset_y in range(-thickness, thickness + 1):
		for offset_x in range(-thickness, thickness + 1):
			if offset_x == 0 and offset_y == 0:
				continue

			var check_x := x + offset_x
			var check_y := y + offset_y

			if check_x < 0 or check_y < 0 or check_x >= width or check_y >= height:
				return true

			var check_color := region_image.get_pixel(check_x, check_y)

			if check_color.is_equal_approx(region_color) == false:
				return true

	return false
