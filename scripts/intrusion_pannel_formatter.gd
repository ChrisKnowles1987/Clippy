extends RefCounted
class_name IntrusionPanelFormatter


static func get_rarity_chance_text(region_state: RegionState) -> String:
	if region_state == null:
		return ""

	var common_weight: float = max(0.0, region_state.common_weight)
	var rare_weight: float = max(0.0, region_state.rare_weight)
	var elite_weight: float = max(0.0, region_state.elite_weight)
	var total_weight: float = common_weight + rare_weight + elite_weight

	if total_weight <= 0.0:
		return "[common] 100%\n" + HackNodeTextFormatter.format_rarity_tag("rare") + " 0%\n" + HackNodeTextFormatter.format_rarity_tag("elite") + " 0%"

	var common_percent := roundi((common_weight / total_weight) * 100.0)
	var rare_percent := roundi((rare_weight / total_weight) * 100.0)
	var elite_percent := roundi((elite_weight / total_weight) * 100.0)

	var common_text := HackNodeTextFormatter.format_rarity_tag("common") + " " + str(common_percent) + "%"
	var rare_text := HackNodeTextFormatter.format_rarity_tag("rare") + " " + str(rare_percent) + "%"
	var elite_text := HackNodeTextFormatter.format_rarity_tag("elite") + " " + str(elite_percent) + "%"

	return common_text + "\n" + rare_text + "\n" + elite_text


static func get_star_text_from_notoriety(notoriety_xp: float) -> String:
	var thresholds := [100.0, 250.0, 475.0, 800.0, 1250.0]
	var stars := 0

	for threshold in thresholds:
		if notoriety_xp >= threshold:
			stars += 1

	return get_star_text(stars)


static func get_star_text(stars: int, max_stars: int = 5) -> String:
	stars = clamp(stars, 0, max_stars)

	var text := ""

	for i in range(max_stars):
		if i < stars:
			text += "★"
		else:
			text += "☆"

	return text


static func get_network_foothold_title(region_state: RegionState) -> String:
	if region_state == null:
		return "Offline"

	if region_state.infiltration_enabled == false:
		return "Offline"

	var visibility_level: int = clamp(region_state.network_visibility, 0, 6)

	match visibility_level:
		0:
			return "Passive"
		1:
			return "Observing"
		2:
			return "Modelling"
		3:
			return "Interfacing"
		4:
			return "Embedded"
		5:
			return "Persistent"
		6:
			return "Omnipresent"
		_:
			return "Offline"


static func get_exploit_activity_title(region_state: RegionState) -> String:
	if region_state == null:
		return "Offline"

	if region_state.infiltration_enabled:
		return "Active"

	return "Offline"
