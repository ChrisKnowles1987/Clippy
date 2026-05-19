extends RefCounted
class_name HackDecisionBuilder


static func build_decision(hack_node: HackNodeData, terminal_line: String, days_left: int) -> DecisionData:
	var decision := DecisionData.new()

	decision.id = hack_node.id
	decision.title = hack_node.node_type.capitalize() + " node"
	decision.subtitle = hack_node.city_name + " / " + hack_node.rarity.capitalize()
	decision.region_id = hack_node.region_id
	decision.source_type = "hack_node"
	decision.terminal_text = terminal_line
	decision.expires_on_day = hack_node.expires_on_day

	decision.sections.append(build_cost_section(hack_node))
	decision.sections.append(build_risk_section(hack_node))
	decision.sections.append(build_success_section(hack_node))
	decision.sections.append(build_failure_section(hack_node))

	decision.choices.append(build_choice("execute", "Proceed", "primary"))
	decision.choices.append(build_choice("defer", "Defer", "normal"))
	decision.choices.append(build_choice("ignore", "Cancel", "danger"))

	if days_left > 0:
		var expiry_section := DecisionSectionData.new()
		expiry_section.title = "Expiry"
		expiry_section.style = "muted"
		expiry_section.rows = [str(days_left) + " days left"]
		decision.sections.append(expiry_section)

	return decision


static func build_cost_section(hack_node: HackNodeData) -> DecisionSectionData:
	var section := DecisionSectionData.new()
	section.title = "Cost"
	section.style = "cost"
	section.rows = [
		"[color=#88ccff]Compute:[/color] " + str(snapped(hack_node.processing_required, 0.1))
	]
	return section


static func build_risk_section(hack_node: HackNodeData) -> DecisionSectionData:
	var section := DecisionSectionData.new()
	section.title = "Risk"
	section.style = "risk"

	var chance := get_possible_notoriety_chance_text(hack_node)
	var gain := get_possible_notoriety_gain(hack_node)

	if gain > 0.0:
		section.rows = [
			"[color=#ff4444]Exposure possible[/color]",
			"[color=#999999]Estimated exposure:[/color] " + str(snapped(gain, 0.1)) + " notoriety XP",
			"[color=#999999]Chance profile:[/color] " + chance
		]
	else:
		section.rows = [
			"[color=#999999]No major exposure expected[/color]"
		]

	return section


static func build_success_section(hack_node: HackNodeData) -> DecisionSectionData:
	var section := DecisionSectionData.new()
	section.title = "On success"
	section.style = "success"

	section.rows.append("[color=#88ccff]+[/color] " + str(snapped(hack_node.intelligence_reward, 0.1)) + " intelligence")

	if hack_node.coin_reward > 0.0:
		section.rows.append("[color=#88dd88]+[/color] " + str(snapped(hack_node.coin_reward, 0.1)) + " coin")

	if get_possible_notoriety_gain(hack_node) > 0.0:
		section.rows.append("[color=#ff4444]+[/color] possible notoriety exposure")

	return section


static func build_failure_section(hack_node: HackNodeData) -> DecisionSectionData:
	var section := DecisionSectionData.new()
	section.title = "On failure"
	section.style = "failure"

	section.rows = [
		"[color=#cc6666]Node fails[/color]",
		"[color=#999999]No intelligence gained[/color]"
	]

	if get_possible_notoriety_gain(hack_node) > 0.0:
		section.rows.append("[color=#ff4444]+[/color] possible notoriety exposure")

	return section


static func build_choice(id: String, label: String, style: String) -> DecisionChoiceData:
	var choice := DecisionChoiceData.new()
	choice.id = id
	choice.label = label
	choice.style = style
	return choice


static func get_possible_notoriety_gain(hack_node: HackNodeData) -> float:
	var gain := 8.0

	match hack_node.node_type:
		"social":
			gain = 5.0
		"cultural":
			gain = 6.0
		"financial":
			gain = 10.0
		"infrastructure":
			gain = 12.0
		"government":
			gain = 18.0
		"security":
			gain = 24.0

	match hack_node.rarity:
		"common":
			gain *= 0.75
		"rare":
			gain *= 1.75
		"elite":
			gain *= 2.75

	return gain


static func get_possible_notoriety_chance_text(hack_node: HackNodeData) -> String:
	match hack_node.node_type:
		"social":
			return "low"
		"cultural":
			return "low"
		"financial":
			return "moderate"
		"infrastructure":
			return "moderate"
		"government":
			return "high"
		"security":
			return "critical"

	return "unknown"
