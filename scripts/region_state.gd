extends Resource
class_name RegionState

@export var region_id: String = ""

@export var intelligence_percent: float = 0.0
@export var influence_level: int = 0

@export var soc_xp: float = 0.0
@export var cul_xp: float = 0.0
@export var fin_xp: float = 0.0
@export var inf_xp: float = 0.0
@export var gov_xp: float = 0.0
@export var sec_xp: float = 0.0

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


func add_typed_xp(node_type: String, amount: float) -> void:
	if amount <= 0.0:
		return

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


func get_xp_required(node_type: String) -> float:
	if NodeTypeDefinitions.is_valid_type(node_type) == false:
		return 0.0

	return 100.0


func get_all_typed_xp() -> Dictionary:
	var typed_xp := {}

	for node_type in NodeTypeDefinitions.get_all_types():
		typed_xp[node_type] = get_typed_xp(node_type)

	return typed_xp
