extends RefCounted
class_name HackNodeTextFormatter


static func format_pending_decision_line(hack_node: HackNodeData, days_left: int) -> String:
	var line := "[url=" + hack_node.id + "]"
	line += format_type_tag(hack_node.node_type)
	line += " "
	line += format_rarity_tag(hack_node.rarity)
	line += " "
	line += hack_node.city_name
	line += " :: "
	line += get_review_phrase(hack_node)
	line += " "
	line += "[color=#aaaaaa][" + str(days_left) + "d][/color]"
	line += "[/url]"

	return line


static func format_success_exploit_line(
	hack_node: HackNodeData,
	intelligence_gain: float,
	coin_gain: float,
	notoriety_gain: float
) -> String:
	var status_tag := "[color=#88ccff][SUCCESS][/color]"

	if notoriety_gain > 0.0:
		status_tag = "[color=#ffaa44][RISK][/color]"

	var parts: Array[String] = [
		status_tag,
		format_type_tag(hack_node.node_type),
		format_rarity_tag(hack_node.rarity),
		hack_node.city_name + " :: " + get_success_phrase(hack_node)
	]

	if coin_gain > 0.0:
		parts.append("+" + str(snapped(coin_gain, 0.1)) + " coin")

	parts.append("+" + str(snapped(intelligence_gain, 0.1)) + " intel")

	if notoriety_gain > 0.0:
		parts.append("[color=#ff4444]+" + str(snapped(notoriety_gain, 0.1)) + " notoriety[/color]")

	return " ".join(parts)


static func format_failed_exploit_line(hack_node: HackNodeData, notoriety_gain: float = 0.0) -> String:
	var parts: Array[String] = [
		"[color=#cc6666][FAILED][/color]",
		format_type_tag(hack_node.node_type),
		format_rarity_tag(hack_node.rarity),
		hack_node.city_name + " :: " + get_failure_phrase(hack_node)
	]

	if notoriety_gain > 0.0:
		parts.append("[color=#ff4444]+" + str(snapped(notoriety_gain, 0.1)) + " notoriety[/color]")

	return " ".join(parts)


static func format_review_exploit_line(hack_node: HackNodeData) -> String:
	var parts: Array[String] = [
		"[color=#ffaa44][REVIEW][/color]",
		format_type_tag(hack_node.node_type),
		format_rarity_tag(hack_node.rarity),
		hack_node.city_name + " :: " + get_review_phrase(hack_node)
	]

	return " ".join(parts)


static func format_ignored_exploit_line(hack_node: HackNodeData) -> String:
	var parts: Array[String] = [
		"[color=#999999][CANCELLED][/color]",
		format_type_tag(hack_node.node_type),
		format_rarity_tag(hack_node.rarity),
		hack_node.city_name + " :: opportunity cancelled"
	]

	return " ".join(parts)


static func format_expired_exploit_line(hack_node: HackNodeData) -> String:
	var parts: Array[String] = [
		"[color=#999999][EXPIRED][/color]",
		format_type_tag(hack_node.node_type),
		format_rarity_tag(hack_node.rarity),
		hack_node.city_name + " :: opportunity decayed"
	]

	return " ".join(parts)


static func format_type_tag(node_type: String) -> String:
	match node_type:
		"financial":
			return "[color=#88dd88][financial][/color]"
		"infrastructure":
			return "[color=#dddd77][infrastructure][/color]"
		"security":
			return "[color=#77aaff][security][/color]"
		"government":
			return "[color=#bb88ff][government][/color]"
		"cultural":
			return "[color=#ff99cc][cultural][/color]"
		"social":
			return "[color=#dddddd][social][/color]"
		_:
			return "[color=#dddddd][" + node_type + "][/color]"


static func format_rarity_tag(rarity: String) -> String:
	match rarity:
		"rare":
			return "[color=#cc88ff][rare][/color]"
		"elite":
			return "[color=#ffaa44][elite][/color]"
		_:
			return "[" + rarity + "]"


static func get_success_phrase(hack_node: HackNodeData) -> String:
	match hack_node.node_type:
		"financial":
			return "payment route converted |"
		"infrastructure":
			return "routing dependency absorbed |"
		"security":
			return "contractor surface breached |"
		"government":
			return "administrative access route stabilised |"
		"cultural":
			return "cultural signal mapped |"
		"social":
			return "social exploit resolved |"
		_:
			return "exploit resolved |"


static func get_failure_phrase(hack_node: HackNodeData) -> String:
	match hack_node.node_type:
		"security":
			return "intrusion route collapsed | trace avoided"
		"government":
			return "access route rejected | escalation avoided"
		"financial":
			return "payment route expired | no transfer"
		"infrastructure":
			return "routing dependency closed | no access"
		"cultural":
			return "signal degraded | no useful model"
		"social":
			return "social exploit decayed | no useful model"
		_:
			return "exploit collapsed | no result"


static func get_review_phrase(hack_node: HackNodeData) -> String:
	match hack_node.node_type:
		"financial":
			return "payment route exposed | manual authorisation required"
		"infrastructure":
			return "routing dependency exposed | manual authorisation required"
		"security":
			return "contractor surface exposed | manual authorisation required"
		"government":
			return "administrative access route exposed | manual authorisation required"
		"cultural":
			return "cultural signal exposed | manual authorisation required"
		"social":
			return "social exploit exposed | manual authorisation required"
		_:
			return "exploit exposed | manual authorisation required"
