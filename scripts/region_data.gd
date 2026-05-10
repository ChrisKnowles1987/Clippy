extends Resource
class_name RegionData

@export var id: String = ""
@export var display_name: String = ""
@export var population: int = 0

@export var clippy_power: float = 0.0
@export var clippy_compute: float = 0.0
@export var clippy_storage: float= 0.0
@export var clippy_influence: float = 0.0
@export var clippy_control: float = 0.0:
	set(value):
		clippy_control = clamp(value, 0.0, 100.0)
