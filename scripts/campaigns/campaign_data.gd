extends Resource
class_name CampaignData

var id: String = ""
var display_name: String = ""
var description: String = ""

var min_soc: int = 0
var min_cul: int = 0
var min_fin: int = 0
var min_inf: int = 0
var min_gov: int = 0
var min_sec: int = 0

var required_slots: Array[String] = []

var coin_cost: float = 0.0
var duration_days: int = 10
var effect_id: String = ""
