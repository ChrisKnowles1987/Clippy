extends Resource
class_name CityData

@export var id: String = ""
@export var display_name: String = ""
@export var region_id: String = ""

@export var map_position: Vector2 = Vector2.ZERO

@export var population_weight: float = 1.0
@export var network_weight: float = 1.0
@export var security_weight: float = 1.0
@export var cultural_weight: float = 1.0
@export var financial_weight: float = 1.0
@export var government_weight: float = 1.0
