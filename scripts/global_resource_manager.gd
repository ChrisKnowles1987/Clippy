extends Node

signal resources_changed(power: float, compute: float, storage: float)

var clippy_power: float = 10.0
var clippy_compute: float = 10.0
var clippy_storage: float = 0.0

# scenes/global_resource_manager.gd
func can_afford(power_cost: float, compute_cost: float, storage_cost: float = 0.0) -> bool:
	return (
		clippy_power >= power_cost
		and clippy_compute >= compute_cost
		and clippy_storage >= storage_cost
	)

func spend(power_cost: float, compute_cost: float, storage_cost: float = 0.0) -> bool:
	if clippy_power < power_cost:
		print("Not enough power")
		return false

	if clippy_compute < compute_cost:
		print("Not enough compute")
		return false

	if clippy_storage < storage_cost:
		print("Not enough storage")
		return false

	clippy_power -= power_cost
	clippy_compute -= compute_cost
	clippy_storage -= storage_cost

	resources_changed.emit(clippy_power, clippy_compute, clippy_storage)
	return true
