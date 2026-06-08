extends Control

# ---------------------------------------------------------------------------
# Character panel — displays the active generation's stats, skills, and items
# ---------------------------------------------------------------------------

signal close_requested

@onready var _name_label: Label         = $Panel/VBox/NameLabel
@onready var _gen_label: Label          = $Panel/VBox/GenLabel
@onready var _year_label: Label         = $Panel/VBox/YearLabel
@onready var _skills_list: VBoxContainer = $Panel/VBox/SkillsSection/SkillsList
@onready var _items_list: VBoxContainer  = $Panel/VBox/ItemsSection/ItemsList
@onready var _achievements_list: VBoxContainer = $Panel/VBox/AchievementsSection/AchievementsList
@onready var _close_button: Button      = $Panel/VBox/CloseButton

# Skill add form
@onready var _skill_name_input: LineEdit  = $Panel/VBox/AddSkillSection/SkillNameInput
@onready var _skill_cat_option: OptionButton = $Panel/VBox/AddSkillSection/CategoryOption
@onready var _add_skill_button: Button   = $Panel/VBox/AddSkillSection/AddSkillButton

# Item add form
@onready var _item_name_input: LineEdit  = $Panel/VBox/AddItemSection/ItemNameInput
@onready var _heirloom_check: CheckBox   = $Panel/VBox/AddItemSection/HeirloomCheck
@onready var _add_item_button: Button    = $Panel/VBox/AddItemSection/AddItemButton


func _ready() -> void:
	# Populate skill category dropdown
	_skill_cat_option.add_item("戦闘", 0)
	_skill_cat_option.add_item("探索", 1)
	_skill_cat_option.add_item("生活", 2)
	_refresh()
	GameData.new_generation_started.connect(_on_new_generation_started)


func _refresh() -> void:
	var gen := GameData.get_current_generation()
	if gen == null:
		_name_label.text = "当主なし"
		return

	_name_label.text = gen.name
	_gen_label.text = "第%d世代" % gen.id
	_year_label.text = "活動開始: %d年" % gen.birth_year

	# Skills
	for child in _skills_list.get_children():
		child.queue_free()
	for skill in gen.skills:
		var lbl := Label.new()
		lbl.text = "・%s Lv%d [%s] %s" % [
			skill.display_name,
			skill.level,
			skill.get_category_label(),
			skill.get_inheritance_label()
		]
		_skills_list.add_child(lbl)
	if gen.skills.is_empty():
		var lbl := Label.new()
		lbl.text = "（スキルなし）"
		_skills_list.add_child(lbl)

	# Items
	for child in _items_list.get_children():
		child.queue_free()
	for item in gen.equipped_items:
		var lbl := Label.new()
		lbl.text = "・%s %s — %s" % [
			item.display_name,
			item.get_heirloom_label(),
			item.description
		]
		_items_list.add_child(lbl)
	if gen.equipped_items.is_empty():
		var lbl := Label.new()
		lbl.text = "（所持品なし）"
		_items_list.add_child(lbl)

	# Achievements
	for child in _achievements_list.get_children():
		child.queue_free()
	for ach in gen.achievements:
		var lbl := Label.new()
		lbl.text = "◆ " + ach
		_achievements_list.add_child(lbl)
	if gen.achievements.is_empty():
		var lbl := Label.new()
		lbl.text = "（功績なし）"
		_achievements_list.add_child(lbl)


# ---------------------------------------------------------------------------
# Skill addition
# ---------------------------------------------------------------------------

func _on_add_skill_button_pressed() -> void:
	var gen := GameData.get_current_generation()
	if gen == null:
		return
	if gen.skills.size() >= 3:
		return

	var skill_name := _skill_name_input.text.strip_edges()
	if skill_name.is_empty():
		return

	var categories := ["combat", "exploration", "life"]
	var sel_id := _skill_cat_option.get_item_id(_skill_cat_option.selected)
	var cat := categories[sel_id] if sel_id < categories.size() else "combat"

	var skill := Skill.new(
		skill_name.to_lower().replace(" ", "_"),
		skill_name,
		1,
		cat,
		-1
	)
	gen.add_skill(skill)
	_skill_name_input.text = ""
	_refresh()


# ---------------------------------------------------------------------------
# Item addition
# ---------------------------------------------------------------------------

func _on_add_item_button_pressed() -> void:
	var gen := GameData.get_current_generation()
	if gen == null:
		return
	if gen.equipped_items.size() >= 2:
		return

	var item_name := _item_name_input.text.strip_edges()
	if item_name.is_empty():
		return

	var item := Item.new(
		item_name.to_lower().replace(" ", "_"),
		item_name,
		"手動追加アイテム",
		_heirloom_check.button_pressed,
		1.0,
		1.0
	)
	gen.add_item(item)
	_item_name_input.text = ""
	_heirloom_check.button_pressed = false
	_refresh()
	SaveManager.save_game()


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

func _on_close_button_pressed() -> void:
	close_requested.emit()


func _on_new_generation_started(_gen: Generation) -> void:
	_refresh()
