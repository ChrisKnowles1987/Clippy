@tool
extends Node

const CITY_CSV_PATH := "res://data/Natural_earth_coords/natural_earth_major_city_coordinates_with_regions_and_weights_clean_social.csv"

@export var socket_scene: PackedScene
@export var sockets_per_region: int = 10
@export var clear_existing_sockets: bool = false
@export var minimum_box_spacing: float = 35.0

@export var generate_sockets: bool = false:
	set(value):
		generate_sockets = false
		if value:
			generate()

var placed_box_positions: Array[Vector2] = []

var candidate_offsets: Array[Vector2] = [
	Vector2(0, -35),
	Vector2(8, -34),
	Vector2(16, -31),
	Vector2(24, -26),
	Vector2(30, -18),
	Vector2(34, -9),
	Vector2(35, 0),
	Vector2(34, 9),
	Vector2(30, 18),
	Vector2(24, 26),
	Vector2(16, 31),
	Vector2(8, 34),

	Vector2(0, -50),
	Vector2(12, -48),
	Vector2(23, -44),
	Vector2(34, -36),
	Vector2(43, -25),
	Vector2(48, -13),
	Vector2(50, 0),
	Vector2(48, 13),
	Vector2(43, 25),
	Vector2(34, 36),
	Vector2(23, 44),
	Vector2(12, 48),

	Vector2(0, -65),
	Vector2(16, -63),
	Vector2(30, -58),
	Vector2(44, -47),
	Vector2(56, -33),
	Vector2(63, -17),
	Vector2(65, 0),
	Vector2(63, 17),
	Vector2(56, 33),
	Vector2(44, 47),
	Vector2(30, 58),
	Vector2(16, 63)
]

func generate() -> void:
	if socket_scene == null:
		push_error("expansion_socket_generator.gd: No socket_scene assigned.")
		return

	placed_box_positions.clear()

	if clear_existing_sockets:
		clear_sockets()

	var cities_by_region := load_cities_by_region()

	for region_id in cities_by_region:
		generate_region_sockets(region_id, cities_by_region[region_id])

func load_cities_by_region() -> Dictionary:
	var cities_by_region := {}

	var file := FileAccess.open(CITY_CSV_PATH, FileAccess.READ)

	if file == null:
		push_error("expansion_socket_generator.gd: Could not open city CSV.")
		return cities_by_region

	file.get_line()

	while not file.eof_reached():
		var columns := file.get_csv_line()

		if columns.is_empty():
			continue

		if columns.size() < 28:
			continue

		var city := {
			"id": columns[1].to_lower().replace(" ", "_"),
			"display_name": columns[0],
			"region_id": columns[20],
			"map_position": Vector2(
				960.0 + float(columns[16]),
				540.0 + float(columns[17])
			),
			"population_weight": float(columns[21])
		}

		var region_id: String = city["region_id"]

		if cities_by_region.has(region_id) == false:
			cities_by_region[region_id] = []

		cities_by_region[region_id].append(city)

	return cities_by_region

func clear_sockets() -> void:
	for child in get_parent().get_children():
		if child == self:
			continue

		if child.has_method("update_line"):
			child.queue_free()

func generate_region_sockets(region_id: String, cities: Array) -> void:
	if cities.is_empty():
		return

	cities.sort_custom(_sort_city_by_population_desc)

	var count: int = min(sockets_per_region, cities.size())
	var selected_cities: Array = cities.slice(0, count)

	selected_cities.sort_custom(_sort_city_by_x_position)

	for i in range(selected_cities.size()):
		var city: Dictionary = selected_cities[i]
		var socket := socket_scene.instantiate()

		if socket == null:
			continue

		var city_position: Vector2 = city["map_position"]
		var offset := get_clockwise_clear_offset(city_position)

		var city_id := str(city["id"])
		var city_name := str(city["display_name"])
		var socket_name := "%s_%s_expansion_socket" % [region_id, city_id]

		socket.region_id = region_id
		socket.city_id = city_id
		socket.display_name = city_name
		socket.position = city_position
		socket.node_box_offset = offset

		get_parent().add_child(socket)
		socket.name = socket_name
		socket.id = socket_name
		socket.owner = get_tree().edited_scene_root

		placed_box_positions.append(city_position + offset)

func get_clockwise_clear_offset(city_position: Vector2) -> Vector2:
	for offset in candidate_offsets:
		var candidate_position: Vector2 = city_position + offset

		if is_position_clear(candidate_position):
			return offset

	return candidate_offsets[0]

func is_position_clear(candidate_position: Vector2) -> bool:
	for placed_position in placed_box_positions:
		if candidate_position.distance_to(placed_position) < minimum_box_spacing:
			return false

	return true

func _sort_city_by_x_position(a: Dictionary, b: Dictionary) -> bool:
	return Vector2(a["map_position"]).x < Vector2(b["map_position"]).x

func _sort_city_by_population_desc(a: Dictionary, b: Dictionary) -> bool:
	return float(a["population_weight"]) > float(b["population_weight"])
