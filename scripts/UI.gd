extends Control

@onready var summary_label: Label = %SummaryLabel
@onready var selection_label: Label = %SelectionLabel
@onready var town_label: Label = %TownLabel
@onready var army_label: Label = %ArmyLabel
@onready var status_label: Label = %StatusLabel

func _ready() -> void:
	GameState.state_changed.connect(_refresh)
	GameState.error_raised.connect(_on_error)
	_refresh()

func _refresh() -> void:
	var s := GameState.get_state()
	summary_label.text = "Turn %d | Gold %d | Food %d" % [s["turn"], s["empire"]["gold"], s["empire"]["food"]]
	var sel := s["map"]["selected_tile"]
	selection_label.text = "Selected: (%d, %d)" % [sel["x"], sel["y"]]
	town_label.text = _town_text(s)
	army_label.text = _army_text(s)
	status_label.text = ""

func _town_text(s: Dictionary) -> String:
	var sel := s["map"]["selected_tile"]
	if int(sel["x"]) < 0:
		return "Town: none"
	var tile := s["map"]["tiles"].get("%d,%d" % [sel["x"], sel["y"]], {})
	var town_id := int(tile.get("town_id", -1))
	if town_id == -1:
		return "Town: empty tile"
	var town := s["towns"][str(town_id)]
	return "Town %s | Lv %d | Buildings: %s | Garrison: %s" % [town["name"], town["level"], ", ".join(town["buildings"]), str(town["garrison"])]

func _army_text(s: Dictionary) -> String:
	var sel := s["map"]["selected_tile"]
	if int(sel["x"]) < 0:
		return "Army: none"
	var tile := s["map"]["tiles"].get("%d,%d" % [sel["x"], sel["y"]], {})
	var army_id := int(tile.get("army_id", -1))
	if army_id == -1:
		return "Army: none"
	var army := s["armies"][str(army_id)]
	return "Army %d | Move %d/%d | Units %s" % [army_id, army["move_points"], army["max_move_points"], str(army["units"])]

func _on_error(msg: String) -> void:
	status_label.text = msg

func _selected() -> Dictionary:
	var s := GameState.get_state()
	return s["map"]["selected_tile"]

func _selected_town_id() -> int:
	var s := GameState.get_state()
	var sel := s["map"]["selected_tile"]
	var tile := s["map"]["tiles"].get("%d,%d" % [sel["x"], sel["y"]], {})
	return int(tile.get("town_id", -1))

func _selected_army_id() -> int:
	var s := GameState.get_state()
	var sel := s["map"]["selected_tile"]
	var tile := s["map"]["tiles"].get("%d,%d" % [sel["x"], sel["y"]], {})
	return int(tile.get("army_id", -1))

func _on_build_town_pressed() -> void:
	var sel := _selected()
	GameState.build_town(int(sel["x"]), int(sel["y"]), "Town")

func _on_upgrade_town_pressed() -> void:
	var id := _selected_town_id()
	if id != -1:
		GameState.upgrade_town(id)

func _on_market_pressed() -> void:
	var id := _selected_town_id()
	if id != -1:
		GameState.construct_building(id, "market")

func _on_granary_pressed() -> void:
	var id := _selected_town_id()
	if id != -1:
		GameState.construct_building(id, "granary")

func _on_barracks_pressed() -> void:
	var id := _selected_town_id()
	if id != -1:
		GameState.construct_building(id, "barracks")

func _on_smith_pressed() -> void:
	var id := _selected_town_id()
	if id != -1:
		GameState.construct_building(id, "smith")

func _on_recruit_militia_pressed() -> void:
	var id := _selected_town_id()
	if id != -1:
		GameState.recruit(id, "militia", false)

func _on_recruit_archer_pressed() -> void:
	var id := _selected_town_id()
	if id != -1:
		GameState.recruit(id, "archer", true)

func _on_recruit_cavalry_pressed() -> void:
	var id := _selected_town_id()
	if id != -1:
		GameState.recruit(id, "cavalry", true)

func _on_move_up_pressed() -> void:
	_move_selected_army(Vector2i(0, -1))

func _on_move_down_pressed() -> void:
	_move_selected_army(Vector2i(0, 1))

func _on_move_left_pressed() -> void:
	_move_selected_army(Vector2i(-1, 0))

func _on_move_right_pressed() -> void:
	_move_selected_army(Vector2i(1, 0))

func _move_selected_army(offset: Vector2i) -> void:
	var army_id := _selected_army_id()
	if army_id == -1:
		return
	var sel := _selected()
	GameState.move_army(army_id, int(sel["x"]) + offset.x, int(sel["y"]) + offset.y)

func _on_end_turn_pressed() -> void:
	GameState.end_turn()

func _on_save_pressed() -> void:
	GameState.save()
	status_label.text = "Saved to user://savegame.json"

func _on_load_pressed() -> void:
	GameState.load()
	status_label.text = "Loaded from user://savegame.json"
