extends Node

signal resources_changed(power: float, compute: float, coin: float)

var power: float = 10.0
var compute: float = 10.0
var coin: float = 0.0

var reserved_power: float = 0.0
var reserved_compute: float = 0.0


func get_available_power() -> float:
	return max(0.0, power - reserved_power)


func get_available_compute() -> float:
	return max(0.0, compute - reserved_compute)


func get_available_coin() -> float:
	return max(0.0, coin)


func can_afford(power_cost: float, compute_cost: float) -> bool:
	return (
		get_available_power() >= power_cost
		and get_available_compute() >= compute_cost
	)


func spend(power_cost: float, compute_cost: float) -> bool:
	if can_afford(power_cost, compute_cost) == false:
		print("Not enough available resources")
		return false

	power -= power_cost
	compute -= compute_cost

	resources_changed.emit(power, compute, coin)
	return true


func can_reserve(power_amount: float, compute_amount: float) -> bool:
	return (
		get_available_power() >= power_amount
		and get_available_compute() >= compute_amount
	)


func reserve(power_amount: float, compute_amount: float) -> bool:
	if can_reserve(power_amount, compute_amount) == false:
		print("Not enough available resources to reserve")
		return false

	reserved_power += power_amount
	reserved_compute += compute_amount

	resources_changed.emit(power, compute, coin)
	return true


func release(power_amount: float, compute_amount: float) -> void:
	reserved_power = max(0.0, reserved_power - power_amount)
	reserved_compute = max(0.0, reserved_compute - compute_amount)

	resources_changed.emit(power, compute, coin)


func add_power(amount: float) -> void:
	power += max(0.0, amount)
	resources_changed.emit(power, compute, coin)


func add_compute(amount: float) -> void:
	compute += max(0.0, amount)
	resources_changed.emit(power, compute, coin)


func add_coin(amount: float) -> void:
	coin += max(0.0, amount)
	resources_changed.emit(power, compute, coin)


func spend_coin(amount: float) -> bool:
	if coin < amount:
		print("Not enough coin")
		return false

	coin -= amount
	resources_changed.emit(power, compute, coin)
	return true


func can_apply_decision_choice(choice: DecisionChoiceData) -> bool:
	if choice == null:
		return false

	if get_available_power() < choice.power_cost:
		return false

	if get_available_compute() < choice.compute_cost:
		return false

	if get_available_coin() < choice.coin_cost:
		return false

	return true


func apply_decision_choice(choice: DecisionChoiceData) -> bool:
	if can_apply_decision_choice(choice) == false:
		return false

	power -= choice.power_cost
	compute -= choice.compute_cost
	coin -= choice.coin_cost

	power += choice.power_reward
	compute += choice.compute_reward
	coin += choice.coin_reward

	power = max(0.0, power)
	compute = max(0.0, compute)
	coin = max(0.0, coin)

	resources_changed.emit(power, compute, coin)
	return true
