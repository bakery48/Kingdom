extends Control

signal close_requested

@onready var _stats_display: RichTextLabel  = $Panel/Margin/VBox/Scroll/Content/StatsDisplay
@onready var _skill_name_input: LineEdit    = $Panel/Margin/VBox/Scroll/Content/AddSkillRow/SkillNameInput
@onready var _skill_cat_option: OptionButton = $Panel/Margin/VBox/Scroll/Content/AddSkillRow/CategoryOption
@onready var _item_name_input: LineEdit     = $Panel/Margin/VBox/Scroll/Content/AddItemRow/ItemNameInput
@onready var _heirloom_check: CheckBox      = $Panel/Margin/VBox/Scroll/Content/AddItemRow/HeirloomCheck

const _COL_NAME    := "#ffdd88"
const _COL_MUTED   := "#888888"
const _COL_HEADER  := "#aaddff"
const _COL_INHERIT := "#ffcc66"
const _COL_ACHIEVE := "#ffdd88"


func _ready() -> void:
	_skill_cat_option.add_item("戦闘", 0)
	_skill_cat_option.add_item("探索", 1)
	_skill_cat_option.add_item("生活", 2)
	GameData.new_generation_started.connect(_on_data_changed)
	GameData.world_changed.connect(_on_data_changed)
	_refresh()


func _refresh() -> void:
	_stats_display.clear()
	var gen := GameData.get_current_generation()
	if gen == null:
		_stats_display.append_text(_muted("当主なし"))
		return
	_stats_display.append_text(_build_stats(gen))


# ---------------------------------------------------------------------------
# Stats builder
# ---------------------------------------------------------------------------

func _build_stats(gen: Generation) -> String:
	var b: PackedStringArray = []
	var age := GameData.total_years - gen.birth_year

	# Name + generation
	b.append("[color=%s][b]%s[/b][/color]" % [_COL_NAME, gen.name])
	b.append(
		"[color=%s]第%d世代  |  [/color]%d歳[color=%s]（寿命目安: %d歳）[/color]" % [
			_COL_MUTED, gen.id, age, _COL_MUTED, gen.max_age
		]
	)
	b.append(
		_muted("活動開始: %d年  |  現在: %d年  |  功績: %d件  |  世界貢献: %d件" % [
			gen.birth_year, GameData.total_years,
			gen.achievements.size(), gen.world_changes.size()
		])
	)
	b.append("")

	# Skills
	b.append("[b][color=%s]スキル[/color][/b]  %s" % [
		_COL_HEADER,
		_muted("%d / 8" % gen.skills.size())
	])
	if gen.skills.is_empty():
		b.append(_muted("　（なし）"))
	else:
		for skill in gen.skills:
			var col := _category_color(skill.category)
			var line := "  [color=%s]・%s　Lv%d[/color]  [color=%s][%s][/color]" % [
				col, skill.display_name, skill.level,
				_COL_MUTED, skill.get_category_label()
			]
			if skill.inherited_from_generation != -1:
				line += "  [color=%s]← 第%d世代より継承[/color]" % [
					_COL_INHERIT, skill.inherited_from_generation
				]
			b.append(line)
	b.append("")

	# Items
	b.append("[b][color=%s]所持品[/color][/b]  %s" % [
		_COL_HEADER,
		_muted("%d / 2（継承枠）" % gen.equipped_items.size())
	])
	if gen.equipped_items.is_empty():
		b.append(_muted("　（なし）"))
	else:
		for item in gen.equipped_items:
			var line := "  ・[b]%s[/b]  %s" % [item.display_name, item.get_heirloom_label()]
			if item.description != "":
				line += "  " + _muted(item.description)
			b.append(line)
	b.append("")

	# Achievements
	b.append("[b][color=%s]功績[/color][/b]  %s" % [
		_COL_HEADER,
		_muted("%d件" % gen.achievements.size())
	])
	if gen.achievements.is_empty():
		b.append(_muted("　（なし）"))
	else:
		for ach in gen.achievements:
			b.append("  [color=%s]◆[/color] %s" % [_COL_ACHIEVE, ach])
	b.append("")

	# World changes summary
	if not gen.world_changes.is_empty():
		b.append("[b][color=%s]世界への貢献[/color][/b]" % _COL_HEADER)
		for change in gen.world_changes:
			var col := _change_color(change.type)
			b.append("  [color=%s]▶ [%s][/color]  %s" % [
				col, change.get_type_label(), change.description
			])

	return "\n".join(b)


# ---------------------------------------------------------------------------
# Skill addition
# ---------------------------------------------------------------------------

func _on_add_skill_button_pressed() -> void:
	var gen := GameData.get_current_generation()
	if gen == null:
		return
	var skill_name := _skill_name_input.text.strip_edges()
	if skill_name.is_empty():
		return
	var categories: Array[String] = ["combat", "exploration", "life"]
	var sel_id := _skill_cat_option.get_item_id(_skill_cat_option.selected)
	var cat: String = categories[clamp(sel_id, 0, 2)]
	var skill := Skill.new(
		skill_name.to_lower().replace(" ", "_") + "_" + str(gen.id),
		skill_name, 1, cat, -1
	)
	gen.add_skill(skill)
	_skill_name_input.text = ""
	_refresh()
	SaveManager.save_game()


# ---------------------------------------------------------------------------
# Item addition
# ---------------------------------------------------------------------------

func _on_add_item_button_pressed() -> void:
	var gen := GameData.get_current_generation()
	if gen == null:
		return
	var item_name := _item_name_input.text.strip_edges()
	if item_name.is_empty():
		return
	var item := Item.new(
		item_name.to_lower().replace(" ", "_"),
		item_name,
		"手動追加",
		_heirloom_check.button_pressed,
		1.0, 1.0
	)
	gen.add_item(item)
	_item_name_input.text = ""
	_heirloom_check.button_pressed = false
	_refresh()
	SaveManager.save_game()


# ---------------------------------------------------------------------------
# Colour helpers
# ---------------------------------------------------------------------------

func _muted(text: String) -> String:
	return "[color=%s]%s[/color]" % [_COL_MUTED, text]

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

func _on_data_changed(_arg = null) -> void:
	_refresh()
