extends Node

# ---------------------------------------------------------------------------
# Central game state — registered as Autoload "GameData"
# ---------------------------------------------------------------------------

signal generation_ended(generation: Generation)
signal new_generation_started(generation: Generation)
signal world_changed(change: WorldChange)
signal game_started(clan_name: String)

# Core state
var clan_name: String = ""
var current_generation: int = 0
var total_years: int = 0

# All completed generations; never deleted — the permanent chronicle
var generations: Array = []  # Array[Generation]

# The world
var world_state: WorldState = null

# The active character being played right now
var current_character: Generation = null

# Internal timer for tracking play time per generation
var _generation_timer: float = 0.0
var _timer_active: bool = false


func _ready() -> void:
	world_state = WorldState.new()


func _process(delta: float) -> void:
	if _timer_active and current_character != null:
		_generation_timer += delta
		current_character.play_time_seconds = _generation_timer


# ---------------------------------------------------------------------------
# Game lifecycle
# ---------------------------------------------------------------------------

func start_new_game(p_clan_name: String) -> void:
	clan_name = p_clan_name
	current_generation = 1
	total_years = 0
	generations = []
	world_state = WorldState.new()

	current_character = _create_generation(1, clan_name + "・初代")
	_start_timer()
	game_started.emit(clan_name)
	new_generation_started.emit(current_character)


func get_current_generation() -> Generation:
	return current_character


## Finalize the current generation and record it to history.
## cause: "old_age" | "battle" | "retired"
func end_generation(cause: String) -> void:
	if current_character == null:
		push_error("GameData.end_generation: no active character")
		return

	_stop_timer()
	current_character.finalize(total_years, cause)

	# Auto-record generation-end achievement
	var label := current_character.get_cause_of_death_label()
	current_character.add_achievement(
		"%d年、%sにより現役を退く" % [total_years, label]
	)

	generations.append(current_character)
	generation_ended.emit(current_character)

	# Advance world time by a small amount for flavour
	total_years += randi_range(2, 8)


## Start a new generation using the inherited skills and items chosen by the player.
## inherited_skills: Array[Skill]  (max 3)
## inherited_items:  Array[Item]   (max 2)
func start_next_generation(
	inherited_skills: Array,
	inherited_items: Array,
	heir_name: String = ""
) -> void:
	current_generation += 1

	var gen_name := heir_name if heir_name != "" else \
		clan_name + "・第%d代" % current_generation

	current_character = _create_generation(current_generation, gen_name)

	# Apply inherited skills — mark their origin
	var skill_count := 0
	for skill in inherited_skills:
		if skill_count >= 3:
			break
		var inherited_skill := Skill.new(
			skill.id,
			skill.display_name,
			skill.level,
			skill.category,
			skill.inherited_from_generation if skill.inherited_from_generation != -1
				else generations[-1].id
		)
		current_character.skills.append(inherited_skill)
		skill_count += 1

	# Apply inherited items
	var item_count := 0
	for item in inherited_items:
		if item_count >= 2:
			break
		item.record_usage(current_character.id)
		current_character.equipped_items.append(item)
		item_count += 1

	_start_timer()
	new_generation_started.emit(current_character)


# ---------------------------------------------------------------------------
# World changes
# ---------------------------------------------------------------------------

func add_world_change(change: WorldChange) -> void:
	if current_character == null:
		push_error("GameData.add_world_change: no active character")
		return
	change.generation_id = current_character.id
	change.year = total_years
	world_state.add_change(change)
	current_character.add_world_change(change)
	world_changed.emit(change)

	# Auto-achievement for first build, first clear, etc.
	_check_world_achievements(change)


# ---------------------------------------------------------------------------
# Chronicle
# ---------------------------------------------------------------------------

func get_chronicle_text() -> String:
	if generations.is_empty() and current_character == null:
		return "まだ記録がありません。"

	var lines: Array[String] = []
	lines.append("═══════════════════════════════════")
	lines.append("　　%s　年代記" % clan_name)
	lines.append("═══════════════════════════════════")
	lines.append("")

	# Completed generations
	for gen in generations:
		lines.append(_format_generation_entry(gen))
		lines.append("")

	# Active generation
	if current_character != null:
		lines.append("【現在の当主】")
		lines.append(_format_generation_entry(current_character, true))
		lines.append("")

	lines.append("───────────────────────────────────")
	lines.append(world_state.get_progress_label())
	lines.append("総経過年数: %d年" % total_years)

	return "\n".join(lines)


func _format_generation_entry(gen: Generation, is_active: bool = false) -> String:
	var lines: Array[String] = []

	var header := gen.get_title()
	if is_active:
		header += "（活動中）"
	lines.append(header)

	var birth_info := "生年: %d年" % gen.birth_year
	if gen.death_year != -1:
		birth_info += "　没年: %d年（享年%d）　死因: %s" % [
			gen.death_year,
			gen.get_lifespan(),
			gen.get_cause_of_death_label()
		]
	lines.append(birth_info)

	if not gen.skills.is_empty():
		lines.append("　スキル:")
		for skill in gen.skills:
			lines.append("　　・%s Lv%d [%s] %s" % [
				skill.display_name,
				skill.level,
				skill.get_category_label(),
				skill.get_inheritance_label()
			])

	if not gen.equipped_items.is_empty():
		lines.append("　所持品:")
		for item in gen.equipped_items:
			lines.append("　　・%s %s" % [item.display_name, item.get_heirloom_label()])

	if not gen.achievements.is_empty():
		lines.append("　功績:")
		for ach in gen.achievements:
			lines.append("　　◆ " + ach)

	if not gen.world_changes.is_empty():
		lines.append("　世界への貢献:")
		for change in gen.world_changes:
			lines.append("　　▶ " + change.get_summary())

	var pt_min := int(gen.play_time_seconds / 60.0)
	lines.append("　プレイ時間: %d分" % pt_min)

	return "\n".join(lines)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _create_generation(gen_id: int, gen_name: String) -> Generation:
	var gen := Generation.new(gen_id, gen_name, total_years)
	# Give first generation a starter skill
	if gen_id == 1:
		var starter := Skill.new(
			"basic_sword",
			"剣術・初歩",
			1,
			"combat",
			-1
		)
		gen.skills.append(starter)
	return gen


func _start_timer() -> void:
	_generation_timer = current_character.play_time_seconds if current_character else 0.0
	_timer_active = true


func _stop_timer() -> void:
	_timer_active = false


func _check_world_achievements(change: WorldChange) -> void:
	if current_character == null:
		return
	match change.type:
		"build":
			if world_state.get_changes_by_type("build").size() == 1:
				current_character.add_achievement("一族初の建設事業を成し遂げた")
		"clear_monster":
			if world_state.get_changes_by_type("clear_monster").size() == 1:
				current_character.add_achievement("一族初の討伐を果たした")
		"alliance":
			current_character.add_achievement(
				"%sとの同盟を結んだ" % change.description
			)
	if world_state.goal_progress >= 1.0:
		current_character.add_achievement("伝説の都市建設を完成させた！")


# ---------------------------------------------------------------------------
# Queries
# ---------------------------------------------------------------------------

func get_all_generations() -> Array:
	var all: Array = generations.duplicate()
	if current_character != null:
		all.append(current_character)
	return all


func get_generation_by_id(gen_id: int) -> Generation:
	for gen in generations:
		if gen.id == gen_id:
			return gen
	if current_character != null and current_character.id == gen_id:
		return current_character
	return null


func is_game_started() -> bool:
	return current_character != null or not generations.is_empty()
