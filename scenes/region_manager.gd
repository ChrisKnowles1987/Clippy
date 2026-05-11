extends Node

var selected_region_data: RegionData = null
var region_runtime_data := {}

func select_region(region_id: String) -> RegionData:
	if region_id == "":
		return selected_region_data

	if region_runtime_data.has(region_id):
		selected_region_data = region_runtime_data[region_id]
	else:
		var path = "res://data/regions/" + region_id + ".tres"
		var region_data: RegionData = load(path).duplicate(true)
		region_runtime_data[region_id] = region_data
		selected_region_data = region_data

	return selected_region_data
