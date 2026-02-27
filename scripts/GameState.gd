extends Node
class_name GameState

signal state_changed
signal error_raised(message: String)

const SAVE_PATH := "user://savegame.json"
const DATA_PATH_UNITS := "res://data/unit_defs.json"
const DATA_PATH_BUILDINGS := "res://data/building_defs.json"
const DATA_PATH_TERRAIN := "res://data/terrain_defs.json"
const DATA_PATH_RELICS := "res://data/relic_defs.json"

var rng := RandomNumberGenerator.new()

var unit_defs: Dictionary = {}
var building_defs: Dictionary = {}
var terrain_defs: Dictionary = {}
var relic_defs: Dictionary = {}

var state: Dictionary = {}

func _ready() -> void:
	rng.randomize()
	_load_content()
	new_game()

func _load_content() -> void:
	unit_defs = _load_json(DATA_PATH_UNITS)
	building_defs = _load_json(DATA_PATH_BUILDINGS)
	terrain_defs = _load_json(DATA_PATH_TERRAIN)
	relic_defs = _load_json(DATA_PATH_RELICS)

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}

func new_game(width := 18, height := 12) -> void:
	state = {
		"turn": 1,
		"next_town_id": 1,
		"next_army_id": 1,
		"empire": {
			"gold": 200,
			"food": 120,
			"gold_income_mult": 1.0,
			"town_level_cap_bonus": 0,
			"unlocked_unit_tags": []
		},
		"map": {
			"width": width,
			"height": height,
			"tiles": {},
			"selected_tile": {"x": -1, "y": -1}
		},
		"towns": {},
		"armies": {},
		"relics": {
			"spawned": {},
			"claimed": []
		}
	}
	_generate_tiles()
	_spawn_relics(5)
	emit_signal("state_changed")

func _generate_tiles() -> void:
	var types := terrain_defs.get("terrain_types", ["plains"])
	for y in state["map"]["height"]:
		for x in state["map"]["width"]:
			var kind: String = types[rng.randi_range(0, max(0, types.size() - 1))]
			state["map"]["tiles"][_tile_key(x, y)] = {
				"terrain": kind,
				"town_id": -1,
				"army_id": -1
			}

func _spawn_relics(count: int) -> void:
	var relic_list: Array = relic_defs.get("relics", [])
	if relic_list.is_empty():
		return
	for i in count:
		var x := rng.randi_range(0, state["map"]["width"] - 1)
		var y := rng.randi_range(0, state["map"]["height"] - 1)
		var tile_key := _tile_key(x, y)
		if state["relics"]["spawned"].has(tile_key):
			continue
		var relic := relic_list[rng.randi_range(0, relic_list.size() - 1)]
		state["relics"]["spawned"][tile_key] = relic

func get_state() -> Dictionary:
	return state.duplicate(true)

func select_tile(x: int, y: int) -> void:
	if not _is_inside(x, y):
		return
	state["map"]["selected_tile"] = {"x": x, "y": y}
	emit_signal("state_changed")

func build_town(x: int, y: int, name := "New Town") -> bool:
	if not _is_inside(x, y):
		return _error("Invalid tile")
	var tile := _get_tile(x, y)
	if int(tile["town_id"]) != -1:
		return _error("Tile already has a town")
	var town_id := state["next_town_id"]
	state["next_town_id"] += 1
	state["towns"][str(town_id)] = {
		"id": town_id,
		"name": "%s %d" % [name, town_id],
		"x": x,
		"y": y,
		"level": 1,
		"buildings": [],
		"garrison": {"militia": 1},
		"base_gold": 20,
		"base_food": 12
	}
	tile["town_id"] = town_id
	_check_relic_claim(x, y)
	emit_signal("state_changed")
	return true

func upgrade_town(town_id: int) -> bool:
	var key := str(town_id)
	if not state["towns"].has(key):
		return _error("Town not found")
	var town: Dictionary = state["towns"][key]
	var level_cap := 5 + int(state["empire"].get("town_level_cap_bonus", 0))
	if int(town["level"]) >= level_cap:
		return _error("Town at level cap")
	var cost := 50 * int(town["level"])
	if state["empire"]["gold"] < cost:
		return _error("Not enough gold")
	state["empire"]["gold"] -= cost
	town["level"] += 1
	emit_signal("state_changed")
	return true

func construct_building(town_id: int, building_id: String) -> bool:
	var key := str(town_id)
	if not state["towns"].has(key):
		return _error("Town not found")
	var defs: Dictionary = building_defs.get("buildings", {})
	if not defs.has(building_id):
		return _error("Building not defined")
	var town: Dictionary = state["towns"][key]
	if town["buildings"].has(building_id):
		return _error("Building already exists")
	var cost := int(defs[building_id].get("cost_gold", 0))
	if state["empire"]["gold"] < cost:
		return _error("Not enough gold")
	state["empire"]["gold"] -= cost
	town["buildings"].append(building_id)
	emit_signal("state_changed")
	return true

func recruit(town_id: int, unit_id: String, to_army := false) -> bool:
	var town_key := str(town_id)
	if not state["towns"].has(town_key):
		return _error("Town not found")
	var unit_data := unit_defs.get("units", {}).get(unit_id, null)
	if unit_data == null:
		return _error("Unit not defined")
	if not _unit_unlocked(unit_data):
		return _error("Unit tag not unlocked")
	var gold_cost := int(unit_data.get("cost_gold", 0))
	var food_cost := int(unit_data.get("cost_food", 0))
	if state["empire"]["gold"] < gold_cost or state["empire"]["food"] < food_cost:
		return _error("Not enough resources")
	state["empire"]["gold"] -= gold_cost
	state["empire"]["food"] -= food_cost
	var town: Dictionary = state["towns"][town_key]
	if to_army:
		var army_id := _army_at(town["x"], town["y"])
		if army_id == -1:
			army_id = _spawn_army(town["x"], town["y"])
		var army: Dictionary = state["armies"][str(army_id)]
		army["units"][unit_id] = int(army["units"].get(unit_id, 0)) + 1
	else:
		town["garrison"][unit_id] = int(town["garrison"].get(unit_id, 0)) + 1
	emit_signal("state_changed")
	return true

