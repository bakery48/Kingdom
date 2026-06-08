extends Control

signal close_requested

const MAX_SKILLS := 3
const MAX_ITEMS  := 2

var _selected_skills: Array[Skill] = []
var _selected_items: Array[Item]   = []

@onready var _title_label: Label          = $Panel/Margin/VBox/TitleLabel
@onready var _deceased_label: Label       = $Panel/Margin/VBox/DeceasedLabel
@onready var _skills_container: VBoxContainer = $Panel/Margin/VBox/Scroll/ScrollContent/SkillsSection/SkillsContainer
@onready var _skill_limit_label: Label    = $Panel/Margin/VBox/Scroll/ScrollContent/SkillsSection/SkillLimitLabel
@onready var _items_container: VBoxContainer  = $Panel/Margin/VBox/Scroll/ScrollContent/ItemsSection/ItemsContainer
@onready var _item_limit_label: Label     = $Panel/Margin/VBox/Scroll/ScrollContent/ItemsSection/ItemLimitLabel
@onready var _selected_skills_label: Label = $Panel/Margin/VBox/SelectionInfo/SelectedSkillsLabel
@onready var _selected_items_label: Label  = $Panel/Margin/VBox/SelectionInfo/SelectedItemsLabel
@onready var _heir_name_input: LineEdit   = $Panel/Margin/VBox/HeirSection/HeirNameInput
@onready var _confirm_button: Button      = $Panel/Margin/VBox/Buttons/ConfirmButton
@onready var _skip_button: Button         = $Panel/Margin/VBox/Buttons/SkipButton


func _ready() -> void:
	var last_gen: Generation = null
	if not GameData.generations.is_empty():
		last_gen = GameData.generations[-1]

	if last_gen != null:
		_title_label.text = "── 第%d世代の終焉 ──" % last_gen.id
		_deceased_label.text = "「%s」　%d年〜%d年（享年%d）　%s" % [
			last_gen.name,
			last_gen.birth_year,
			last_gen.death_year,
			last_gen.get_lifespan(),
			last_gen.get_cause_of_death_label()
		]
		_populate_skill_list(last_gen)
		_populate_item_list(last_gen)
	else:
		_title_label.text = "── 継承の選択 ──"
		_deceased_label.text = "（世代記録なし）"

	_update_selection_labels()


# ---------------------------------------------------------------------------
# Build skill checkbox list
# ---------------------------------------------------------------------------

func _populate_skill_list(gen: Generation) -> void:
	for child in _skills_container.get_children():
		child.queue_free()

	if gen.skills.is_empty():
		var lbl := Label.new()
		lbl.text = "継承できるスキルがありません。"
		_skills_container.add_child(lbl)
		return

	for skill in gen.skills:
		var check := CheckBox.new()
		check.text = "%s　Lv%d　[%s]　%s" % [
			skill.display_name,
			skill.level,
			skill.get_category_label(),
			skill.get_inheritance_label()
		]
		check.set_meta("skill_ref", skill)
		check.toggled.connect(_on_skill_toggled.bind(check))
		_skills_container.add_child(check)


# ---------------------------------------------------------------------------
# Build item checkbox list
# ---------------------------------------------------------------------------

func _populate_item_list(gen: Generation) -> void:
	for child in _items_container.get_children():
		child.queue_free()

	if gen.equipped_items.is_empty():
		var lbl := Label.new()
		lbl.text = "継承できるアイテムがありません。"
		_items_container.add_child(lbl)
		return

	for item in gen.equipped_items:
		var check := CheckBox.new()
		var label := "%s%s" % [item.display_name, item.get_heirloom_label()]
		if item.description != "":
			label += " — " + item.description
		check.text = label
		check.set_meta("item_ref", item)
		check.toggled.connect(_on_item_toggled.bind(check))
		_items_container.add_child(check)


# ---------------------------------------------------------------------------
# Toggle handlers
# ---------------------------------------------------------------------------

func _on_skill_toggled(toggled_on: bool, check: CheckBox) -> void:
	var skill: Skill = check.get_meta("skill_ref")
	if toggled_on:
		if _selected_skills.size() >= MAX_SKILLS:
			check.set_pressed_no_signal(false)
			_skill_limit_label.text = "※ スキルは最大%d つまでです。" % MAX_SKILLS
			_skill_limit_label.visible = true
			return
		_selected_skills.append(skill)
	else:
		_selected_skills.erase(skill)

	_skill_limit_label.visible = false
	_update_selection_labels()


func _on_item_toggled(toggled_on: bool, check: CheckBox) -> void:
	var item: Item = check.get_meta("item_ref")
	if toggled_on:
		if _selected_items.size() >= MAX_ITEMS:
			check.set_pressed_no_signal(false)
			_item_limit_label.text = "※ アイテムは最大%d つまでです。" % MAX_ITEMS
			_item_limit_label.visible = true
			return
		_selected_items.append(item)
	else:
		_selected_items.erase(item)

	_item_limit_label.visible = false
	_update_selection_labels()


func _update_selection_labels() -> void:
	_selected_skills_label.text = "継承スキル: %d / %d 選択中" % [
		_selected_skills.size(), MAX_SKILLS
	]
	_selected_items_label.text = "継承アイテム: %d / %d 選択中" % [
		_selected_items.size(), MAX_ITEMS
	]


# ---------------------------------------------------------------------------
# Confirm / Skip
# ---------------------------------------------------------------------------

func _on_confirm_button_pressed() -> void:
	var heir_name := _heir_name_input.text.strip_edges()
	GameData.start_next_generation(_selected_skills, _selected_items, heir_name)
	SaveManager.save_game()
	close_requested.emit()


func _on_skip_button_pressed() -> void:
	var heir_name := _heir_name_input.text.strip_edges()
	GameData.start_next_generation([], [], heir_name)
	SaveManager.save_game()
	close_requested.emit()
