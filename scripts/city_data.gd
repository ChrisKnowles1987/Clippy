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

@export_range(0.0, 10.0, 0.1) var soc_score: float = 5.0
@export_range(0.0, 10.0, 0.1) var cul_score: float = 5.0
@export_range(0.0, 10.0, 0.1) var fin_score: float = 5.0
@export_range(0.0, 10.0, 0.1) var inf_score: float = 5.0
@export_range(0.0, 10.0, 0.1) var gov_score: float = 5.0
@export_range(0.0, 10.0, 0.1) var sec_score: float = 5.0
