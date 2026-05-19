extends Resource
class_name RegionData

@export var id: String = ""
@export var display_name: String = ""

@export var base_common_chance: float = 0.80
@export var base_rare_chance: float = 0.18
@export var base_elite_chance: float = 0.02

@export var cities: Array[CityData] = []
