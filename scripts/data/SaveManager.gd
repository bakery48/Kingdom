extends Node

# ---------------------------------------------------------------------------
# Save / Load — registered as Autoload "SaveManager"
# Persists to user://savegame.json
# ---------------------------------------------------------------------------

const SAVE_PATH := "user://savegame.json"

signal game_saved
signal game_loaded
signal save_failed(reason: String)
signal load_failed(reason: String)


func save_game() -> void:
	var data := serialize_game()
	var json_string := JSON.stringify(data, "\t")

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		var err_msg := "ファイルを開けませんでした: " + str(FileAccess.get_open_error())
		push_error("SaveManager.save_game: " + err_msg)
		save_failed.emit(err_msg)
		return

	file.store_string(json_string)
	file.close()
	print("SaveManager: ゲームを保存しました → ", SAVE_PATH)
	game_saved.emit()


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		var err_msg := "セーブファイルを読み込めませんでした: " + str(FileAccess.get_open_error())
		push_error("SaveManager.load_game: " + err_msg)
		load_failed.emit(err_msg)
		return false

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		var err_msg := "JSONパースエラー: line %d — %s" % [json.get_error_line(), json.get_error_message()]
		push_error("SaveManager.load_game: " + err_msg)
		load_failed.emit(err_msg)
		return false

	var data: Dictionary = json.get_data()
	deserialize_game(data)
	print("SaveManager: ゲームを読み込みました ← ", SAVE_PATH)
	game_loaded.emit()
	return true


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		print("SaveManager: セーブデータを削除しました")


# ---------------------------------------------------------------------------
# Serialization
# ---------------------------------------------------------------------------

func serialize_game() -> Dictionary:
	var gd: Node = get_node("/root/GameData")

	var generations_data: Array = []
	for gen in gd.generations:
		generations_data.append(gen.to_dict())

	var current_char_data: Dictionary = {}
	if gd.current_character != null:
		current_char_data = gd.current_character.to_dict()

	return {
		"version": 1,
		"clan_name": gd.clan_name,
		"current_generation": gd.current_generation,
		"total_years": gd.total_years,
		"generations": generations_data,
		"current_character": current_char_data,
		"world_state": gd.world_state.to_dict(),
	}


func deserialize_game(data: Dictionary) -> void:
	var gd: Node = get_node("/root/GameData")

	gd.clan_name = data.get("clan_name", "")
	gd.current_generation = data.get("current_generation", 0)
	gd.total_years = data.get("total_years", 0)

	gd.generations = []
	for gen_data in data.get("generations", []):
		gd.generations.append(Generation.from_dict(gen_data))

	var cur_data: Dictionary = data.get("current_character", {})
	if not cur_data.is_empty():
		gd.current_character = Generation.from_dict(cur_data)
	else:
		gd.current_character = null

	var ws_data: Dictionary = data.get("world_state", {})
	if not ws_data.is_empty():
		gd.world_state = WorldState.from_dict(ws_data)
	else:
		gd.world_state = WorldState.new()
