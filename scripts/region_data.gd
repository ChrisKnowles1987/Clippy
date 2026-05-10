extends Resource
class_name RegionData

@export var id: String = ""
@export var display_name: String = ""

@export var description: String = ""
@export var population: int = 0

@export var clippy_power: float = 0.0
@export var compute: float = 0.0
@export var storage: float= 0.0
@export var influence: float = 0.0
@export var control: float = 0.0:
	
	set(value):
		control = clamp(value, 0.0, 100.0)
