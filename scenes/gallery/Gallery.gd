extends Control

signal close_requested

@onready var _grid: GridContainer       = $Panel/Margin/VBox/ContentRow/GridScroll/Grid
@onready var _gen_count_label: Label    = $Panel/Margin/VBox/HeaderRow/GenCountLabel
@onready var _detail_header: Label      = $Panel/Margin/VBox/ContentRow/DetailPane/DetailHeader
@onready var _detail_label: RichTextLabel = $Panel/Margin/VBox/ContentRow/DetailPane/DetailScroll/DetailLabel

const _COL_HEADER  := "#ffdd88"
const _COL_MUTED   := "#888888"
const _COL_INHERIT := "#ffcc66"
const _COL_ACTIVE  := "#aaffaa"


func _ready() -> void:
	GameData.generation_ended.connect(_on_new_generation_recorded)
	_build_gallery()
	_clear_detail()


# ---------------------------------------------------------------------------
# Gallery grid
# ---------------------------------------------------------------------------

func _build_gallery() -> void:
	for child in _grid.get_children():
		child.queue_free()

	var all_gens := GameData.get_all_generations()
	_gen_count_label.text = "%d名" % all_gens.size()

	if all_gens.is_empty():
		var lbl := Label.new()
		lbl.text = "まだ記録がありません。"
		_grid.add_child(lbl)
		return

	for gen in all_gens:
		_grid.add_child(_make_card(gen))


func _make_card(gen: Generation) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(120, 110)
	card.pressed.connect(_show_detail.bind(gen))

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 3)
	margin.add_child(vbox)

	# Generation badge
	var badge := Label.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.text = "第%d世代" % gen.id
	badge.add_theme_font_size_override("font_size", 10)
	badge.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(badge)

	# Portrait placeholder
	var portrait_row := CenterContainer.new()
	portrait_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(portrait_row)

	var portrait := ColorRect.new()
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.custom_minimum_size = Vector2(48, 48)
	portrait.color = _gen_color(gen)
	portrait_row.add_child(portrait)

	var initial := Label.new()
	initial.mouse_filter = Control.MOUSE_FILTER_IGNORE
	initial.text = gen.name.substr(0, 1) if gen.name.length() > 0 else "?"
	initial.add_theme_font_size_override("font_size", 20)
	initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	initial.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.add_child(initial)

	# Name
	var name_lbl := Label.new()
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.text = gen.name
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if gen.is_alive():
		name_lbl.add_theme_color_override("font_color", Color(0.9, 1.0, 0.9))
	vbox.add_child(name_lbl)

	# Status line
	var status_lbl := Label.new()
	status_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_lbl.add_theme_font_size_override("font_size", 10)
	if gen.is_alive():
		status_lbl.text = "活動中"
		status_lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	else:
		status_lbl.text = "享年%d  %s" % [gen.get_lifespan(), gen.get_cause_of_death_label()]
		status_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(status_lbl)

	return card


func _gen_color(gen: Generation) -> Color:
	if gen.is_alive():
		return Color(0.2, 0.5, 0.3)
	var hue := fmod(float(gen.id) * 0.137, 1.0)
	return Color.from_hsv(hue, 0.35, 0.55)


# ---------------------------------------------------------------------------
# Detail panel
# ---------------------------------------------------------------------------

func _clear_detail() -> void:
	_detail_header.text = "← カードを選ぶと詳細を表示"
	_detail_label.clear()

func _show_detail(gen: Generation) -> void:
	_detail_header.text = "%s　（第%d世代）" % [gen.name, gen.id]
	_detail_label.clear()
	_detail_label.append_text(_build_detail(gen))


func _build_detail(gen: Generation) -> String:
	var b: PackedStringArray = []

	# Dates
	if gen.is_alive():
		var age := GameData.total_years - gen.birth_year
		b.append("[color=%s]%d年生まれ  現在 [b]%d歳[/b]  （寿命目安: %d歳）[/color]" % [
			_COL_MUTED, gen.birth_year, age, gen.max_age
		])
	else:
		var cause_col := _cause_color(gen.cause_of_death)
		b.append("[color=%s]%d年生まれ → %d年没  享年[b]%d[/b][/color]  [color=%s]%s[/color]" % [
			_COL_MUTED, gen.birth_year, gen.death_year,
			gen.get_lifespan(), cause_col, gen.get_cause_of_death_label()
		])
	b.append("")

	# Skills
	b.append("[color=%s][b]スキル[/b][/color]  [color=%s]%d個[/color]" % [
		_COL_HEADER, _COL_MUTED, gen.skills.size()
	])
	if gen.skills.is_empty():
		b.append(_muted("  （なし）"))
	else:
		for skill in gen.skills:
			var col := _category_color(skill.category)
			var line := "  [color=%s]・%s　Lv%d[/color]  [color=%s][%s][/color]" % [
				col, skill.display_name, skill.level,
				_COL_MUTED, skill.get_category_label()
			]
			if skill.inherited_from_generation != -1:
				line += "  [color=%s]← 第%d世代[/color]" % [
					_COL_INHERIT, skill.inherited_from_generation
				]
			b.append(line)
	b.append("")

	# World changes
	b.append("[color=%s][b]世界への貢献[/b][/color]  [color=%s]%d件[/color]" % [
		_COL_HEADER, _COL_MUTED, gen.world_changes.size()
	])
	if gen.world_changes.is_empty():
		b.append(_muted("  （なし）"))
	else:
		for change in gen.world_changes:
			var col := _change_color(change.type)
			b.append("  [color=%s]▶ [%s][/color]  %s  [color=%s]%d年[/color]" % [
				col, change.get_type_label(), change.description,
				_COL_MUTED, change.year
			])
	b.append("")

	# Achievements
	b.append("[color=%s][b]功績[/b][/color]" % _COL_HEADER)
	if gen.achievements.is_empty():
		b.append(_muted("  （なし）"))
	else:
		for ach in gen.achievements:
			b.append("  [color=%s]◆[/color] %s" % [_COL_HEADER, ach])

	return "\n".join(b)


# ---------------------------------------------------------------------------
# Colour helpers
# ---------------------------------------------------------------------------

func _muted(text: String) -> String:
	return "[color=%s]%s[/color]" % [_COL_MUTED, text]

func _cause_color(cause: String) -> String:
	match cause:
		"battle":  return "#ff8888"
		"retired": return "#88bbff"
	return _COL_MUTED

func _category_color(category: String) -> String:
	match category:
		"combat":      return "#ff9988"
		"exploration": return "#88cc88"
		"life":        return "#ffdd88"
	return "#dddddd"

func _change_color(type: String) -> String:
	match type:
		"build":         return "#88cc88"
		"clear_monster": return "#ff8888"
		"open_road":     return "#88bbff"
		"alliance":      return "#cc99ff"
	return "#dddddd"


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

func _on_close_button_pressed() -> void:
	close_requested.emit()

func _on_new_generation_recorded(_gen: Generation) -> void:
	_build_gallery()
