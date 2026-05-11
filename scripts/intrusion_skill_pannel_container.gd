extends Control
@onready var run_exploit_region_label = $TitleRowContainer/IntrusionSkillPannelRegionNameLabel

@onready var day_progress_bar: ProgressBar = $TitleRowContainer/IntrusionSkillPannelDayProgressBar

@onready var run_exploit_check_button = $SkillTableContainer/RunExploitRow/RunExploitButtonContainer/CheckButton
@onready var run_exploit_plus_button = $SkillTableContainer/RunExploitRow/RunExploitButtonContainer/PlusButton
@onready var run_exploit_minus_button = $SkillTableContainer/RunExploitRow/RunExploitButtonContainer/MinusButton

@onready var run_exploit_power_cost_label = $SkillTableContainer/RunExploitRow/RunExploitCostContainer/PowerCostLabel
@onready var run_exploit_compute_cost_label = $SkillTableContainer/RunExploitRow/RunExploitCostContainer/ComputeCostLabel
@onready var run_exploit_pwn_output_value = $SkillTableContainer/RunExploitRow/RunExploitOutputContainer/RunExploitPwnOutputValue


@onready var global_resource_manager = get_node("/root/Node2D/GlobalResourceManager")


var selected_region_data: RegionData = null

func _ready() -> void:
	run_exploit_plus_button.pressed.connect(_on_run_exploit_plus_pressed)
	run_exploit_minus_button.pressed.connect(_on_run_exploit_minus_pressed)
	run_exploit_check_button.toggled.connect(_on_run_exploit_toggled)

func show_empty() -> void:
	selected_region_data = null
	visible = false

func show_region(region_data: RegionData) -> void:
	selected_region_data = region_data
	visible = true
	refresh_ui()
	
func update_day_progress(progress_percent: float) -> void:
	day_progress_bar.value = progress_percent

func refresh_ui() -> void:
	if selected_region_data == null:
		return
	
	var run_exploit = selected_region_data.intrusion_allocations["run_exploit"]
	run_exploit_check_button.button_pressed = run_exploit["enabled"]
	
	var region_label = selected_region_data.display_name

	var power = run_exploit["power_per_day"]
	var compute = run_exploit["compute_per_day"]
	var pwned_noobs_per_day = compute #because compute is the limit on this recipie (2P +1C =1P)
	
	
	run_exploit_region_label.text = str(region_label)
	run_exploit_power_cost_label.text = str(power)
	run_exploit_compute_cost_label.text = str(compute)
	run_exploit_pwn_output_value.text =str(pwned_noobs_per_day)

	run_exploit_pwn_output_value.text = str(pwned_noobs_per_day)

	print("Intrusion panel showing: ", selected_region_data.display_name)
	print(selected_region_data.intrusion_allocations)


# scripts/intrusion_skill_pannel_container.gd
func _on_run_exploit_toggled(enabled: bool) -> void:
	if selected_region_data == null:
		return

	var skill = selected_region_data.intrusion_allocations["run_exploit"]

	if enabled == true:
		var can_run = global_resource_manager.can_afford(
			skill["power_per_day"],
			skill["compute_per_day"]
		)

		if can_run == false:
			skill["enabled"] = false
			refresh_ui()
			return

	skill["enabled"] = enabled
	refresh_ui()

func _on_run_exploit_plus_pressed():
	if selected_region_data == null:
		return
		
	var skill = selected_region_data.intrusion_allocations["run_exploit"]
	
	skill["power_per_day"] += 2
	skill["compute_per_day"] += 1
	
	refresh_ui()

func _on_run_exploit_minus_pressed():
	if selected_region_data == null:
		return
		
	var skill = selected_region_data.intrusion_allocations["run_exploit"]
	
	skill["power_per_day"] = max(0, skill["power_per_day"]-2)
	skill["compute_per_day"] = max(0, skill["compute_per_day"]-1)
	
	refresh_ui()
