@tool
extends Node

@export var socket_scene: PackedScene
@export var region_manager_path: NodePath
@export var sockets_per_region: int = 10
@export var clear_existing_sockets: bool = false

@export var generate_sockets: bool = false:
	set(value):
		generate_sockets = false
		if value:
			generate()

var default_offsets: Array[Vector2] = [
	Vector2(40, -30),
	Vector2(50, 0),
	Vector2(40, 30),
	Vector2(-40, -30),
	Vector2(-50, 0),
	Vector2(-40, 30),
	Vector2(0, -50),
	Vector2(0, 50),
	Vector2(70, -50),
	Vector2(-70, 50)
]

func generate() -> void:
	if socket_scene == null:
		push_error("expansion_socket_generator.gd: No socket_scene assigned.")
		return

	var region_manager := get_node_or_null(region_manager_path)

	if region_manager == null:
		push_error("expansion_socket_generator.gd: RegionManager not found.")
		return

	if clear_existing_sockets:
		clear_sockets()

	region_manager.load_regions_from_csv()

	var regions: Dictionary = region_manager.regions

	for region_id in regions:
		generate_region_sockets(region_id, regions[region_id])

func clear_sockets() -> void:
	for child in get_parent().get_children():
		if child == self:
			continue

		if child.has_method("update_line"):
			child.queue_free()

func generate_region_sockets(region_id: String, region_data) -> void:
	if region_data == null:
		return

	var cities: Array = region_data.cities.duplicate()

	if cities.is_empty():
		return

	cities.sort_custom(_sort_city_by_population_desc)

	var count: int = min(sockets_per_region, cities.size())

	for i in range(count):
		var city = cities[i]
		var socket := socket_scene.instantiate()

		if socket == null:
			continue

		socket.name = "%s_%s_expansion_socket" % [region_id, city.id]
		socket.id = socket.name
		socket.region_id = region_id
		socket.city_id = city.id
		socket.display_name = city.display_name
		socket.position = city.map_position
		socket.node_box_offset = default_offsets[i % default_offsets.size()]

		get_parent().add_child(socket)
		socket.owner = get_tree().edited_scene_root

func _sort_city_by_population_desc(a, b) -> bool:
	return a.population_weight > b.population_weight
