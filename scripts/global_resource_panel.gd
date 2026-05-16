extends Control

@onready var power_value_label: Label = $VBoxContainer/HBoxContainer/PowerValueLabel
@onready var compute_value_label: Label = $VBoxContainer/HBoxContainer2/ComputeValueLabel
@onready var coin_value_label: Label = $VBoxContainer/HBoxContainer3/CoinValueLabel

func update_values(power: float, compute: float, coin: float) -> void:
	power_value_label.text = str(snapped(power, 0.1))
	compute_value_label.text = str(snapped(compute, 0.1))
	coin_value_label.text = str(snapped(coin, 0.1))
