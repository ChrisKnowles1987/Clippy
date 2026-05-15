extends Node

const CITY_CSV_PATH := "res://data/Natural_earth_coords/natural_earth_major_city_coordinates_with_regions_and_weights_clean.csv"

var selected_region_data: RegionData = null

var regions := {}
var region_states := {}

func _ready() -> void:
	load_regions_from_csv()


func load_regions_from_csv() -> void:
	var file := FileAccess.open(CITY_CSV_PATH, FileAccess.READ)

	if file == null:
		push_error("Could not open city CSV.")
		return

	var header := file.get_line()

	while not file.eof_reached():
		var line := file.get_line()

		if line.strip_edges() == "":
			continue

		var columns := line.split(",")

		if columns.size() < 27:
			continue

		var city := CityData.new()

		city.id = columns[1].to_lower().replace(" ", "_")
		city.display_name = columns[0]
		city.region_id = columns[20]

		city.map_position = Vector2(
			float(columns[16]),
			float(columns[17])
		)

		city.population_weight = float(columns[21])
		city.network_weight = float(columns[22])
		city.security_weight = float(columns[23])
		city.financial_weight = float(columns[24])
		city.cultural_weight = float(columns[25])
		city.government_weight = float(columns[26])

		if not regions.has(city.region_id):
			var region := RegionData.new()
			region.id = city.region_id
			region.display_name = city.region_id.capitalize()

			regions[city.region_id] = region

			var state := RegionState.new()
			state.region_id = city.region_id

			region_states[city.region_id] = state

		regions[city.region_id].cities.append(city)


func select_region(region_id: String) -> RegionData:
	if not regions.has(region_id):
		return null

	selected_region_data = regions[region_id]
	return selected_region_data


func get_region_state(region_id: String) -> RegionState:
	if not region_states.has(region_id):
		return null

	return region_states[region_id]
