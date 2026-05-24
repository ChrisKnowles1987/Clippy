extends Resource
class_name RegionState

const MAX_REGION_LEVEL := 10

@export var region_id: String = ""

@export var influence_level: int = 0
@export var confirmed_region_level: int = 0
@export var pending_level_ups: int = 0
@export var expansion_points: int = 0

@export var soc_xp: float = 0.0
@export var cul_xp: float = 0.0
@export var fin_xp: float = 0.0
@export var inf_xp: float = 0.0
@export var gov_xp: float = 0.0
@export var sec_xp: float = 0.0

@export var level_slots: Array[String] = []

@export var conversion_slot_index: int = -1
@export var conversion_target_type: String = ""
@export var conversion_progress: float = 0.0

@export var notoriety_xp: float = 0.0:
	set(value):
		notoriety_xp = clamp(value, 0.0 ,100.0)

@export var shutdown_progress: float = 0.0

@export var active_campaigns: Array[String] = []
@export var active_node_ids: Array[String] = []

@export var infiltration_enabled: bool = false
@export var infiltration_reserved_power: float = 0.0
@export var infiltration_reserved_compute: float = 0.0

@export var scan_networks_level: int = 1
@export var network_visibility: int = 0

@export var common_weight: float = 80.0
@export var rare_weight: float = 18.0
@export var elite_weight: float = 2.0


func get_node_type_level(node_type: String) -> int:
	var count := 0

	for slot_type in level_slots:
		if slot_type == node_type:
			count += 1

	return count


func add_typed_xp(node_type: String, amount: float) -> int:
	if amount <= 0.0:
		return 0

	if NodeTypeDefinitions.is_valid_type(node_type) == false:
		return 0

	if add_conversion_xp(node_type, amount):
		return 0

	add_raw_typed_xp(node_type, amount)

	return process_typed_xp_thresholds(node_type)


func get_typed_xp(node_type: String) -> float:
	match node_type:
		NodeTypeDefinitions.SOCIAL:
			return soc_xp
		NodeTypeDefinitions.CULTURAL:
			return cul_xp
		NodeTypeDefinitions.FINANCIAL:
			return fin_xp
		NodeTypeDefinitions.INFRASTRUCTURE:
			return inf_xp
		NodeTypeDefinitions.GOVERNMENT:
			return gov_xp
		NodeTypeDefinitions.SECURITY:
			return sec_xp
		_:
			return 0.0


func get_typed_xp_percent(node_type: String) -> float:
	var xp_required := get_xp_required(node_type)

	if xp_required <= 0.0:
		return 0.0

	return clamp((get_typed_xp(node_type) / xp_required) * 100.0, 0.0, 100.0)
	
	
func add_raw_typed_xp(node_type: String, amount: float) -> void:
	match node_type:
		NodeTypeDefinitions.SOCIAL:
			soc_xp += amount
		NodeTypeDefinitions.CULTURAL:
			cul_xp += amount
		NodeTypeDefinitions.FINANCIAL:
			fin_xp += amount
		NodeTypeDefinitions.INFRASTRUCTURE:
			inf_xp += amount
		NodeTypeDefinitions.GOVERNMENT:
			gov_xp += amount
		NodeTypeDefinitions.SECURITY:
			sec_xp += amount


func spend_typed_xp(node_type: String, amount: float) -> void:
	match node_type:
		NodeTypeDefinitions.SOCIAL:
			soc_xp = max(0.0, soc_xp - amount)
		NodeTypeDefinitions.CULTURAL:
			cul_xp = max(0.0, cul_xp - amount)
		NodeTypeDefinitions.FINANCIAL:
			fin_xp = max(0.0, fin_xp - amount)
		NodeTypeDefinitions.INFRASTRUCTURE:
			inf_xp = max(0.0, inf_xp - amount)
		NodeTypeDefinitions.GOVERNMENT:
			gov_xp = max(0.0, gov_xp - amount)
		NodeTypeDefinitions.SECURITY:
			sec_xp = max(0.0, sec_xp - amount)


