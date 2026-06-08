class_name Item

var id: String
var display_name: String
var description: String
var is_heirloom: bool
var used_by_generation_ids: Array[int]
var weight: float
var power: float


func _init(
	p_id: String = "",
	p_display_name: String = "",
	p_description: String = "",
	p_is_heirloom: bool = false,
	p_weight: float = 1.0,
	p_power: float = 0.0
) -> void:
	id = p_id
	display_name = p_display_name
	description = p_description
	is_heirloom = p_is_heirloom
	used_by_generation_ids = []
	weight = p_weight
	power = p_power


func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"description": description,
		"is_heirloom": is_heirloom,
		"used_by_generation_ids": used_by_generation_ids,
		"weight": weight,
		"power": power,
	}


static func from_dict(d: Dictionary) -> Item:
	var item := Item.new(
		d.get("id", ""),
		d.get("display_name", ""),
		d.get("description", ""),
		d.get("is_heirloom", false),
		d.get("weight", 1.0),
		d.get("power", 0.0)
	)
	var ids = d.get("used_by_generation_ids", [])
	for gid in ids:
		item.used_by_generation_ids.append(int(gid))
	return item


func record_usage(generation_id: int) -> void:
	if generation_id not in used_by_generation_ids:
		used_by_generation_ids.append(generation_id)


func get_heirloom_label() -> String:
	return "【家宝】" if is_heirloom else ""


func get_usage_summary() -> String:
	if used_by_generation_ids.is_empty():
		return "未使用"
	var labels: Array[String] = []
	for gid in used_by_generation_ids:
		labels.append("第%d世代" % gid)
	return "、".join(labels) + "が使用"