func move_army(army_id: int, target_x: int, target_y: int) -> bool:
	var key := str(army_id)
	if not state["armies"].has(key):
		return _error("Army not found")
	if not _is_inside(target_x, target_y):
		return _error("Invalid destination")
	var army: Dictionary = state["armies"][key]
	var distance := abs(target_x - int(army["x"])) + abs(target_y - int(army["y"]))
	if distance > int(army["move_points"]):
		return _error("Not enough movement")
	if _army_at(target_x, target_y) != -1:
		return _error("Tile occupied by army")
	_get_tile(army["x"], army["y"])["army_id"] = -1
	army["x"] = target_x
	army["y"] = target_y
	army["move_points"] -= distance
	_get_tile(target_x, target_y)["army_id"] = army_id
	_check_relic_claim(target_x, target_y)
	emit_signal("state_changed")
	return true

func end_turn() -> void:
	var total_gold := 0
	var total_food := 0
	for town in state["towns"].values():
		var level := int(town["level"])
		var town_gold := int(town["base_gold"]) + level * 6
		var town_food := int(town["base_food"]) + level * 4
		for building_id in town["buildings"]:
			var b_def: Dictionary = building_defs.get("buildings", {}).get(building_id, {})
			town_gold += int(b_def.get("gold_bonus", 0))
			town_food += int(b_def.get("food_bonus", 0))
		total_gold += town_gold
		total_food += town_food
	var upkeep_gold := 0
	var upkeep_food := 0
	for army in state["armies"].values():
		army["move_points"] = int(army.get("max_move_points", 4))
		for unit_id in army["units"].keys():
			var count := int(army["units"][unit_id])
			var u_def: Dictionary = unit_defs.get("units", {}).get(unit_id, {})
			upkeep_gold += int(u_def.get("upkeep_gold", 0)) * count
			upkeep_food += int(u_def.get("upkeep_food", 0)) * count
	for town in state["towns"].values():
		for unit_id in town["garrison"].keys():
			var g_count := int(town["garrison"][unit_id])
			var ug_def: Dictionary = unit_defs.get("units", {}).get(unit_id, {})
			upkeep_gold += int(ug_def.get("upkeep_gold", 0)) * g_count
			upkeep_food += int(ug_def.get("upkeep_food", 0)) * g_count
	var income_mult := float(state["empire"].get("gold_income_mult", 1.0))
	state["empire"]["gold"] += int(round(total_gold * income_mult)) - upkeep_gold
	state["empire"]["food"] += total_food - upkeep_food
	state["turn"] += 1
	emit_signal("state_changed")

func save() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return _error("Could not open save file")
	file.store_string(JSON.stringify(state, "\t"))
	return true

func load() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return _error("No save file found")
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return _error("Could not open save file")
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is not Dictionary:
		return _error("Invalid save data")
	state = parsed
	emit_signal("state_changed")
	return true

func _unit_unlocked(unit_data: Dictionary) -> bool:
	var required_tag := str(unit_data.get("required_tag", ""))
	if required_tag.is_empty():
		return true
	return state["empire"]["unlocked_unit_tags"].has(required_tag)

func _spawn_army(x: int, y: int) -> int:
	var army_id := state["next_army_id"]
	state["next_army_id"] += 1
	state["armies"][str(army_id)] = {
		"id": army_id,
		"x": x,
		"y": y,
		"move_points": 4,
		"max_move_points": 4,
		"units": {}
	}
	_get_tile(x, y)["army_id"] = army_id
	return army_id

func _check_relic_claim(x: int, y: int) -> void:
	var key := _tile_key(x, y)
	if not state["relics"]["spawned"].has(key):
		return
	if state["relics"]["claimed"].has(key):
		return
	var relic: Dictionary = state["relics"]["spawned"][key]
	state["relics"]["claimed"].append(key)
	_apply_relic_modifier(relic)

func _apply_relic_modifier(relic: Dictionary) -> void:
	for mod in relic.get("modifiers", []):
		var kind := str(mod.get("type", ""))
		match kind:
			"gold_income_mult":
				state["empire"]["gold_income_mult"] += float(mod.get("value", 0.0))
			"town_level_cap_bonus":
				state["empire"]["town_level_cap_bonus"] += int(mod.get("value", 0))
			"unlock_unit_tag":
				var tag := str(mod.get("value", ""))
				if not tag.is_empty() and not state["empire"]["unlocked_unit_tags"].has(tag):
					state["empire"]["unlocked_unit_tags"].append(tag)

func _army_at(x: int, y: int) -> int:
	return int(_get_tile(x, y).get("army_id", -1))

func _get_tile(x: int, y: int) -> Dictionary:
	return state["map"]["tiles"][_tile_key(x, y)]

func _tile_key(x: int, y: int) -> String:
	return "%d,%d" % [x, y]

func _is_inside(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < int(state["map"]["width"]) and y < int(state["map"]["height"])

func _error(msg: String) -> bool:
	emit_signal("error_raised", msg)
	return false
