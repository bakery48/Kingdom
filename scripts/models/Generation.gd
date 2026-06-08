class_name Generation

var id: int
var name: String
var birth_year: int
var death_year: int
var cause_of_death: String  # "old_age", "battle", "retired"
var skills: Array[Skill]
var equipped_items: Array[Item]
var achievements: Array[String]
var world_changes: Array[WorldChange]
var play_time_seconds: float


func _init(
	p_id: int = 0,
	p_name: String = "",
	p_birth_year: int = 1
) -> void:
	id = p_id
	name = p_name
	birth_year = p_birth_year
	death_year = -1
	cause_of_death = ""
	skills = []
	equipped_items = []
	achievements = []
	world_changes = []
	play_time_seconds = 0.0


func is_alive() -> bool:
	return death_year == -1


func get_lifespan() -> int:
	if death_year == -1:
		return -1
	return death_year - birth_year


func add_skill(skill: Skill) -> void:
	# Enforce max 3 skills
	if skills.size() < 3:
		skills.append(skill)


func add_item(item: Item) -> void:
	# Enforce max 2 items
	if equipped_items.size() < 2:
		item.record_usage(id)
		equipped_items.append(item)


func add_achievement(achievement: String) -> void:
	if achievement not in achievements:
		achievements.append(achievement)


func add_world_change(change: WorldChange) -> void:
	world_changes.append(change)


func finalize(year: int, cause: String) -> void:
	death_year = year
	cause_of_death = cause


func get_cause_of_death_label() -> String:
	match cause_of_death:
		"old_age":
			return "老衰"
		"battle":
			return "戦死"
		"retired":
			return "引退"
	return cause_of_death if cause_of_death != "" else "不明"


func get_title() -> String:
	return "第%d世代　%s" % [id, name]


func to_dict() -> Dictionary:
	var skills_data: Array = []
	for skill in skills:
		skills_data.append(skill.to_dict())

	var items_data: Array = []
	for item in equipped_items:
		items_data.append(item.to_dict())

	var changes_data: Array = []
	for change in world_changes:
		changes_data.append(change.to_dict())

	return {
		"id": id,
		"name": name,
		"birth_year": birth_year,
		"death_year": death_year,
		"cause_of_death": cause_of_death,
		"skills": skills_data,
		"equipped_items": items_data,
		"achievements": achievements,
		"world_changes": changes_data,
		"play_time_seconds": play_time_seconds,
	}


static func from_dict(d: Dictionary) -> Generation:
	var gen := Generation.new(
		d.get("id", 0),
		d.get("name", ""),
		d.get("birth_year", 1)
	)
	gen.death_year = d.get("death_year", -1)
	gen.cause_of_death = d.get("cause_of_death", "")
	gen.play_time_seconds = d.get("play_time_seconds", 0.0)

	for ad in d.get("achievements", []):
		gen.achievements.append(str(ad))

	for sd in d.get("skills", []):
		gen.skills.append(Skill.from_dict(sd))

	for id_data in d.get("equipped_items", []):
		gen.equipped_items.append(Item.from_dict(id_data))

	for cd in d.get("world_changes", []):
		gen.world_changes.append(WorldChange.from_dict(cd))

	return gen
