extends Control

# ---------------------------------------------------------------------------
# Portrait Gallery — shows all ancestors in a card grid
# ---------------------------------------------------------------------------

signal close_requested

@onready var _grid: GridContainer         = $Panel/VBox/ScrollContainer/Grid
@onready var _close_button: Button        = $Panel/VBox/CloseButton
@onready var _detail_panel: VBoxContainer = $Panel/VBox/DetailPanel
@onready var _detail_label: RichTextLabel = $Panel/VBox/DetailPanel/DetailLabel
@onready var _gen_count_label: Label      = $Panel/VBox/HeaderRow/GenCountLabel


func _ready() -> void:
	_build_gallery()
	GameData.generation_ended.connect(_on_new_generation_recorded)
	_detail_panel.visible = false


# ---------------------------------------------------------------------------
# Gallery population
# ---------------------------------------------------------------------------

func _build_gallery() -> void:
	for child in _grid.get_children():
		child.queue_free()

	var all_gens := GameData.get_all_generations()
	_gen_count_label.text = "先祖一覧（%d名）" % all_gens.size()

	if all_gens.is_empty():
		var lbl := Label.new()
		lbl.text = "まだ記録がありません。"
		_grid.add_child(lbl)
		return

	for gen in all_gens:
		var card := _make_card(gen)
		_grid.add_child(card)


func _make_card(gen: Generation) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(180, 140)

	var vbox := VBoxContainer.new()
	card.add_child(vbox)

	# Generation badge
	var badge := Label.new()
	badge.text = "第%d世代" % gen.id
	badge.add_theme_font_size_override("font_size", 11)
	vbox.add_child(badge)

	# Portrait placeholder (colored rectangle)
	var portrait := ColorRect.new()
	portrait.custom_minimum_size = Vector2(60, 60)
	portrait.color = _generation_color(gen.id)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(portrait)

	# Initials in portrait
	var initials := Label.new()
	initials.text = gen.name.substr(0, 1) if gen.name.length() > 0 else "?"
	initials.add_theme_font_size_override("font_size", 22)
	initials.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait.add_child(initials)
	initials.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = gen.name
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_lbl)

	# Status
	var status_lbl := Label.new()
	if gen.is_alive():
		status_lbl.text = "活動中"
		status_lbl.add_theme_color_override("font_color", Color.GREEN)
	else:
		status_lbl.text = "%d〜%d年" % [gen.birth_year, gen.death_year]
	status_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(status_lbl)

	# Skill count / achievements
	var summary_lbl := Label.new()
	summary_lbl.text = "スキル:%d　功績:%d" % [gen.skills.size(), gen.achievements.size()]
	summary_lbl.add_theme_font_size_override("font_size", 10)
	vbox.add_child(summary_lbl)

	# Click to show detail
	var btn := Button.new()
	btn.text = "詳細"
	btn.pressed.connect(_show_detail.bind(gen))
	vbox.add_child(btn)

	return card


func _generation_color(gen_id: int) -> Color:
	# Cycle through hues based on generation id
	var hue := fmod(float(gen_id) * 0.137, 1.0)
	return Color.from_hsv(hue, 0.4, 0.7)


# ---------------------------------------------------------------------------
# Detail panel
# ---------------------------------------------------------------------------

func _show_detail(gen: Generation) -> void:
	_detail_panel.visible = true

	var lines: Array[String] = []
	lines.append("[b]%s[/b]" % gen.get_title())
	lines.append("")

	if gen.is_alive():
		lines.append("生年: %d年　（活動中）" % gen.birth_year)
	else:
		lines.append("生年: %d年　没年: %d年（享年%d）　%s" % [
			gen.birth_year,
			gen.death_year,
			gen.get_lifespan(),
			gen.get_cause_of_death_label()
		])
	lines.append("")

	# Skills
	lines.append("[b]スキル[/b]")
	for skill in gen.skills:
		lines.append("  ・%s Lv%d — %s" % [skill.display_name, skill.level, skill.get_inheritance_label()])
	if gen.skills.is_empty():
		lines.append("  （なし）")
	lines.append("")

	# Items
	lines.append("[b]所持品[/b]")
	for item in gen.equipped_items:
		lines.append("  ・%s %s" % [item.display_name, item.get_heirloom_label()])
	if gen.equipped_items.is_empty():
		lines.append("  （なし）")
	lines.append("")

	# World changes
	lines.append("[b]世界への貢献 (%d件)[/b]" % gen.world_changes.size())
	for change in gen.world_changes:
		lines.append("  ▶ %s — %s" % [change.get_type_label(), change.description])
	lines.append("")

	# Achievements
	lines.append("[b]功績[/b]")
	for ach in gen.achievements:
		lines.append("  ◆ " + ach)
	if gen.achievements.is_empty():
		lines.append("  （なし）")

	_detail_label.bbcode_enabled = true
	_detail_label.text = "\n".join(lines)


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

func _on_close_button_pressed() -> void:
	close_requested.emit()


func _on_close_detail_button_pressed() -> void:
	_detail_panel.visible = false


func _on_new_generation_recorded(_gen: Generation) -> void:
	_build_gallery()
