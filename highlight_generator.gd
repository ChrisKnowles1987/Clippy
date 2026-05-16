@tool
extends Node

@export var export_overlays := false

@export var region_map_texture: Texture2D
@export var density_texture: Texture2D

@export var output_dir := "res://assets/Nasa/highlights/"

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


func _process(_delta: float) -> void:
	if export_overlays == false:
		return

	export_overlays = false
	export_region_overlays()


func export_region_overlays() -> void:
	print("=== REGION OVERLAY EXPORT START ===")

	if region_map_texture == null:
		push_error("No region map texture assigned")
		return

	if density_texture == null:
		push_error("No density texture assigned")
		return

	var region_image := region_map_texture.get_image()
	var density_image := density_texture.get_image()

	if region_image.get_size() != density_image.get_size():
		push_error("Region map and density texture must be same size")
		return

	print("Image size: ", region_image.get_width(), " x ", region_image.get_height())

	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(output_dir)
	)

	for region_color in region_lookup:
		var region_id: String = region_lookup[region_color]

		print("Processing region: ", region_id)

		var output_image := Image.create(
			region_image.get_width(),
			region_image.get_height(),
			false,
			Image.FORMAT_RGBA8
		)

		output_image.fill(Color.TRANSPARENT)

		for y in range(region_image.get_height()):
			if y % 250 == 0:
				print(region_id, " row: ", y)

			for x in range(region_image.get_width()):
				var pixel_color := region_image.get_pixel(x, y)

				if pixel_color.is_equal_approx(region_color):
					var density_pixel := density_image.get_pixel(x, y)
					density_pixel.a = 1.0
					output_image.set_pixel(x, y, density_pixel)

		var save_path := output_dir + region_id + ".png"
		var result := output_image.save_png(save_path)

		print("Saved: ", save_path)
		print("Save result: ", result)

	print("=== REGION OVERLAY EXPORT COMPLETE ===")
