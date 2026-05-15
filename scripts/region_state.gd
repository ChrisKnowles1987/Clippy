extends Resource
class_name RegionState

@export var region_id: String = ""

@export var intelligence_percent: float = 0.0
@export var influence_level: int = 0

@export var blue_power: float = 0.0
@export var blue_compute: float = 0.0

@export var notoriety: float = 0.0
@export var shutdown_progress: float = 0.0

@export var active_campaigns: Array[String] = []
@export var active_node_ids: Array[String] = []
