class_name WorldState

var map_changes: Array[WorldChange]
var goal_progress: float  # 0.0 to 1.0
var friendly_factions: Array[String]


func _init() -> void:
	map_changes = []
	goal_progress = 0.0
	friendly_factions = []


func add_change(change: WorldChange) -> void:
	map_changes.append(change)
	_recalculate_progress()


func add_faction(faction_name: String) -> void:
	if faction_name not in friendly_factions:
		friendly_factions.append(faction_name)


func remove_faction(faction_name: String) -> void:
	friendly_factions.erase(faction_name)


func get_changes_at(x: int, y: int) -> Array[WorldChange]:
	var result: Array[WorldChange] = []
	for change in map_changes:
		if change.location_x == x and change.location_y == y:
			result.append(change)
	return result


func get_changes_by_type(change_type: String) -> Array[WorldChange]:
	var result: Array[WorldChange] = []
	for change in map_changes:
		if change.type == change_type:
			result.append(change)
	return result


func get_changes_by_generation(gen_id: int) -> Array[WorldChange]:
	var result: Array[WorldChange] = []
	for change in map_changes:
		if change.generation_id == gen_id:
			result.append(change)
	return result


func _recalculate_progress() -> void:
	# Goal: build legendary city — progress is driven by "build" changes
	# Each build contributes, capped at 1.0
	var build_count := 0
	for change in map_changes:
		if change.type == "build":
			build_count += 1
	# 20 major buildings to complete the legendary city
	goal_progress = clampf(float(build_count) / 20.0, 0.0, 1.0)


func get_progress_label() -> String:
	return "伝説の都市建設進捗: %.1f%%" % (goal_progress * 100.0)


func to_dict() -> Dictionary:
	var changes_data: Array = []
	for change in map_changes:
		changes_data.append(change.to_dict())
	return {
		"map_changes": changes_data,
		"goal_progress": goal_progress,
		"friendly_factions": friendly_factions,
	}


static func from_dict(d: Dictionary) -> WorldState:
	var ws := WorldState.new()
	ws.goal_progress = d.get("goal_progress", 0.0)
	var factions = d.get("friendly_factions", [])
	for f in factions:
		ws.friendly_factions.append(str(f))
	var changes_data = d.get("map_changes", [])
	for cd in changes_data:
		ws.map_changes.append(WorldChange.from_dict(cd))
	return ws
