extends TileMap

# Signal, das ausgelöst wird, wenn das Layout aktualisiert wird.
signal layout_updated

# Variable, die angibt, ob gerade eine Wand platziert wird.
var is_placing_wall := false
# Variable, die angibt, ob gerade eine Zelle gezogen wird.
var is_dragging := false
# Die letzte Zellenposition der Maus.
var last_mouse_cell: Vector2i

# Verarbeitet Eingaben, die nicht anderweitig behandelt wurden.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# LMB zum Platzieren von Wänden, RMB zum Entfernen
		is_placing_wall = event.button_index == MOUSE_BUTTON_MASK_LEFT
		is_dragging = event.pressed
		if is_dragging:
			last_mouse_cell = local_to_map(get_local_mouse_position())
			set_cell_to_drag_value(last_mouse_cell)
			layout_updated.emit() # Signalisiert, dass das Layout aktualisiert wurde.
		return
	
	if event is InputEventMouseMotion and is_dragging:
		var current_cell = local_to_map(get_local_mouse_position())
		
		var line = get_line(last_mouse_cell, current_cell)
		for point in line:
			set_cell_to_drag_value(point)

		if line.size() > 0:
			layout_updated.emit() # Signalisiert, dass das Layout aktualisiert wurde.
		last_mouse_cell = current_cell

# Setzt den Zellenwert basierend auf der Zellenposition beim Ziehen.
func set_cell_to_drag_value(cell: Vector2i) -> void:
	var current_source_id = 3 # TileSet ID
	var coordinatesvalueX = 1 # Tile-Koordinate
	var coordinatesvalueY = 8 # Tile-Koordinate
	if !is_placing_wall:
		current_source_id = 3
		coordinatesvalueX = 0
		coordinatesvalueY = 12
	set_cell(0, cell, current_source_id, Vector2i(coordinatesvalueX, coordinatesvalueY))
	# Debug-Ausgaben
	var tile_data = get_cell_tile_data(0, cell)
	if tile_data:
		var custom_data_layer = tile_data.get_custom_data('tile_type')
		print("Platziertes Tile: ", cell, "mit Tile Type: ", custom_data_layer)
	else:
		print("Keine TileData gefunden für: ", cell)

# Berechnet eine Linie von Start- zu Endzelle.
func get_line(start: Vector2i, end: Vector2i) -> Array:
	var points = []
	
	var delta = end - start
	var n = max(abs(delta.x), abs(delta.y))
	
	for step in range(n):
		var t = step / n
		var lerp_point = Vector2(start).lerp(Vector2(end), t)
		var rounded_point = lerp_point.floor()
		points.append(rounded_point)

	points.append(end)
	return points
