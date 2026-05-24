extends PanelContainer

signal map_view_selected(view_name: String)

@onready var tab_bar: TabBar = $TabBar

func _ready() -> void:
	tab_bar.current_tab = 0
	tab_bar.tab_changed.connect(_on_tab_changed)

func _on_tab_changed(tab_index: int) -> void:
	if tab_index == 0:
		map_view_selected.emit("infiltration")
	elif tab_index == 1:
		map_view_selected.emit("expansion")
