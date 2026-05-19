extends RefCounted
class_name InfiltrationRateCalculator

const BASE_DISCOVERY_REQUIRED := 10.0
const MIN_DISCOVERY_REQUIRED := 4.0
const MAX_VISIBILITY_DISCOVERY_BONUS := 20.0
const MAX_VISIBILITY_SPEED_BONUS := 25.0


static func get_discovery_speed(region_state: RegionState) -> float:
	var power_factor: float = max(0.1, region_state.infiltration_reserved_power)
	var visibility_factor: float = 1.0 + min(region_state.network_visibility, MAX_VISIBILITY_SPEED_BONUS) * 0.04
	var scan_factor: float = max(1.0, float(region_state.scan_networks_level))

	return power_factor * visibility_factor * scan_factor


static func get_discovery_required(region_state: RegionState) -> float:
	var visibility_reduction: float = min(region_state.network_visibility, MAX_VISIBILITY_DISCOVERY_BONUS) * 0.2

	return max(MIN_DISCOVERY_REQUIRED, BASE_DISCOVERY_REQUIRED - visibility_reduction)


static func get_exploit_processing_speed(hack_node: HackNodeData, region_state: RegionState) -> float:
	var compute_factor: float = max(0.1, region_state.infiltration_reserved_compute)
	var rarity_factor: float = 1.0

	match hack_node.rarity:
		"common":
			rarity_factor = 1.0
		"rare":
			rarity_factor = 0.8
		"elite":
			rarity_factor = 0.65

	return compute_factor * rarity_factor
