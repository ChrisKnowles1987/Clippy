extends RefCounted
class_name IntrusionPanelCosts


static func get_infiltration_power_cost(region_data: RegionData, region_state: RegionState) -> float:
	if region_state == null:
		return 0.0

	var scan_level := float(region_state.scan_networks_level)

	return get_average_city_network_weight(region_data) * scan_level


static func get_infiltration_compute_cost(region_data: RegionData, region_state: RegionState) -> float:
	if region_state == null:
		return 0.0

	var scan_level := float(region_state.scan_networks_level)

	return get_average_city_security_weight(region_data) * scan_level


static func get_average_city_network_weight(region_data: RegionData) -> float:
	if region_data == null:
		return 2.0

	if region_data.cities.is_empty():
		return 2.0

	var total := 0.0

	for city in region_data.cities:
		total += city.network_weight

	return total / float(region_data.cities.size())


static func get_average_city_security_weight(region_data: RegionData) -> float:
	if region_data == null:
		return 2.0

	if region_data.cities.is_empty():
		return 2.0

	var total := 0.0

	for city in region_data.cities:
		total += city.security_weight

	return total / float(region_data.cities.size())
