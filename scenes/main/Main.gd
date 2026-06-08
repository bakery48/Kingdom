extends Control

@onready var _clan_name_input: LineEdit  = $Margin/VBox/NewGamePanel/InputRow/ClanNameInput
@onready var _new_game_panel: Control    = $Margin/VBox/NewGamePanel
@onready var _hud_panel: Control         = $Margin/VBox/HudPanel
@onready var _status_label: Label        = $Margin/VBox/HudPanel/InfoBar/StatusLabel
@onready var _year_label: Label          = $Margin/VBox/HudPanel/InfoBar/YearLabel
@onready var _age_label: Label           = $Margin/VBox/HudPanel/ProgressRow/AgeLabel
@onready var _progress_label: Label      = $Margin/VBox/HudPanel/ProgressRow/ProgressLabel
@onready var _action_log: RichTextLabel  = $Margin/VBox/HudPanel/ActionLog

const CHRONICLE_SCENE := preload("res://scenes/chronicle/Chronicle.tscn")
const CHARACTER_SCENE := preload("res://scenes/character/Character.tscn")
const GEN_END_SCENE   := preload("res://scenes/generation_end/GenerationEnd.tscn")
const GALLERY_SCENE   := preload("res://scenes/gallery/Gallery.tscn")

var _overlay: Control = null

const _BUILD_EVENTS := [
	["小さな砦を築いた", "建築術"],
	["木造の倉庫を建てた", "建築術"],
	["石造りの橋を架けた", "建築術"],
	["交易所を開いた", "商才"],
	["見張り塔を建設した", "測量術"],
]
const _ROAD_EVENTS := [
	["東への街道を切り開いた", "開拓術"],
	["山間の険路を整備した", "開拓術"],
	["河沿いの道を開通した", "地図術"],
	["西の集落への道を整えた", "開拓術"],
]
const _BATTLE_EVENTS := [
	["魔物の巣を壊滅させた", "剣術"],
	["盗賊団を撃退した", "剣術"],
	["山の怪獣を討ち取った", "弓術"],
	["暗黒の森を浄化した", "魔法術"],
	["谷底の怪物を倒した", "剣術"],
]
const _ALLIANCE_EVENTS := [
	["北の商人ギルドと同盟を結んだ", "交渉術"],
	["山岳の部族と友好協定を結んだ", "外交術"],
	["海辺の漁村と交易協定を締結した", "交渉術"],
	["隣国の貴族と縁組みを結んだ", "外交術"],
]


func _ready() -> void:
	GameData.game_started.connect(_on_game_started)
	GameData.new_generation_started.connect(_on_new_generation_started)
	GameData.world_changed.connect(_on_world_changed)
	GameData.generation_ended.connect(_on_generation_ended)

	if SaveManager.load_game():
		_show_hud()
		_refresh_hud()
		_log_system("セーブデータを読み込みました。")
	else:
		_show_new_game_panel()


# ---------------------------------------------------------------------------
# UI state
# ---------------------------------------------------------------------------

func _show_new_game_panel() -> void:
	_new_game_panel.visible = true
	_hud_panel.visible = false


func _show_hud() -> void:
	_new_game_panel.visible = false
	_hud_panel.visible = true


func _refresh_hud() -> void:
	var gen := GameData.get_current_generation()
	if gen == null:
		return
	_status_label.text = "%s（第%d世代）" % [gen.name, gen.id]
	var age := GameData.total_years - gen.birth_year
	_year_label.text = "%d年" % GameData.total_years
	_age_label.text = "年齢 %d歳" % age
	_progress_label.text = GameData.world_state.get_progress_label()


# ---------------------------------------------------------------------------
# Log helpers
# ---------------------------------------------------------------------------

func _log_system(text: String) -> void:
	_action_log.append_text("\n[color=#888888]" + text + "[/color]")

func _log_event(text: String) -> void:
	_action_log.append_text("\n[color=#ffdd88]" + text + "[/color]")

func _log_build(text: String) -> void:
	_action_log.append_text("\n[color=#88cc88]" + text + "[/color]")

func _log_battle(text: String) -> void:
	_action_log.append_text("\n[color=#ff8888]" + text + "[/color]")

func _log_road(text: String) -> void:
	_action_log.append_text("\n[color=#aaddff]" + text + "[/color]")

func _log_alliance(text: String) -> void:
	_action_log.append_text("\n[color=#ddaaff]" + text + "[/color]")


# ---------------------------------------------------------------------------
# New-game
# ---------------------------------------------------------------------------

func _on_start_button_pressed() -> void:
	var clan := _clan_name_input.text.strip_edges()
	if clan.is_empty():
		clan = "アルデン"
	GameData.start_new_game(clan)
	SaveManager.save_game()


# ---------------------------------------------------------------------------
# Action buttons
# ---------------------------------------------------------------------------

func _on_build_pressed() -> void:
	var gen := GameData.get_current_generation()
	if gen == null or _overlay != null:
		return
	GameData.total_years += randi_range(1, 3)
	var ev: Array = _BUILD_EVENTS[randi() % _BUILD_EVENTS.size()]
	var change := WorldChange.new(
		"build", ev[0], randi_range(0, 9), randi_range(0, 9), gen.id, GameData.total_years
	)
	GameData.add_world_change(change)
	_try_gain_skill(gen, ev[1], "exploration")
	_log_build("[%d年] %s が「%s」を成し遂げた。" % [GameData.total_years, gen.name, ev[0]])
	_refresh_hud()
	SaveManager.save_game()
	_check_old_age()


