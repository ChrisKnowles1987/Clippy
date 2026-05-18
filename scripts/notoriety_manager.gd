extends Node
class_name NotorietyManager

const STAR_THRESHOLDS := [100.0, 250.0, 475.0, 800.0, 1250.0]


func get_star_count(notoriety_xp: float) -> int:
	var stars := 0

	for threshold in STAR_THRESHOLDS:
		if notoriety_xp >= threshold:
			stars += 1

	return stars


func get_star_text(stars: int, max_stars: int = 5) -> String:
	stars = clamp(stars, 0, max_stars)

	var text := ""

	for i in range(max_stars):
		if i < stars:
			text += "★"
		else:
			text += "☆"

	return text


func get_star_text_from_xp(notoriety_xp: float) -> String:
	return get_star_text(get_star_count(notoriety_xp))
