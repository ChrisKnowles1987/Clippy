extends Control

@onready var power_value_label: Label = $PowerValueLabel
@onready var compute_value_label: Label = $ComputeValueLabel

func update_values(power: float, compute: float) -> void:
	power_value_label.text = str(snapped(power, 0.1))
	compute_value_label.text = str(snapped(compute, 0.1))
