extends Node

@export var provinces_file_path: String = "res://assets/opengs_map_data/Provinces.txt"
@export var province_map_texture: Texture2D
@export var map_sprite: Sprite2D

var land_spawn_points: Array[Dictionary] = []

func _ready() -> void:
	load_spawn_points()

func load_spawn_points() -> void:
	land_spawn_points.clear()

	if province_map_texture == null:
		push_error("ProvinceSpawnManager needs province_map_texture assigned.")
		return

	if map_sprite == null:
		push_error("ProvinceSpawnManager needs map_sprite assigned.")
		return

	if map_sprite.texture == null:
		push_error("ProvinceSpawnManager map_sprite has no texture.")
		return

	var land_colors := load_land_province_colors()

	if land_colors.is_empty():
		push_error("No land province colors loaded.")
		return

	var province_image := province_map_texture.get_image()
	var province_sums := {}
	var province_counts := {}

	for y in province_image.get_height():
		for x in province_image.get_width():
			var pixel_color := province_image.get_pixel(x, y)
			var color_key := color_to_key(pixel_color)

			if not land_colors.has(color_key):
				continue

			if not province_sums.has(color_key):
				province_sums[color_key] = Vector2.ZERO
				province_counts[color_key] = 0

			province_sums[color_key] += Vector2(x, y)
			province_counts[color_key] += 1

	var texture_size := province_map_texture.get_size()
	var map_texture_size := map_sprite.texture.get_size()
	var scale_factor := map_texture_size / texture_size

	for color_key in province_sums.keys():
		var count: int = province_counts[color_key]

		if count <= 0:
			continue

		var province_center: Vector2 = province_sums[color_key] / count
		var scaled_center := province_center * scale_factor
		var local_position := scaled_center - (map_texture_size / 2.0)
		var map_position := map_sprite.position + (local_position * map_sprite.scale)

		land_spawn_points.append({
			"color_key": color_key,
			"position": map_position
		})

func load_land_province_colors() -> Dictionary:
	var land_colors := {}
	var file := FileAccess.open(provinces_file_path, FileAccess.READ)

	if file == null:
		push_error("Could not open Provinces.txt at: " + provinces_file_path)
		return land_colors

	while not file.eof_reached():
		var line := file.get_line().strip_edges()

		if line == "":
			continue

		var columns := line.split(",")

		if columns.size() < 5:
			continue

		var province_type := columns[4]

		if province_type != "land":
			continue

		var red := int(columns[1])
		var green := int(columns[2])
		var blue := int(columns[3])
		var color_key := "%d,%d,%d" % [red, green, blue]

		land_colors[color_key] = true

	return land_colors

func color_to_key(color: Color) -> String:
	return "%d,%d,%d" % [
		int(round(color.r * 255.0)),
		int(round(color.g * 255.0)),
		int(round(color.b * 255.0))
	]

func get_random_spawn_position() -> Vector2:
	if land_spawn_points.is_empty():
		return Vector2.ZERO

	var spawn_point: Dictionary = land_spawn_points.pick_random()
	return spawn_point["position"]
