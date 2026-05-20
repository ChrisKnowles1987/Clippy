extends Node
class_name HackNodeManager

var active_nodes: Array[HackNodeData] = []


func generate_region_node(
	region_data: RegionData,
	region_state: RegionState
) -> HackNodeData:

	if region_data == null:
		return null

	if region_state == null:
		return null

	if region_data.cities.is_empty():
		return null

	var city: CityData = pick_city(region_data.cities)
	var hack_node := HackNodeData.new()

	hack_node.id = str(Time.get_unix_time_from_system()) + "_" + str(randi())

	hack_node.region_id = region_data.id
	hack_node.city_id = city.id
	hack_node.city_name = city.display_name
	hack_node.map_position = city.map_position

	hack_node.node_type = pick_node_type(city)
	hack_node.rarity = pick_rarity(region_state)
	hack_node.success_chance = calculate_success_chance(city, hack_node)

	hack_node.coin_reward = calculate_coin_reward(city, hack_node)
	hack_node.intelligence_reward = calculate_intelligence_reward(city, hack_node)
	hack_node.notoriety_gain = 0.0

	hack_node.processing_progress = 0.0
	hack_node.processing_required = calculate_processing_required(city, hack_node)
	hack_node.processing_speed = 1.0
	hack_node.status = "processing"
	hack_node.resolved = false

	active_nodes.append(hack_node)

	return hack_node


func generate_region_nodes(
	region_data: RegionData,
	region_state: RegionState
) -> void:
	generate_region_node(region_data, region_state)


func remove_resolved_nodes() -> void:
	var remaining_nodes: Array[HackNodeData] = []

	for hack_node in active_nodes:
		if hack_node.resolved == false:
			remaining_nodes.append(hack_node)

	active_nodes = remaining_nodes


func get_active_nodes_for_region(region_id: String) -> Array[HackNodeData]:
	var region_nodes: Array[HackNodeData] = []

	for hack_node in active_nodes:
		if hack_node.region_id == region_id and hack_node.resolved == false:
			region_nodes.append(hack_node)

	return region_nodes


func pick_city(cities: Array[CityData]) -> CityData:
	var total_weight := 0.0

	for city in cities:
		total_weight += max(0.1, city.population_weight)

	var roll := randf() * total_weight
	var current := 0.0

	for city in cities:
		current += max(0.1, city.population_weight)

		if roll <= current:
			return city

	return cities[0]


func pick_node_type(city: CityData) -> String:
	var weights := {
		NodeTypeDefinitions.SOCIAL: max(0.1, city.population_weight),
		NodeTypeDefinitions.CULTURAL: max(0.1, city.cultural_weight),
		NodeTypeDefinitions.INFRASTRUCTURE: max(0.1, city.network_weight),
		NodeTypeDefinitions.GOVERNMENT: max(0.1, city.government_weight),
		NodeTypeDefinitions.FINANCIAL: max(0.1, city.financial_weight),
		NodeTypeDefinitions.SECURITY: max(0.1, city.security_weight)
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


func pick_rarity(region_state: RegionState) -> String:
	var common_weight: float = max(0.0, region_state.common_weight)
	var rare_weight: float = max(0.0, region_state.rare_weight)
	var elite_weight: float = max(0.0, region_state.elite_weight)

	var total_weight := common_weight + rare_weight + elite_weight

	if total_weight <= 0.0:
		return "common"

	var roll := randf() * total_weight

	if roll < elite_weight:
		return "elite"

	if roll < elite_weight + rare_weight:
		return "rare"

	return "common"


func calculate_success_chance(city: CityData, hack_node: HackNodeData) -> float:
	var base_chance := 0.72
	var security_penalty := city.security_weight * 0.025

	match hack_node.rarity:
		"common":
			base_chance += 0.08
		"rare":
			base_chance -= 0.04
		"elite":
			base_chance -= 0.10

	return clamp(base_chance - security_penalty, 0.20, 0.92)


func calculate_coin_reward(city: CityData, hack_node: HackNodeData) -> float:

	var rarity_multiplier := get_rarity_multiplier(hack_node.rarity)

	return city.financial_weight * rarity_multiplier * randf_range(2.0, 5.0)


func calculate_intelligence_reward(city: CityData, hack_node: HackNodeData) -> float:
	var type_weight := city.network_weight

	match hack_node.node_type:
		NodeTypeDefinitions.SOCIAL:
			type_weight = city.population_weight
		NodeTypeDefinitions.CULTURAL:
			type_weight = city.cultural_weight
		NodeTypeDefinitions.INFRASTRUCTURE:
			type_weight = city.network_weight
		NodeTypeDefinitions.GOVERNMENT:
			type_weight = city.government_weight
		NodeTypeDefinitions.FINANCIAL:
			type_weight = city.financial_weight
		NodeTypeDefinitions.SECURITY:
			type_weight = city.security_weight

	var rarity_multiplier := get_rarity_multiplier(hack_node.rarity)

	return max(0.2, type_weight * rarity_multiplier * 0.35)


func calculate_processing_required(city: CityData, hack_node: HackNodeData) -> float:
	var base_time := 8.0

	match hack_node.rarity:
		"common":
			base_time = 8.0
		"rare":
			base_time = 24.0
		"elite":
			base_time = 40.0

	var security_multiplier := 1.0 + (city.security_weight * 0.08)

	return base_time * security_multiplier


func get_rarity_multiplier(rarity: String) -> float:
	match rarity:
		"common":
			return 1.0
		"rare":
			return 3.2
		"elite":
			return 5.0
		_:
			return 1.0
