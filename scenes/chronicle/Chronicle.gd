extends Control

# ---------------------------------------------------------------------------
# Chronicle viewer — displays the full clan history
# ---------------------------------------------------------------------------

signal close_requested

@onready var _text_display: RichTextLabel = $Panel/VBox/ScrollContainer/TextDisplay
@onready var _close_button: Button        = $Panel/VBox/CloseButton
@onready var _filter_option: OptionButton = $Panel/VBox/FilterRow/FilterOption
@onready var _gen_count_label: Label      = $Panel/VBox/FilterRow/GenCountLabel


func _ready() -> void:
	_populate_filter()
	_display_chronicle()
	GameData.generation_ended.connect(_on_data_changed)
	GameData.world_changed.connect(_on_world_changed)


# ---------------------------------------------------------------------------
# Display
# ---------------------------------------------------------------------------

func _populate_filter() -> void:
	_filter_option.clear()
	_filter_option.add_item("全世代", -1)
	var all_gens := GameData.get_all_generations()
	for gen in all_gens:
		_filter_option.add_item("第%d世代 %s" % [gen.id, gen.name], gen.id)
	_gen_count_label.text = "計%d世代" % all_gens.size()


func _display_chronicle() -> void:
	var selected_id: int = -1
	if _filter_option.selected > 0:
		selected_id = _filter_option.get_item_id(_filter_option.selected)

	if selected_id == -1:
		_text_display.text = GameData.get_chronicle_text()
	else:
		_display_single_generation(selected_id)


func _display_single_generation(gen_id: int) -> void:
	var gen := GameData.get_generation_by_id(gen_id)
	if gen == null:
		_text_display.text = "世代が見つかりません (id=%d)" % gen_id
		return

	var lines: Array[String] = []
	lines.append("[b]%s[/b]" % gen.get_title())
	lines.append("")

	# Dates
	var birth_info := "生年: [b]%d年[/b]" % gen.birth_year
	if gen.death_year != -1:
		birth_info += "　没年: [b]%d年[/b]（享年%d）" % [gen.death_year, gen.get_lifespan()]
		birth_info += "　死因: %s" % gen.get_cause_of_death_label()
	else:
		birth_info += "　（活動中）"
	lines.append(birth_info)
	lines.append("")

	# Skills
	lines.append("[b]スキル[/b]")
	if gen.skills.is_empty():
		lines.append("　（なし）")
	else:
		for skill in gen.skills:
			lines.append("　・%s Lv%d [%s] %s" % [
				skill.display_name,
				skill.level,
				skill.get_category_label(),
				skill.get_inheritance_label()
			])
	lines.append("")

	# Items
	lines.append("[b]所持品[/b]")
	if gen.equipped_items.is_empty():
		lines.append("　（なし）")
	else:
		for item in gen.equipped_items:
			lines.append("　・%s %s" % [item.display_name, item.get_heirloom_label()])
			if item.description != "":
				lines.append("　　　%s" % item.description)
			lines.append("　　　%s" % item.get_usage_summary())
	lines.append("")

	# World changes
	lines.append("[b]世界への貢献[/b]")
	if gen.world_changes.is_empty():
		lines.append("　（なし）")
	else:
		for change in gen.world_changes:
			lines.append("　▶ " + change.get_summary())
	lines.append("")

	# Achievements
	lines.append("[b]功績[/b]")
	if gen.achievements.is_empty():
		lines.append("　（なし）")
	else:
		for ach in gen.achievements:
			lines.append("　◆ " + ach)
	lines.append("")

	var pt_min := int(gen.play_time_seconds / 60.0)
	lines.append("プレイ時間: %d分" % pt_min)

	_text_display.bbcode_enabled = true
	_text_display.text = "\n".join(lines)


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

func _on_filter_option_item_selected(_index: int) -> void:
	_display_chronicle()


func _on_close_button_pressed() -> void:
	close_requested.emit()


func _on_data_changed(_gen) -> void:
	_populate_filter()
	_display_chronicle()


func _on_world_changed(_change) -> void:
	_display_chronicle()
