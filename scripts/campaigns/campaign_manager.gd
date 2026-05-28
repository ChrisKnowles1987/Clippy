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
	if campaign_database == null:
		return []

	return campaign_database.get_all_campaigns()


func can_activate_campaign_id(region_id: String, campaign_id: String) -> bool:
	var region_data: RegionData = region_manager.regions.get(region_id, null)
	var region_state: RegionState = region_manager.get_region_state(region_id)
	var campaign := campaign_database.get_campaign(campaign_id)

	if region_data == null or region_state == null or campaign == null:
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
	if can_activate_campaign_id(region_id, campaign_id) == false:
		return false

	var region_state: RegionState = region_manager.get_region_state(region_id)
	var campaign := campaign_database.get_campaign(campaign_id)

	global_resource_manager.spend_coin(campaign.coin_cost)
	region_state.consume_campaign_slots(campaign.required_slots)

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

		if region_state != null:
			region_state.process_active_campaigns_day()


func region_meets_stat_minimums(region_data: RegionData, campaign: CampaignData) -> bool:
	return (
		get_region_stat_level(region_data, NodeTypeDefinitions.SOCIAL) >= campaign.min_soc
		and get_region_stat_level(region_data, NodeTypeDefinitions.CULTURAL) >= campaign.min_cul
		and get_region_stat_level(region_data, NodeTypeDefinitions.FINANCIAL) >= campaign.min_fin
		and get_region_stat_level(region_data, NodeTypeDefinitions.INFRASTRUCTURE) >= campaign.min_inf
		and get_region_stat_level(region_data, NodeTypeDefinitions.GOVERNMENT) >= campaign.min_gov
		and get_region_stat_level(region_data, NodeTypeDefinitions.SECURITY) >= campaign.min_sec
	)


func get_region_stat_level(region_data: RegionData, node_type: String) -> int:
	if region_data == null:
		return 0

	return int(round(region_data.get_node_type_score(node_type)))
