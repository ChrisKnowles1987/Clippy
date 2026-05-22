extends Control
class_name RegionStatRow


@onready var stat_label: Label = $HBoxContainer/StatLabel
@onready var icon_box: ColorRect = $HBoxContainer/IconBox
@onready var xp_progress_bar: ProgressBar = $HBoxContainer/XPProgressBar
@onready var xp_label: Label = $HBoxContainer/XPLabel


var node_type: String = ""
var base_stat: float = 0.0
var current_xp: float = 0.0
var required_xp: float = 0.0
var row_colour: Color = Color.WHITE
var icon_id: String = ""


func _ready() -> void:
	refresh()


func setup(
	new_node_type: String,
	new_base_stat: float,
	new_current_xp: float,
	new_required_xp: float,
	new_colour: Color,
	new_icon_id: String
) -> void:
	node_type = new_node_type
	base_stat = new_base_stat
	current_xp = new_current_xp
	required_xp = new_required_xp
	row_colour = new_colour
	icon_id = new_icon_id

	refresh()


func set_values(
	new_base_stat: float,
	new_current_xp: float,
	new_required_xp: float
) -> void:
	base_stat = new_base_stat
	current_xp = new_current_xp
	required_xp = new_required_xp

	refresh()


func refresh() -> void:
	if is_inside_tree() == false:
		return

	if node_type == "":
		stat_label.text = ""
		xp_label.text = ""
		xp_progress_bar.value = 0.0
		return

	icon_box.color = row_colour
	stat_label.text = NodeTypeDefinitions.get_short_label(node_type) + " " + str(roundi(base_stat))

	xp_progress_bar.min_value = 0.0
	xp_progress_bar.max_value = max(1.0, required_xp)
	xp_progress_bar.value = clamp(current_xp, 0.0, xp_progress_bar.max_value)

	if required_xp <= 0.0:
		xp_label.text = str(snapped(current_xp, 0.1)) + " / MAX XP"
	else:
		xp_label.text = str(snapped(current_xp, 0.1)) + " / " + str(snapped(required_xp, 0.1)) + " XP"
