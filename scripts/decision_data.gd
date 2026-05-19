extends Resource
class_name DecisionData

@export var id: String = ""
@export var title: String = ""
@export var subtitle: String = ""
@export var region_id: String = ""
@export var source_type: String = ""
@export_multiline var terminal_text: String = ""
@export var sections: Array[DecisionSectionData] = []
@export var choices: Array[DecisionChoiceData] = []
@export var expires_on_day: int = 0
