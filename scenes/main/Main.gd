extends Control

# ---------------------------------------------------------------------------
# Main scene — world map hub and game entry point
# ---------------------------------------------------------------------------

@onready var _clan_name_input: LineEdit = $VBox/NewGamePanel/ClanNameInput
@onready var _new_game_panel: Control   = $VBox/NewGamePanel
@onready var _hud_panel: Control        = $VBox/HudPanel
@onready var _status_label: Label       = $VBox/HudPanel/StatusLabel
@onready var _year_label: Label         = $VBox/HudPanel/YearLabel
@onready var _progress_label: Label     = $VBox/HudPanel/ProgressLabel
@onready var _action_log: RichTextLabel = $VBox/HudPanel/ActionLog

# Preloaded sub-scenes
const CHRONICLE_SCENE    := preload("res://scenes/chronicle/Chronicle.tscn")
const CHARACTER_SCENE    := preload("res://scenes/character/Character.tscn")
const GEN_END_SCENE      := preload("res://scenes/generation_end/GenerationEnd.tscn")
const GALLERY_SCENE      := preload("res://scenes/gallery/Gallery.tscn")

var _overlay: Control = null


func _ready() -> void:
	GameData.game_started.connect(_on_game_started)
	GameData.new_generation_started.connect(_on_new_generation_started)
	GameData.world_changed.connect(_on_world_changed)
	GameData.generation_ended.connect(_on_generation_ended)

	# Try loading existing save
	if SaveManager.load_game():
		_show_hud()
		_refresh_hud()
		_log("セーブデータを読み込みました。")
	else:
		_show_new_game_panel()


# ---------------------------------------------------------------------------
# UI state helpers
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
	_status_label.text = "当主: %s（第%d世代）" % [gen.name, gen.id]
	_year_label.text = "現在: %d年" % GameData.total_years
	_progress_label.text = GameData.world_state.get_progress_label()


func _log(text: String) -> void:
	_action_log.append_text("\n" + text)


# ---------------------------------------------------------------------------
# New-game button
# ---------------------------------------------------------------------------

func _on_start_button_pressed() -> void:
	var clan := _clan_name_input.text.strip_edges()
	if clan.is_empty():
		clan = "アルデン"
	GameData.start_new_game(clan)
	SaveManager.save_game()


# ---------------------------------------------------------------------------
# HUD action buttons
# ---------------------------------------------------------------------------

func _on_adventure_button_pressed() -> void:
	# Demo: perform a quick adventure that builds something
	var gen := GameData.get_current_generation()
	if gen == null:
		return
	GameData.total_years += randi_range(1, 3)

	var change := WorldChange.new(
		"build",
		"小さな砦を築いた",
		randi_range(0, 9),
		randi_range(0, 9),
		gen.id,
		GameData.total_years
	)
	GameData.add_world_change(change)
	_log("[%d年] %s が「%s」を成し遂げた。" % [GameData.total_years, gen.name, change.description])
	_refresh_hud()
	SaveManager.save_game()


func _on_clear_monster_button_pressed() -> void:
	var gen := GameData.get_current_generation()
	if gen == null:
		return
	GameData.total_years += 1

	var change := WorldChange.new(
		"clear_monster",
		"魔物の巣を討伐した",
		randi_range(0, 9),
		randi_range(0, 9),
		gen.id,
		GameData.total_years
	)
	GameData.add_world_change(change)

	# Also teach a new skill if under cap
	if gen.skills.size() < 3:
		var new_skill := Skill.new(
			"sword_lv" + str(gen.id),
			"剣術・第%d世代流" % gen.id,
			randi_range(1, 3),
			"combat",
			-1
		)
		gen.add_skill(new_skill)
		_log("[%d年] %s が「%s」を習得した！" % [GameData.total_years, gen.name, new_skill.display_name])

	_log("[%d年] %s が「%s」を達成した。" % [GameData.total_years, gen.name, change.description])
	_refresh_hud()
	SaveManager.save_game()


func _on_open_chronicle_pressed() -> void:
	_open_overlay(CHRONICLE_SCENE)


func _on_open_character_pressed() -> void:
	_open_overlay(CHARACTER_SCENE)


func _on_open_gallery_pressed() -> void:
	_open_overlay(GALLERY_SCENE)


func _on_end_generation_pressed() -> void:
	var causes := ["old_age", "battle", "retired"]
	var cause := causes[randi() % causes.size()]
	GameData.end_generation(cause)
	_open_overlay(GEN_END_SCENE)
	SaveManager.save_game()


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
# GameData signal handlers
# ---------------------------------------------------------------------------

func _on_game_started(clan_name: String) -> void:
	_show_hud()
	_refresh_hud()
	_log("【%s】の年代記が始まった。" % clan_name)


func _on_new_generation_started(gen: Generation) -> void:
	_refresh_hud()
	_log("═══ 第%d世代「%s」が当主となった。═══" % [gen.id, gen.name])


func _on_world_changed(change: WorldChange) -> void:
	_progress_label.text = GameData.world_state.get_progress_label()


func _on_generation_ended(gen: Generation) -> void:
	_log("─── 第%d世代「%s」の物語が幕を閉じた。───" % [gen.id, gen.name])
