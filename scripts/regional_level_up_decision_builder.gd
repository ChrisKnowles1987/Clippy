extends RefCounted
class_name RegionalLevelUpDecisionBuilder

const DECISION_PREFIX := "level_up:"


static func build_decision(region_data: RegionData, region_state: RegionState) -> DecisionData:
	var decision := DecisionData.new()
	var region_name := region_state.region_id

	if region_data != null:
		region_name = region_data.display_name

	decision.id = get_decision_id(region_state.region_id)
	decision.title = "Regional level-up available"
	decision.subtitle = region_name
	decision.region_id = region_state.region_id
	decision.source_type = "regional_level_up"
	decision.terminal_text = "Typed intelligence threshold reached. Regional model expansion is available pending resource authorisation."
	decision.expires_on_day = 0

	decision.sections.append(build_cost_section(region_state))
	decision.sections.append(build_reward_section(region_state))
	decision.sections.append(build_status_section(region_state))

	decision.choices.append(build_confirm_choice(region_state))
	decision.choices.append(build_defer_choice())

	return decision


static func get_decision_id(region_id: String) -> String:
	return DECISION_PREFIX + region_id


static func get_region_id_from_decision_id(decision_id: String) -> String:
	if decision_id.begins_with(DECISION_PREFIX) == false:
		return ""

	return decision_id.substr(DECISION_PREFIX.length())


static func is_level_up_decision_id(decision_id: String) -> bool:
	return decision_id.begins_with(DECISION_PREFIX)


static func build_cost_section(region_state: RegionState) -> DecisionSectionData:
	var section := DecisionSectionData.new()
	section.title = "Cost"
	section.style = "cost"
	section.rows = [
		"[color=#88ccff]Power:[/color] " + str(snapped(region_state.get_next_level_up_power_cost(), 0.1)),
		"[color=#88ccff]Compute:[/color] " + str(snapped(region_state.get_next_level_up_compute_cost(), 0.1))
	]
	return section


static func build_reward_section(region_state: RegionState) -> DecisionSectionData:
	var section := DecisionSectionData.new()
	section.title = "Rewards"
	section.style = "success"
	section.rows = [
		"[color=#88ccff]+1[/color] Scan Networks level",
		"[color=#88dd88]+1[/color] Expansion point"
	]
	return section


static func build_status_section(region_state: RegionState) -> DecisionSectionData:
	var section := DecisionSectionData.new()
	section.title = "Status"
	section.style = "normal"
	section.rows = [
		"Confirmed level: " + str(region_state.get_region_level()) + "/" + str(region_state.get_max_region_level()),
		"Earned slots: " + str(region_state.get_earned_slot_count()) + "/" + str(region_state.get_max_region_level()),
		"Pending level-ups: " + str(region_state.pending_level_ups)
	]
	return section


static func build_confirm_choice(region_state: RegionState) -> DecisionChoiceData:
	var choice := DecisionChoiceData.new()
	choice.id = "confirm_level_up"
	choice.label = "Authorise"
	choice.style = "primary"
	choice.tooltip = "Spend Power and Compute to confirm the regional level-up."
	choice.power_cost = region_state.get_next_level_up_power_cost()
	choice.compute_cost = region_state.get_next_level_up_compute_cost()
	return choice


static func build_defer_choice() -> DecisionChoiceData:
	var choice := DecisionChoiceData.new()
	choice.id = "defer"
	choice.label = "Defer"
	choice.style = "normal"
	choice.tooltip = "Move this level-up to pending decisions."
	return choice