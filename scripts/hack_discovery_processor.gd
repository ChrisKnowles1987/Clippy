extends Node
class_name HackDiscoveryProcessor

const BASE_DISCOVERY_REQUIRED := 10.0
const MAX_ACTIVE_EXPLOITS_PER_REGION := 8

var hack_node_manager: Node = null
var discovery_progress_by_region: Dictionary = {}


func setup(hack_node_manager_ref: Node) -> void:
	hack_node_manager = hack_node_manager_ref


func process_exploit_discovery(
	delta: float,
	region_data: RegionData,
	region_state: RegionState
) -> bool:
	var active_region_nodes = hack_node_manager.get_active_nodes_for_region(region_state.region_id)

	if active_region_nodes.size() >= MAX_ACTIVE_EXPLOITS_PER_REGION:
		return false

	if discovery_progress_by_region.has(region_state.region_id) == false:
		discovery_progress_by_region[region_state.region_id] = 0.0

	var power_factor: float = max(0.1, region_state.infiltration_reserved_power)
	var foothold_factor: float = 1.0 + min(region_state.network_visibility, 25.0) * 0.04
	var scan_factor: float = max(1.0, float(region_state.scan_networks_level))

	var discovery_speed: float = power_factor * scan_factor * foothold_factor
	var discovery_required: float = max(4.0, BASE_DISCOVERY_REQUIRED - min(region_state.network_visibility, 20.0) * 0.2)

	discovery_progress_by_region[region_state.region_id] += discovery_speed * delta

	if discovery_progress_by_region[region_state.region_id] < discovery_required:
		return false

	discovery_progress_by_region[region_state.region_id] -= discovery_required

	var hack_node: HackNodeData = hack_node_manager.generate_region_node(region_data, region_state)

	if hack_node == null:
		return false

	if region_state.active_node_ids.has(hack_node.id) == false:
		region_state.active_node_ids.append(hack_node.id)

	return true
