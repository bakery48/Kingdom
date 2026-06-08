extends Control

signal close_requested

@onready var _title_label: Label         = $Panel/Margin/VBox/HeaderRow/TitleLabel
@onready var _info_label: Label          = $Panel/Margin/VBox/InfoLabel
@onready var _text_display: RichTextLabel = $Panel/Margin/VBox/Scroll/TextDisplay
@onready var _filter_option: OptionButton = $Panel/Margin/VBox/FilterRow/FilterOption
@onready var _gen_count_label: Label     = $Panel/Margin/VBox/FilterRow/GenCountLabel

# World-change type colours (BBCode)
const _COL_BUILD   := "#88cc88"
const _COL_BATTLE  := "#ff8888"
const _COL_ROAD    := "#88bbff"
const _COL_ALLY    := "#cc99ff"
const _COL_HEADER  := "#ffdd88"
const _COL_MUTED   := "#888888"
const _COL_INHERIT := "#ffcc66"


func _ready() -> void:
	GameData.generation_ended.connect(_on_data_changed)
	GameData.world_changed.connect(_on_world_changed)
	_populate_filter()
	_display_chronicle()


# ---------------------------------------------------------------------------
# Filter
# ---------------------------------------------------------------------------

func _populate_filter() -> void:
	_filter_option.clear()
	_filter_option.add_item("全世代", -1)
	var all_gens := GameData.get_all_generations()
	for gen in all_gens:
		var suffix := "（活動中）" if gen.is_alive() else "（享年%d）" % gen.get_lifespan()
		_filter_option.add_item("第%d世代 %s %s" % [gen.id, gen.name, suffix], gen.id)
	_gen_count_label.text = "計%d世代" % all_gens.size()

	# Update info label
	var clan := GameData.clan_name if GameData.clan_name != "" else "―"
	_title_label.text = "%s家　年代記" % clan
	_info_label.text = "第%d世代　|　創業 %d年" % [GameData.current_generation, GameData.total_years]


# ---------------------------------------------------------------------------
# Display dispatch
# ---------------------------------------------------------------------------

func _display_chronicle() -> void:
	var selected_id: int = -1
	if _filter_option.selected > 0:
		selected_id = _filter_option.get_item_id(_filter_option.selected)

	_text_display.clear()
	if selected_id == -1:
		_text_display.append_text(_build_full_chronicle())
	else:
		_text_display.append_text(_build_single_gen(selected_id))


# ---------------------------------------------------------------------------
# Full chronicle (all generations)
# ---------------------------------------------------------------------------

func _build_full_chronicle() -> String:
	var b: PackedStringArray = []

	b.append(_h("═══ %s家　年代記 ═══" % GameData.clan_name))
	b.append(_muted("現在 第%d世代　|　総経過 %d年" % [
		GameData.current_generation, GameData.total_years
	]))
	b.append(_muted(GameData.world_state.get_progress_label()))
	b.append("")

	var all_gens := GameData.get_all_generations()
	if all_gens.is_empty():
		b.append(_muted("まだ記録がありません。"))
	for gen in all_gens:
		b.append(_format_gen_entry(gen))
		b.append("")

	return "\n".join(b)


# ---------------------------------------------------------------------------
# Single generation detail
# ---------------------------------------------------------------------------

func _build_single_gen(gen_id: int) -> String:
	var gen := GameData.get_generation_by_id(gen_id)
	if gen == null:
		return _muted("世代が見つかりません (id=%d)" % gen_id)

	var b: PackedStringArray = []
	b.append(_format_gen_entry(gen))
	return "\n".join(b)


# ---------------------------------------------------------------------------
# Per-generation formatter
# ---------------------------------------------------------------------------

func _format_gen_entry(gen: Generation) -> String:
	var b: PackedStringArray = []

	# ── Header ──
	var is_active := gen.is_alive()
	var title := "── 第%d世代　%s" % [gen.id, gen.name]
	title += "　（活動中）" if is_active else " ──"
	b.append(_h(title))

	# Dates / lifespan
	if is_active:
		var age := GameData.total_years - gen.birth_year
		b.append("　%d年生まれ　現在 [b]%d歳[/b]　（寿命目安: %d歳）" % [
			gen.birth_year, age, gen.max_age
		])
	else:
		b.append("　%d年生まれ → %d年没　享年[b]%d[/b]　%s" % [
			gen.birth_year, gen.death_year,
			gen.get_lifespan(),
			_cause_colored(gen.cause_of_death)
		])
	b.append("")

	# Skills
	b.append("[b]スキル[/b]")
	if gen.skills.is_empty():
		b.append(_muted("　（なし）"))
	else:
		for skill in gen.skills:
			var cat_col := _category_color(skill.category)
			var line := "　[color=%s]・%s　Lv%d[/color]　[color=%s][%s][/color]" % [
				cat_col, skill.display_name, skill.level,
				_COL_MUTED, skill.get_category_label()
			]
			if skill.inherited_from_generation != -1:
				line += "　[color=%s]← 第%d世代より[/color]" % [
					_COL_INHERIT, skill.inherited_from_generation
				]
			b.append(line)
	b.append("")

	# World changes
	b.append("[b]世界への貢献[/b]")
	if gen.world_changes.is_empty():
		b.append(_muted("　（なし）"))
	else:
		for change in gen.world_changes:
			b.append(_format_world_change(change))
	b.append("")

	# Achievements
	b.append("[b]功績[/b]")
	if gen.achievements.is_empty():
		b.append(_muted("　（なし）"))
	else:
		for ach in gen.achievements:
			b.append("　[color=%s]◆[/color] %s" % [_COL_HEADER, ach])
	b.append("")

	# Items
	if not gen.equipped_items.is_empty():
		b.append("[b]形見の品[/b]")
		for item in gen.equipped_items:
			b.append("　[color=#dddddd]・%s[/color] %s" % [
				item.display_name, item.get_heirloom_label()
			])
			if item.description != "":
				b.append(_muted("　　　" + item.description))
		b.append("")

	var pt_min := int(gen.play_time_seconds / 60.0)
	b.append(_muted("　プレイ時間: %d分" % pt_min))

	return "\n".join(b)


# ---------------------------------------------------------------------------
# World change entry
# ---------------------------------------------------------------------------

func _format_world_change(change: WorldChange) -> String:
	var col := _change_color(change.type)
	return "　[color=%s]▶ [%s][/color]　%s　[color=%s]%d年 / (%d,%d)[/color]" % [
		col, change.get_type_label(), change.description,
		_COL_MUTED, change.year, change.location_x, change.location_y
	]


# ---------------------------------------------------------------------------
# Colour / style helpers
# ---------------------------------------------------------------------------

func _h(text: String) -> String:
	return "[color=%s][b]%s[/b][/color]" % [_COL_HEADER, text]

func _muted(text: String) -> String:
	return "[color=%s]%s[/color]" % [_COL_MUTED, text]

func _cause_colored(cause: String) -> String:
	match cause:
		"battle":
			return "[color=%s]戦死[/color]" % _COL_BATTLE
		"old_age":
			return "[color=%s]老衰[/color]" % _COL_MUTED
		"retired":
			return "[color=%s]引退[/color]" % _COL_ROAD
	return cause

func _category_color(category: String) -> String:
	match category:
		"combat":    return "#ff9988"
		"exploration": return "#88cc88"
		"life":      return "#ffdd88"
	return "#dddddd"

func _change_color(type: String) -> String:
	match type:
		"build":         return _COL_BUILD
		"clear_monster": return _COL_BATTLE
		"open_road":     return _COL_ROAD
		"alliance":      return _COL_ALLY
	return "#dddddd"


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
