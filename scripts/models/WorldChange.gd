class_name WorldChange

var type: String  # "build", "clear_monster", "open_road", "alliance"
var description: String
var location_x: int
var location_y: int
var generation_id: int
var year: int


func _init(
	p_type: String = "build",
	p_description: String = "",
	p_location_x: int = 0,
	p_location_y: int = 0,
	p_generation_id: int = 0,
	p_year: int = 0
) -> void:
	type = p_type
	description = p_description
	location_x = p_location_x
	location_y = p_location_y
	generation_id = p_generation_id
	year = p_year


func to_dict() -> Dictionary:
	return {
		"type": type,
		"description": description,
		"location_x": location_x,
		"location_y": location_y,
		"generation_id": generation_id,
		"year": year,
	}


static func from_dict(d: Dictionary) -> WorldChange:
	return WorldChange.new(
		d.get("type", "build"),
		d.get("description", ""),
		d.get("location_x", 0),
		d.get("location_y", 0),
		d.get("generation_id", 0),
		d.get("year", 0)
	)


func get_type_label() -> String:
	match type:
		"build":
			return "建設"
		"clear_monster":
			return "討伐"
		"open_road":
			return "開通"
		"alliance":
			return "同盟"
	return type


func get_location_label() -> String:
	return "(%d, %d)" % [location_x, location_y]


func get_summary() -> String:
	return "[%s] %s ― %d年、%sにて（第%d世代）" % [
		get_type_label(),
		description,
		year,
		get_location_label(),
		generation_id
	]
