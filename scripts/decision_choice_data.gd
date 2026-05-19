extends Resource
class_name DecisionChoiceData

@export var id: String = ""
@export var label: String = ""
@export var style: String = ""
@export_multiline var tooltip: String = ""
@export_multiline var warning_text: String = ""

@export var power_cost: float = 0.0
@export var compute_cost: float = 0.0
@export var coin_cost: float = 0.0

@export var power_reward: float = 0.0
@export var compute_reward: float = 0.0
@export var coin_reward: float = 0.0
