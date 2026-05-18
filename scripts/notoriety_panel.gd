extends PanelContainer
class_name NotorietyPanel

@onready var grid_container: GridContainer = $MarginContainer/GridContainer

var region_label_map: Dictionary = {}


func _ready() -> void:
	build_region_label_map()


func build_region_label_map() -> void:
	region_label_map = {
		"north_america": grid_container.get_node("NorthAmericaStars"),
		"central_america_caribbean": grid_container.get_node("CentralAmerica&CaribbeanStars"),
		"south_america": grid_container.get_node("SouthAmericaStars"),
		"western_europe": grid_container.get_node("WesternEuropeStars"),
		"eastern_europe": grid_container.get_node("EasternEuropeStars"),
		"north_africa": grid_container.get_node("NorthAfricaStars"),
		"east_africa": grid_container.get_node("EastAfricaStars"),
		"west_africa": grid_container.get_node("WestAfricaStars"),
		"russia_central_asia": grid_container.get_node("Russia&CentralAsiaStars"),
		"middle_east": grid_container.get_node("MiddleEastStars"),
		"india": grid_container.get_node("IndiaStars"),
		"china": grid_container.get_node("ChinaStars"),
		"southern_africa": grid_container.get_node("SouthAfricaStars"),
		"japan_korea": grid_container.get_node("EastAsiaStars"),
		"southeast_asia": grid_container.get_node("SouthEastAsiaStars"),
		"oceania": grid_container.get_node("OceaniaStars")
	}


func refresh(region_states: Dictionary, notoriety_manager: NotorietyManager) -> void:
	for region_id in region_label_map.keys():
		if region_states.has(region_id) == false:
			continue

		var region_state: RegionState = region_states[region_id]
		var label: Label = region_label_map[region_id]

		label.text = notoriety_manager.get_star_text_from_xp(region_state.notoriety)
