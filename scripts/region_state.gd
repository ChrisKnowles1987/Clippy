extends Resource
class_name RegionState

@export var region_id: String = ""

@export var intelligence_percent: float = 0.0
@export var influence_level: int = 0

@export var notoriety_xp: float = 0.0:
	set(value):
		notoriety_xp = clamp(value, 0.0 ,100.0)
@export var shutdown_progress: float = 0.0

@export var active_campaigns: Array[String] = []
@export var active_node_ids: Array[String] = []

@export var infiltration_enabled: bool = false
@export var infiltration_reserved_power: float = 0.0
@export var infiltration_reserved_compute: float = 0.0

@export var run_exploit_enabled: bool = false
@export var run_exploit_power_per_day: int = 0
@export var run_exploit_compute_per_day: int = 0

@export var scan_networks_enabled: bool = false
@export var scan_networks_level: int = 1
@export var network_visibility: int = 0