func _on_road_pressed() -> void:
	var gen := GameData.get_current_generation()
	if gen == null or _overlay != null:
		return
	GameData.total_years += randi_range(2, 4)
	var ev: Array = _ROAD_EVENTS[randi() % _ROAD_EVENTS.size()]
	var change := WorldChange.new(
		"open_road", ev[0], randi_range(0, 9), randi_range(0, 9), gen.id, GameData.total_years
	)
	GameData.add_world_change(change)
	_try_gain_skill(gen, ev[1], "exploration")
	_log_road("[%d年] %s が「%s」を成し遂げた。" % [GameData.total_years, gen.name, ev[0]])
	_refresh_hud()
	SaveManager.save_game()
	_check_old_age()


func _on_battle_pressed() -> void:
	var gen := GameData.get_current_generation()
	if gen == null or _overlay != null:
		return
	GameData.total_years += 1
	var ev: Array = _BATTLE_EVENTS[randi() % _BATTLE_EVENTS.size()]

	if randf() < 0.15:
		_log_battle("[%d年] %s は戦いに敗れ、命を散らした…" % [GameData.total_years, gen.name])
		GameData.end_generation("battle")
		_open_overlay(GEN_END_SCENE)
		SaveManager.save_game()
		return

	var change := WorldChange.new(
		"clear_monster", ev[0], randi_range(0, 9), randi_range(0, 9), gen.id, GameData.total_years
	)
	GameData.add_world_change(change)
	_try_gain_skill(gen, ev[1], "combat")
	_log_battle("[%d年] %s が「%s」を達成した。" % [GameData.total_years, gen.name, ev[0]])
	_refresh_hud()
	SaveManager.save_game()
	_check_old_age()


func _on_alliance_pressed() -> void:
	var gen := GameData.get_current_generation()
	if gen == null or _overlay != null:
		return
	GameData.total_years += randi_range(1, 2)
	var ev: Array = _ALLIANCE_EVENTS[randi() % _ALLIANCE_EVENTS.size()]
	var change := WorldChange.new(
		"alliance", ev[0], 0, 0, gen.id, GameData.total_years
	)
	GameData.add_world_change(change)
	_try_gain_skill(gen, ev[1], "life")
	_log_alliance("[%d年] %s が「%s」を成し遂げた。" % [GameData.total_years, gen.name, ev[0]])
	_refresh_hud()
	SaveManager.save_game()
	_check_old_age()


func _on_retire_pressed() -> void:
	var gen := GameData.get_current_generation()
	if gen == null or _overlay != null:
		return
	_log_event("─── %s が引退を決意した。 ───" % gen.name)
	GameData.end_generation("retired")
	_open_overlay(GEN_END_SCENE)
	SaveManager.save_game()


# ---------------------------------------------------------------------------
# Navigation
# ---------------------------------------------------------------------------

func _on_open_chronicle_pressed() -> void:
	_open_overlay(CHRONICLE_SCENE)

func _on_open_character_pressed() -> void:
	_open_overlay(CHARACTER_SCENE)

func _on_open_gallery_pressed() -> void:
	_open_overlay(GALLERY_SCENE)


# ---------------------------------------------------------------------------
# Overlay management
# ---------------------------------------------------------------------------

func _open_overlay(scene_resource) -> void:
	if _overlay != null:
		_overlay.queue_free()
	_overlay = scene_resource.instantiate()
	add_child(_overlay)
	if _overlay.has_signal("close_requested"):
		_overlay.close_requested.connect(_close_overlay)


func _close_overlay() -> void:
	if _overlay != null:
		_overlay.queue_free()
		_overlay = null
	_refresh_hud()


# ---------------------------------------------------------------------------
# Skill gain helper
# ---------------------------------------------------------------------------

func _try_gain_skill(gen: Generation, skill_name: String, category: String) -> void:
	for existing in gen.skills:
		if existing.display_name == skill_name:
			existing.level = min(existing.level + 1, 10)
			_log_system("  %s の「%s」が Lv%d に成長した！" % [gen.name, skill_name, existing.level])
			return
	if gen.skills.size() < 8:
		var new_skill := Skill.new(
			skill_name + "_" + str(gen.id),
			skill_name,
			1,
			category,
			-1
		)
		gen.skills.append(new_skill)
		_log_system("  %s が「%s」を習得した！" % [gen.name, skill_name])


# ---------------------------------------------------------------------------
# Old age check
# ---------------------------------------------------------------------------

func _check_old_age() -> void:
	if _overlay != null:
		return
	var gen := GameData.get_current_generation()
	if gen == null:
		return
	var age := GameData.total_years - gen.birth_year
	if age >= gen.max_age:
		_log_event(
			"─── %s は %d歳となり、老いには勝てず引退の時を迎えた… ───" % [gen.name, age]
		)
		GameData.end_generation("old_age")
		_open_overlay(GEN_END_SCENE)
		SaveManager.save_game()


# ---------------------------------------------------------------------------
# GameData signal handlers
# ---------------------------------------------------------------------------

func _on_game_started(clan_name: String) -> void:
	_show_hud()
	_refresh_hud()
	_log_event("═══ 【%s】の年代記が始まった。═══" % clan_name)


func _on_new_generation_started(gen: Generation) -> void:
	_refresh_hud()
	_log_event(
		"═══ 第%d世代「%s」が当主となった。（寿命目安: %d歳）═══" % [gen.id, gen.name, gen.max_age]
	)


func _on_world_changed(_change: WorldChange) -> void:
	_progress_label.text = GameData.world_state.get_progress_label()


func _on_generation_ended(gen: Generation) -> void:
	_log_event("─── 第%d世代「%s」の物語が幕を閉じた。 ───" % [gen.id, gen.name])
