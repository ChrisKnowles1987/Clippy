extends Node

var active_nodes: Array[HackNodeData] = []


func generate_region_nodes(
	region_data: RegionData,
	region_state: RegionState
) -> void:

	if region_data == null:
		return

	if region_data.cities.is_empty():
		return

	var city: CityData = pick_city(region_data.cities)

	var node := HackNodeData.new()

	node.id = str(Time.get_unix_time_from_system())

	node.region_id = region_data.id
	node.city_id = city.id
	node.city_name = city.display_name

	node.map_position = city.map_position

	node.node_type = pick_node_type(city)
	node.rarity = pick_rarity(city)

	node.quality = randf_range(1.0, 100.0)
	node.success_chance = 0.75

	node.coin_reward = city.financial_weight * randf_range(1.0, 3.0)

	node.intelligence_reward = (
		city.population_weight +
		city.network_weight
	) * 0.5

	node.notoriety_gain = city.security_weight * 0.25

	active_nodes.append(node)


func pick_city(cities: Array[CityData]) -> CityData:
	var total_weight := 0.0

	for city in cities:
		total_weight += city.population_weight

	var roll := randf() * total_weight
	var current := 0.0

	for city in cities:
		current += city.population_weight

		if roll <= current:
			return city

	return cities[0]


func pick_node_type(city: CityData) -> String:
	var weights := {
		"social": city.cultural_weight,
		"infrastructure": city.network_weight,
		"government": city.government_weight,
		"financial": city.financial_weight,
		"security": city.security_weight
	}

	var total := 0.0

	for value in weights.values():
		total += value

	var roll := randf() * total
	var current := 0.0

	for key in weights.keys():
		current += weights[key]

		if roll <= current:
			return key

	return "social"


func pick_rarity(city: CityData) -> String:
	var score := (
		city.population_weight +
		city.network_weight +
		city.financial_weight
	) / 3.0

	if score >= 8.0:
		return "elite"

	if score >= 6.0:
		return "rare"

	if score >= 4.0:
		return "uncommon"

	return "common"
