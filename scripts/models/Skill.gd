class_name Skill

var id: String
var display_name: String
var level: int
var category: String  # "combat", "exploration", "life"
var inherited_from_generation: int  # -1 if original


func _init(
	p_id: String = "",
	p_display_name: String = "",
	p_level: int = 1,
	p_category: String = "combat",
	p_inherited_from: int = -1
) -> void:
	id = p_id
	display_name = p_display_name
	level = p_level
	category = p_category
	inherited_from_generation = p_inherited_from


func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"level": level,
		"category": category,
		"inherited_from_generation": inherited_from_generation,
	}


static func from_dict(d: Dictionary) -> Skill:
	return Skill.new(
		d.get("id", ""),
		d.get("display_name", ""),
		d.get("level", 1),
		d.get("category", "combat"),
		d.get("inherited_from_generation", -1)
	)


func get_inheritance_label() -> String:
	if inherited_from_generation == -1:
		return "（自己習得）"
	return "（第%d世代より継承）" % inherited_from_generation


func get_category_label() -> String:
	match category:
		"combat":
			return "戦闘"
		"exploration":
			return "探索"
		"life":
			return "生活"
	return category
