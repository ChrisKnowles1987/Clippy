extends Node
class_name CampaignDatabase

const CAMPAIGN_CSV_PATH := "res://data/campaigns/campaigns.csv"

var campaigns: Dictionary = {}


func _ready() -> void:
	load_campaigns()


func load_campaigns() -> void:
	campaigns.clear()

	var file := FileAccess.open(CAMPAIGN_CSV_PATH, FileAccess.READ)

	if file == null:
		push_error("Could not open campaign CSV: " + CAMPAIGN_CSV_PATH)
		return

	if file.eof_reached():
		return

	var headers := file.get_csv_line()

	while not file.eof_reached():
		var columns := file.get_csv_line()

		if columns.is_empty():
			continue

		var row := {}

		for index in min(headers.size(), columns.size()):
			row[headers[index]] = columns[index]

		var campaign := CampaignData.new()

		campaign.id = get_string_value(row, "id")
		campaign.display_name = get_string_value(row, "display_name")
		campaign.description = get_string_value(row, "description")

		campaign.min_soc = get_int_value(row, "min_soc")
		campaign.min_cul = get_int_value(row, "min_cul")
		campaign.min_fin = get_int_value(row, "min_fin")
		campaign.min_inf = get_int_value(row, "min_inf")
		campaign.min_gov = get_int_value(row, "min_gov")
		campaign.min_sec = get_int_value(row, "min_sec")

		campaign.required_slots = get_required_slots(row)

		campaign.coin_cost = get_float_value(row, "coin_cost")
		campaign.duration_days = get_int_value(row, "duration_days", 10)
		campaign.effect_id = get_string_value(row, "effect_id")

		if campaign.id != "":
			campaigns[campaign.id] = campaign

	file.close()


func get_campaign(campaign_id: String) -> CampaignData:
	return campaigns.get(campaign_id, null)


func get_all_campaigns() -> Array[CampaignData]:
	var result: Array[CampaignData] = []

	for campaign in campaigns.values():
		result.append(campaign)

	return result


func get_required_slots(row: Dictionary) -> Array[String]:
	var required_slots: Array[String] = []

	for column_name in ["slot_1", "slot_2", "slot_3", "slot_4", "slot_5"]:
		var slot_type := get_string_value(row, column_name)

		if slot_type != "":
			required_slots.append(slot_type)

	return required_slots


func get_string_value(row: Dictionary, key: String, default_value: String = "") -> String:
	return str(row.get(key, default_value)).strip_edges()


func get_int_value(row: Dictionary, key: String, default_value: int = 0) -> int:
	var value := get_string_value(row, key, str(default_value))

	if value == "":
		return default_value

	return int(value)


func get_float_value(row: Dictionary, key: String, default_value: float = 0.0) -> float:
	var value := get_string_value(row, key, str(default_value))

	if value == "":
		return default_value

	return float(value)
