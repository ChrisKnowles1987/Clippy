extends Resource
class_name RegionData

@export var id: String = ""
@export var display_name: String = ""

@export var base_common_weight: float = 80.0
@export var base_rare_weight: float = 18.0
@export var base_elite_weight: float = 2.0

@export var cities: Array[CityData] = []


func get_node_type_score(node_type: String) -> float:
	if cities.is_empty():
		return 0.0

	var total := 0.0

	for city in cities:
		total += get_city_node_type_score(city, node_type)

	return snapped(total / float(cities.size()), 0.1)


func get_city_node_type_score(city: CityData, node_type: String) -> float:
	if city == null:
		return 0.0

	match node_type:
		NodeTypeDefinitions.SOCIAL:
			return city.soc_score
		NodeTypeDefinitions.CULTURAL:
			return city.cul_score
		NodeTypeDefinitions.FINANCIAL:
			return city.fin_score
		NodeTypeDefinitions.INFRASTRUCTURE:
			return city.inf_score
		NodeTypeDefinitions.GOVERNMENT:
			return city.gov_score
		NodeTypeDefinitions.SECURITY:
			return city.sec_score
		_:
			return 0.0


func get_all_node_type_scores() -> Dictionary:
	var scores := {}

	for node_type in NodeTypeDefinitions.get_all_types():
		scores[node_type] = get_node_type_score(node_type)

	return scores
