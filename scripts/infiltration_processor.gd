extends Node
class_name InfiltrationProcessor

var hack_discovery_processor: HackDiscoveryProcessor = null
var hack_exploit_processor: HackExploitProcessor = null


func setup(
	hack_discovery_processor_ref: HackDiscoveryProcessor,
	hack_exploit_processor_ref: HackExploitProcessor
) -> void:
	hack_discovery_processor = hack_discovery_processor_ref
	hack_exploit_processor = hack_exploit_processor_ref


func process_region(
	delta: float,
	region_data: RegionData,
	region_state: RegionState
) -> bool:
	var changed := false

	if region_state.infiltration_enabled == false:
		return false

	if hack_discovery_processor.process_exploit_discovery(delta, region_data, region_state):
		changed = true

	if hack_exploit_processor.process_active_exploits(delta, region_state):
		changed = true

	return changed
