extends Node
class_name CampaignManager

var campaign_database: CampaignDatabase = null
var region_manager = null
var global_resource_manager = null


func setup(
	campaign_database_ref: CampaignDatabase,
	region_manager_ref: Node,
	global_resource_manager_ref: Node
) -> void:
	campaign_database = campaign_database_ref
	region_manager = region_manager_ref
	global_resource_manager = global_resource_manager_ref


func get_available_campaigns(region_id: String) -> Array[CampaignData]:
	var result: Array[CampaignData] = []

	if campaign_database == null or region_manager == null or global_resource_manager == null:
		return result

	var region_data: RegionData = region_manager.regions.get(region_id, null)
	var region_state: RegionState = region_manager.get_region_state(region_id)

	if region_data == null or region_state == null:
		return result

	for campaign in campaign_database.get_all_campaigns():
		if can_activate_campaign(region_data, region_state, campaign):
			result.append(campaign)

	return result


func can_activate_campaign(
	region_data: RegionData,
	region_state: RegionState,
	campaign: CampaignData
) -> bool:
	if campaign == null:
		return false

	if region_state.has_active_campaign(campaign.id):
		return false

	if region_meets_stat_minimums(region_data, campaign) == false:
		return false

	if region_state.has_available_campaign_slots(campaign.required_slots) == false:
		return false

	if global_resource_manager.get_available_coin() < campaign.coin_cost:
		return false

	return true


func try_activate_campaign(region_id: String, campaign_id: String) -> bool:
	if campaign_database == null or region_manager == null or global_resource_manager == null:
		return false

	var region_data: RegionData = region_manager.regions.get(region_id, null)
	var region_state: RegionState = region_manager.get_region_state(region_id)
	var campaign := campaign_database.get_campaign(campaign_id)

	if region_data == null or region_state == null or campaign == null:
		return false

	if can_activate_campaign(region_data, region_state, campaign) == false:
		return false

	if global_resource_manager.spend_coin(campaign.coin_cost) == false:
		return false

	if region_state.consume_campaign_slots(campaign.required_slots) == false:
		return false

	var active_campaign := ActiveCampaignData.new()
	active_campaign.campaign_id = campaign.id
	active_campaign.display_name = campaign.display_name
	active_campaign.description = campaign.description
	active_campaign.effect_id = campaign.effect_id
	active_campaign.always_on = campaign.duration_days < 0
	active_campaign.remaining_days = campaign.duration_days

	region_state.add_active_campaign(active_campaign)

	return true


func process_day_passed() -> void:
	if region_manager == null:
		return

	for region_id in region_manager.region_states.keys():
		var region_state: RegionState = region_manager.get_region_state(region_id)

		if region_state == null:
			continue

		region_state.process_active_campaigns_day()


func region_meets_stat_minimums(region_data: RegionData, campaign: CampaignData) -> bool:
	if get_region_stat_level(region_data, "Soc") < campaign.min_soc:
		return false

	if get_region_stat_level(region_data, "Cul") < campaign.min_cul:
		return false

	if get_region_stat_level(region_data, "Fin") < campaign.min_fin:
		return false

	if get_region_stat_level(region_data, "Inf") < campaign.min_inf:
		return false

	if get_region_stat_level(region_data, "Gov") < campaign.min_gov:
		return false

	if get_region_stat_level(region_data, "Sec") < campaign.min_sec:
		return false

	return true


func get_region_stat_level(region_data: RegionData, stat_type: String) -> int:
	if region_data == null:
		return 0

	match stat_type:
		"Soc":
			return int(round(region_data.soc_score))
		"Cul":
			return int(round(region_data.cul_score))
		"Fin":
			return int(round(region_data.fin_score))
		"Inf":
			return int(round(region_data.inf_score))
		"Gov":
			return int(round(region_data.gov_score))
		"Sec":
			return int(round(region_data.sec_score))
		_:
			return 0
