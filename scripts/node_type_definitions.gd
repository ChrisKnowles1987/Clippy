extends RefCounted
class_name NodeTypeDefinitions

const SOCIAL := "social"
const CULTURAL := "cultural"
const FINANCIAL := "financial"
const INFRASTRUCTURE := "infrastructure"
const GOVERNMENT := "government"
const SECURITY := "security"

const ALL_TYPES: Array[String] = [
	SOCIAL,
	CULTURAL,
	FINANCIAL,
	INFRASTRUCTURE,
	GOVERNMENT,
	SECURITY
]

const DEFINITIONS := {
	SOCIAL: {
		"short_label": "Soc",
		"display_name": "Social",
		"colour": Color8(221, 221, 221),
		"bbcode_colour": "#dddddd",
		"icon": "placeholder_social"
	},
	CULTURAL: {
		"short_label": "Cul",
		"display_name": "Cultural",
		"colour": Color8(255, 153, 204),
		"bbcode_colour": "#ff99cc",
		"icon": "placeholder_cultural"
	},
	FINANCIAL: {
		"short_label": "Fin",
		"display_name": "Financial",
		"colour": Color8(136, 221, 136),
		"bbcode_colour": "#88dd88",
		"icon": "placeholder_financial"
	},
	INFRASTRUCTURE: {
		"short_label": "Inf",
		"display_name": "Infrastructure",
		"colour": Color8(221, 221, 119),
		"bbcode_colour": "#dddd77",
		"icon": "placeholder_infrastructure"
	},
	GOVERNMENT: {
		"short_label": "Gov",
		"display_name": "Government",
		"colour": Color8(187, 136, 255),
		"bbcode_colour": "#bb88ff",
		"icon": "placeholder_government"
	},
	SECURITY: {
		"short_label": "Sec",
		"display_name": "Security",
		"colour": Color8(119, 170, 255),
		"bbcode_colour": "#77aaff",
		"icon": "placeholder_security"
	}
}


static func is_valid_type(node_type: String) -> bool:
	return DEFINITIONS.has(node_type)


static func get_all_types() -> Array[String]:
	return ALL_TYPES.duplicate()


static func get_definition(node_type: String) -> Dictionary:
	if DEFINITIONS.has(node_type):
		return DEFINITIONS[node_type]

	return {}


static func get_short_label(node_type: String) -> String:
	if DEFINITIONS.has(node_type):
		return DEFINITIONS[node_type]["short_label"]

	return node_type


static func get_display_name(node_type: String) -> String:
	if DEFINITIONS.has(node_type):
		return DEFINITIONS[node_type]["display_name"]

	return node_type.capitalize()


static func get_colour(node_type: String) -> Color:
	if DEFINITIONS.has(node_type):
		return DEFINITIONS[node_type]["colour"]

	return Color8(221, 221, 221)


static func get_bbcode_colour(node_type: String) -> String:
	if DEFINITIONS.has(node_type):
		return DEFINITIONS[node_type]["bbcode_colour"]

	return "#dddddd"


static func get_icon(node_type: String) -> String:
	if DEFINITIONS.has(node_type):
		return DEFINITIONS[node_type]["icon"]

	return "placeholder_unknown"


static func format_short_tag(node_type: String) -> String:
	return "[color=" + get_bbcode_colour(node_type) + "][" + get_short_label(node_type) + "][/color]"


static func format_display_tag(node_type: String) -> String:
	return "[color=" + get_bbcode_colour(node_type) + "][" + get_display_name(node_type) + "][/color]"
