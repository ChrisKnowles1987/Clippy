extends Resource
class_name HackNodeData

@export var id: String = ""

@export var region_id: String = ""
@export var city_id: String = ""
@export var city_name: String = ""

@export var node_type: String = ""
@export var rarity: String = "common"
@export var success_chance: float = 0.5

@export var map_position: Vector2 = Vector2.ZERO

@export var coin_reward: float = 0.0
@export var intelligence_reward: float = 0.0
@export var notoriety_gain: float = 0.0

@export var processing_progress: float = 0.0
@export var processing_required: float = 8.0
@export var processing_speed: float = 1.0
@export var status: String = "processing"

@export var expires_on_day: int = 0
@export var resolved: bool = false
