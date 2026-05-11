extends Control

var selected_region_data: RegionData = null

func show_region(region_data: RegionData) -> void:
	selected_region_data = region_data
	refresh_intrusion_ui()
	
func refresh_intrusion_ui() -> void:
	if selected_region_data == null:
		return

	print("Showing intrusion UI for: ", selected_region_data.display_name)
	print(selected_region_data.intrusion_allocations)	
