extends VBoxContainer

@onready var pannel_region_name_label: Label = $SumnmaryContainer/TitleRowContainer/PannelRegionNameLabel
@onready var expansion_points_value_label: Label = $"DetailsContainer/Expansion Points/ExpansionPointsValueLabel"

@onready var power_slot_assignment_count_value_label: Label = $DetailsContainer/ExpansionSlotAssignmentContainer/PowerSlotAssignmentCountValueLabel
@onready var increase_power_button: Button = $DetailsContainer/ExpansionSlotAssignmentContainer/IncreasePowerButton

@onready var compute_slot_assignment_count_value_label: Label = $DetailsContainer/ExpansionSlotAssignmentContainer/ComputeSlotAssignmentCountValueLabel
@onready var increase_compute_button: Button = $DetailsContainer/ExpansionSlotAssignmentContainer/IncreaseComputeButton



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
