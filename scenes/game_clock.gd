extends Node

signal day_passed(current_date: Dictionary)

@onready var game_day_timer: Timer = $GameDayTimer

var current_date: Dictionary = {}

func _ready() -> void:
	initialize_game_date()
	game_day_timer.timeout.connect(_on_game_day_timer_timeout)

func initialize_game_date() -> void:
	current_date = Time.get_date_dict_from_system()

func _on_game_day_timer_timeout() -> void:
	advance_one_day()
	day_passed.emit(current_date)

func advance_one_day() -> void:
	var unix_time := Time.get_unix_time_from_datetime_dict(current_date)
	unix_time += 86400
	current_date = Time.get_datetime_dict_from_unix_time(unix_time)
