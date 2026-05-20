extends Resource
class_name RegionData

@export var id: String = ""
@export var display_name: String = ""

@export var base_common_weight: float = 80.0
@export var base_rare_weight: float = 18.0
@export var base_elite_weight: float = 2.0

@export var cities: Array[CityData] = []
