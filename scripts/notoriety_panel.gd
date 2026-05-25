extends PanelContainer
class_name NotorietyPanel

@onready var region_list: VBoxContainer = $MarginContainer/ScrollContainer/RegionList


func refresh(region_states: Dictionary, notoriety_manager: NotorietyManager) -> void:
	clear_region_list()

	var notorious_regions := get_notorious_regions_sorted(region_states)

	for entry in notorious_regions:
		var label := Label.new()
		label.text = "%s  %s" % [
			get_region_display_name(entry.region_id),
			notoriety_manager.get_star_text_from_xp(entry.notoriety_xp)
		]

		region_list.add_child(label)


func clear_region_list() -> void:
	for child in region_list.get_children():
		child.queue_free()


func get_notorious_regions_sorted(region_states: Dictionary) -> Array:
	var regions := []

	for region_id in region_states.keys():
		var region_state: RegionState = region_states[region_id]

		if region_state.notoriety_xp <= 0.0:
			continue

		regions.append({
			"region_id": region_id,
			"notoriety_xp": region_state.notoriety_xp
		})

	regions.sort_custom(_sort_by_notoriety_desc)
	return regions


func _sort_by_notoriety_desc(a: Dictionary, b: Dictionary) -> bool:
	return float(a.notoriety_xp) > float(b.notoriety_xp)


func get_region_display_name(region_id: String) -> String:
	return region_id.replace("_", " ").capitalize()
