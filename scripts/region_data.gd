extends Resource
class_name RegionData

@export var id: String = ""
@export var display_name: String = ""
@export var population: int = 0

@export var pwned_noobs: float = 0.0

@export var intrusion_allocations: Dictionary = {
	"run_exploit": {
		"enabled": true,
		"power_per_day": 0,
		"compute_per_day": 0
	},
	"scan_networks": {
		"enabled": true,
		"power_per_day": 0,
		"compute_per_day": 0
	}
}
