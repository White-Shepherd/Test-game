extends Node2D

const TILE_SIZE := 48

func _ready() -> void:
	GameState.state_changed.connect(queue_redraw)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var tile := _screen_to_tile(event.position)
		GameState.select_tile(tile.x, tile.y)

func _draw() -> void:
	var s := GameState.get_state()
	var width := int(s["map"]["width"])
	var height := int(s["map"]["height"])
	for y in height:
		for x in width:
			var rect := Rect2(Vector2(x, y) * TILE_SIZE, Vector2.ONE * TILE_SIZE)
			draw_rect(rect, _terrain_color(s["map"]["tiles"]["%d,%d" % [x, y]]["terrain"]))
			draw_rect(rect, Color(0, 0, 0, 0.4), false, 1.0)
			if s["relics"]["spawned"].has("%d,%d" % [x, y]) and not s["relics"]["claimed"].has("%d,%d" % [x, y]):
				draw_circle(rect.get_center(), 6, Color.GOLD)
	for town in s["towns"].values():
		var pos := Vector2(int(town["x"]), int(town["y"])) * TILE_SIZE + Vector2(10, 8)
		draw_rect(Rect2(pos, Vector2(28, 28)), Color(0.2, 0.4, 0.8, 1.0))
	for army in s["armies"].values():
		var pos := Vector2(int(army["x"]), int(army["y"])) * TILE_SIZE + Vector2(18, 18)
		draw_circle(pos, 10, Color(0.85, 0.2, 0.2, 1.0))
	var selected := s["map"]["selected_tile"]
	if int(selected["x"]) >= 0:
		var sel_rect := Rect2(Vector2(int(selected["x"]), int(selected["y"])) * TILE_SIZE, Vector2.ONE * TILE_SIZE)
		draw_rect(sel_rect, Color(1, 1, 0, 0.15), true)
		draw_rect(sel_rect, Color.YELLOW, false, 3.0)

func _screen_to_tile(pos: Vector2) -> Vector2i:
	return Vector2i(floor(pos.x / TILE_SIZE), floor(pos.y / TILE_SIZE))

func _terrain_color(terrain_id: String) -> Color:
	match terrain_id:
		"forest":
			return Color(0.2, 0.45, 0.2)
		"hills":
			return Color(0.5, 0.4, 0.25)
		"desert":
			return Color(0.8, 0.75, 0.4)
		_:
			return Color(0.35, 0.55, 0.3)