func process_typed_xp_thresholds(node_type: String) -> int:
	var slots_added := 0

	while can_add_level_slot():
		var xp_required := get_xp_required(node_type)

		if xp_required <= 0.0:
			break

		if get_typed_xp(node_type) < xp_required:
			break

		spend_typed_xp(node_type, xp_required)

		if add_level_slot(node_type):
			slots_added += 1
		else:
			break

	return slots_added


func get_xp_required(node_type: String) -> float:
	if NodeTypeDefinitions.is_valid_type(node_type) == false:
		return 0.0

	if can_add_level_slot() == false:
		return 0.0

	return get_xp_required_for_next_slot(node_type)


func get_xp_required_for_next_slot(node_type: String) -> float:
	if NodeTypeDefinitions.is_valid_type(node_type) == false:
		return 0.0

	return 100.0 * float(get_node_type_level(node_type) + 1)


func get_all_typed_xp() -> Dictionary:
	var typed_xp := {}

	for node_type in NodeTypeDefinitions.get_all_types():
		typed_xp[node_type] = get_typed_xp(node_type)

	return typed_xp


func get_region_level() -> int:
	return confirmed_region_level


func get_earned_slot_count() -> int:
	return level_slots.size()


func get_max_region_level() -> int:
	return MAX_REGION_LEVEL


func can_add_level_slot() -> bool:
	return level_slots.size() < MAX_REGION_LEVEL


func add_level_slot(node_type: String) -> bool:
	if can_add_level_slot() == false:
		return false

	if NodeTypeDefinitions.is_valid_type(node_type) == false:
		return false

	level_slots.append(node_type)
	pending_level_ups += 1
	return true


func get_level_slots() -> Array[String]:
	return level_slots.duplicate()


func has_pending_level_up() -> bool:
	return pending_level_ups > 0


func get_next_level_number() -> int:
	return clamp(confirmed_region_level + 1, 1, MAX_REGION_LEVEL)


func get_next_level_up_power_cost() -> float:
	return float(get_next_level_number() * 5)


func get_next_level_up_compute_cost() -> float:
	return float(get_next_level_number() * 5)


func confirm_level_up() -> bool:
	if pending_level_ups <= 0:
		return false

	if confirmed_region_level >= MAX_REGION_LEVEL:
		return false

	pending_level_ups -= 1
	confirmed_region_level += 1
	scan_networks_level += 1
	expansion_points += 1

	return true


func start_slot_conversion(slot_index: int, target_type: String) -> bool:
	if slot_index < 0 or slot_index >= level_slots.size():
		return false

	if NodeTypeDefinitions.is_valid_type(target_type) == false:
		return false

	if level_slots[slot_index] == target_type:
		return false

	conversion_slot_index = slot_index
	conversion_target_type = target_type
	conversion_progress = 0.0

	return true


func cancel_slot_conversion() -> void:
	conversion_slot_index = -1
	conversion_target_type = ""
	conversion_progress = 0.0


func has_active_slot_conversion() -> bool:
	if conversion_slot_index < 0:
		return false

	if conversion_slot_index >= level_slots.size():
		return false

	return NodeTypeDefinitions.is_valid_type(conversion_target_type)


func add_conversion_xp(node_type: String, amount: float) -> bool:
	if has_active_slot_conversion() == false:
		return false

	if node_type != conversion_target_type:
		return false

	conversion_progress += amount

	var xp_required := get_conversion_xp_required()

	if xp_required > 0.0 and conversion_progress >= xp_required:
		complete_slot_conversion()

	return true


func get_conversion_xp_required() -> float:
	if has_active_slot_conversion() == false:
		return 0.0

	return get_xp_required_for_next_slot(conversion_target_type)


func get_conversion_progress_percent() -> float:
	var xp_required := get_conversion_xp_required()

	if xp_required <= 0.0:
		return 0.0

	return clamp((conversion_progress / xp_required) * 100.0, 0.0, 100.0)


func complete_slot_conversion() -> void:
	if has_active_slot_conversion() == false:
		cancel_slot_conversion()
		return

	level_slots[conversion_slot_index] = conversion_target_type
	cancel_slot_conversion()
