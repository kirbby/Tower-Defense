##Dokumentation für BasicMapSceneAstarGrid.gd
##Überblick
##Dieses Skript steuert die Hauptlogik für die Erstellung und Aktualisierung des A* Pfadfindungs-Grids in einem Tower Defense-Spiel. Es verwaltet die dynamische Platzierung von Hindernissen, die Spawn- und Zielorte für Gegner und die Routenfindung der Gegner durch das Spielfeld.

##Kernfunktionalitäten
##-Initialisierung des AStarGrids: Beim Start des Spiels oder wenn sich die Spielumgebung ändert, wird das AStarGrid basierend auf den aktuellen Spielkarteninformationen initialisiert und aktualisiert.
##-Pfadfindung: Berechnet den optimalen Weg für Gegner von einem Spawn-Punkt zu einem Ziel unter Berücksichtigung der platzierten Hindernisse.
##-Gegnermanagement: Erstellt Gegner-Instanzen entlang des berechneten Pfades und aktualisiert ihre Routen, wenn Änderungen in der Spielumgebung auftreten.

##Signalverbindungen und Interaktionen
##-UI-Interaktionen: Das Skript abonniert das options_updated Signal von der UI, um Änderungen in den Pfadfindungsoptionen (wie Heuristik, diagonale Bewegung, Sprungfähigkeit) zu empfangen und darauf zu reagieren.
##-------ui.options_updated.connect(_on_options_updated)-------

##-Gegner-Signale: Das Skript verbindet sich mit dem enemy_removed Signal jedes erstellten Gegners, um den Gegner bei Bedarf aus der internen Verwaltung zu entfernen.
##----------enemy_instance.connect("enemy_removed", Callable(self, "_on_enemy_removed"))--------

##Wichtige Methoden
##-_init_grid(): Initialisiert das AStarGrid basierend auf der aktuellen Spielkarte.
##-_update_grid_from_tilemap(): Aktualisiert das Grid, wenn Hindernisse platziert oder entfernt werden.
##-add_enemy_to_path(): Erstellt einen Gegner und platziert ihn auf dem berechneten Pfad.
##-update_all_enemies_path(): Aktualisiert die Pfade für alle Gegner, wenn sich die Spielumgebung ändert.
##Verbesserungsvorschläge
##-Signalverarbeitung optimieren: Stelle sicher, dass die Signalverarbeitung effizient ist, besonders bei häufigen Änderungen in der Spielumgebung.

extends Node2D

# Verweise auf Spielobjekte und UI-Elemente, die für die Pfadfindung und Spiellogik benötigt werden.
@onready var game_map = $GameMap as TileMap # Die Spielkarte.
@onready var path = $path # Der Pfad, der im Spiel dargestellt wird.
@onready var start = $spawn_zone_Scene # Startpunkt der Gegner.
@onready var goal = $end_zone_Scene # Ziel der Gegner.
@onready var ui = $pathfinding_settings_ui # Benutzeroberfläche für Einstellungen und Interaktionen.
@onready var camera = $Camera2D as Camera2D


signal path_updated(path_positions)

# Gegner-Szene, die für die Erstellung neuer Gegner-Instanzen vorab geladen wird.
var enemy_scene = preload("res://enemies/Enemy T2/enemy_t_2.tscn")
# Die AStarGrid-Instanz, die für die Berechnung von Pfaden verwendet wird.
var astar_grid: AStarGrid2D
# Start- und Zielzellen im AStar-Grid, die für die Pfadfindung verwendet werden.
var start_cell: Vector2i
var end_cell: Vector2i
# Array zur Speicherung von aktiven Gegner-Instanzen.
var enemies: Array = []



func _ready() -> void:
	## Wird aufgerufen, wenn das Skript zum ersten Mal ausgeführt wird.
	# Verbindet UI-Signale mit Methoden, initialisiert das AStar-Grid und findet den ersten Pfad.
	ui.options_updated.connect(_on_options_updated) # Verbindung zum UI-Signal für Optionen-Aktualisierungen.
	_init_grid() # Initialisiert das AStar-Grid basierend auf der aktuellen Spielkarte.
	_update_grid_from_tilemap() # Aktualisiert das Grid, um Hindernisse zu berücksichtigen.
	find_path() # Findet den ersten Pfad von Start zu Ziel.
	queue_redraw() # Fordert ein Neuzeichnen des Spielfensters an, um Änderungen sichtbar zu machen.
	var map_limits := game_map.get_used_rect()
	var tile_size: Vector2 = game_map.tile_set.tile_size
	camera.limit_left = map_limits.position.x * tile_size.x
	camera.limit_top = map_limits.position.y * tile_size.y
	camera.limit_right = map_limits.end.x * tile_size.x
	camera.limit_bottom = map_limits.end.y * tile_size.y






func _on_layout_updated() -> void:
	## Wird aufgerufen, wenn das Layout der Spielkarte aktualisiert wird, z.B. durch das Platzieren oder Entfernen von Hindernissen.
	# Aktualisiert das AStar-Grid und findet den Pfad neu.
	_update_grid_from_tilemap() # Aktualisiert das Grid mit den neuesten Änderungen.
	find_path() # Findet den Pfad neu basierend auf dem aktualisierten Grid.
	queue_redraw() # Fordert erneut ein Neuzeichnen an, um die aktualisierten Informationen anzuzeigen.

func _on_options_updated(heuristic: int, diagonal: int, jump: bool) -> void:
	## Reagiert auf Änderungen der Pfadfindungsoptionen durch den Benutzer über die UI.
	# Aktualisiert die Heuristik-, Diagonal- und Sprung-Einstellungen des AStarGrids und sucht den Pfad neu.
	astar_grid.default_compute_heuristic = heuristic # Setzt die Heuristik für die Pfadberechnung.
	astar_grid.default_estimate_heuristic = heuristic # Setzt die Heuristik für die Pfadschätzung.
	astar_grid.diagonal_mode = diagonal # Aktiviert/Deaktiviert diagonale Bewegungen.
	astar_grid.jumping_enabled = jump # Aktiviert/Deaktiviert Sprungfähigkeiten im Pfad.
	
	find_path() # Findet den Pfad basierend auf den neuen Einstellungen.
	queue_redraw() # Fordert ein Neuzeichnen an, um den neuen Pfad anzuzeigen.

func _on_spawn_end_zone_scene_position_updated() -> void:
	## Wird aufgerufen, wenn die Position des Spawn-Punkts oder des Ziels geändert wird.
	# Aktualisiert die Start- und Zielzellen im AStar-Grid und sucht den Pfad neu.
	var new_start_cell = game_map.local_to_map(start.position) # Konvertiert die neue Startposition in Grid-Koordinaten.
	var new_end_cell = game_map.local_to_map(goal.position) # Konvertiert die neue Zielposition in Grid-Koordinaten.
	
	if new_start_cell != start_cell or new_end_cell != end_cell:
		start_cell = new_start_cell # Aktualisiert die Startzelle.
		end_cell = new_end_cell # Aktualisiert die Zielzelle.
		find_path() # Findet den Pfad neu basierend auf den aktualisierten Positionen.
		queue_redraw() # Fordert ein Neuzeichnen an, um den aktualisierten Pfad anzuzeigen.
		update_all_enemies_path() # Aktualisiert die Pfade aller Gegner, um die neuen Start- und Zielpositionen zu berücksichtigen.

func _init_grid() -> void:
	## Initialisiert das AStar-Grid basierend auf der Größe und den Eigenschaften der Spielkarte.
	# Bereitet das Grid für die Pfadfindung vor.
	astar_grid = AStarGrid2D.new() # Erstellt eine neue Instanz des AStarGrids.
	astar_grid.size = game_map.get_used_rect().size # Setzt die Größe des Grids entsprechend der genutzten Fläche der Spielkarte.
	astar_grid.cell_size = game_map.tile_set.tile_size # Setzt die Zellengröße des Grids entsprechend der Zellengröße des TileSets.
	astar_grid.update() # Aktualisiert das Grid, um es für die Pfadfindung vorzubereiten.
	queue_redraw() # Fordert ein Neuzeichnen an, um das initialisierte Grid anzuzeigen.

func _update_grid_from_tilemap() -> void:
	## Überprüft jede Zelle der TileMap und aktualisiert das AStar-Grid entsprechend.
	# Zellen, die Hindernisse enthalten (z.B. Wände), werden als solide markiert.
	for i in range(astar_grid.size.x):
		for j in range(astar_grid.size.y):
			var id = Vector2i(i, j)
			# Überprüft, ob in der aktuellen Zelle ein Hindernis-Tile platziert ist.
			if game_map.get_cell_source_id(0, id) >= 0:
				var tile_type = game_map.get_cell_tile_data(0, id).get_custom_data('tile_type')
				# Setzt den Punkt im AStar-Grid als solide, wenn der Tile-Typ 'wall' ist.
				astar_grid.set_point_solid(Vector2i(i, j), tile_type == 'wall')
			else:
				# Setzt den Punkt als solide, wenn keine Tile-Information vorhanden ist.
				astar_grid.set_point_solid(Vector2i(i, j), true)
	queue_redraw() # Fordert ein Neuzeichnen des Grids an, um Änderungen sichtbar zu machen.
	update_all_enemies_path() # Aktualisiert die Pfade aller Gegner basierend auf den neuen Grid-Daten.

func find_path() -> void:
	## Berechnet den optimalen Pfad von der Start- zur Zielzelle unter Verwendung des AStar-Grids.
	path.clear() # Löscht den aktuellen Pfad.
	start_cell = game_map.local_to_map(start.position) # Konvertiert die Startposition in Grid-Koordinaten.
	end_cell = game_map.local_to_map(goal.position) # Konvertiert die Zielposition in Grid-Koordinaten.
	# Überprüft, ob ein gültiger Pfad existieren kann.
	if start_cell == end_cell or !astar_grid.is_in_boundsv(start_cell) or !astar_grid.is_in_boundsv(end_cell):
		return # Beendet die Funktion frühzeitig, wenn kein Pfad gefunden werden kann.
	var id_path = astar_grid.get_id_path(start_cell, end_cell) # Erhält den Pfad als Liste von Punkt-IDs.
	var path_positions = []
	for id in id_path:
		path_positions.append(astar_grid.get_point_position(id))
		emit_signal("path_updated", path_positions)
		# Zeichnet den Pfad auf der TileMap für visuelle Darstellung.
		path.set_cell(0, id, 4, Vector2(0, 0))
	queue_redraw() # Fordert ein Neuzeichnen des Pfads an.

# Fügt Gegner basierend auf dem gefundenen Pfad hinzu und aktualisiert ihre Pfade.
# Diese Funktion wird aufgerufen, nachdem ein optimaler Pfad gefunden wurde.
# 	add_enemy_to_path(id_path)
	update_all_enemies_path()

func add_enemy_to_path(id_path: Array) -> void:
	## Erstellt und platziert Gegner-Instanzen entlang des Pfads.
	# Instanziert einen Gegner aus der vorab geladenen Szene.
	var enemy_instance = enemy_scene.instantiate()
	var path_positions = []
	# Erstellt eine Liste von Pfadpositionen basierend auf den Punkt-IDs im Pfad.
	for id in id_path:
		path_positions.append(astar_grid.get_point_position(id))
	enemy_instance.set_path(path_positions) # Setzt den Pfad für den Gegner.
	# Verbindet das Signal 'enemy_removed' des Gegners mit der Funktion '_on_enemy_removed' in diesem Skript.
	enemy_instance.connect("enemy_removed", Callable(self, "_on_enemy_removed"))
	add_child(enemy_instance) # Fügt den Gegner der Szene hinzu.
	enemies.append(enemy_instance) # Fügt den Gegner dem Array hinzu.

func update_all_enemies_path() -> void:
	## Aktualisiert die Pfade aller Gegner basierend auf dem aktuellen Pfad.
	var id_path = astar_grid.get_id_path(start_cell, end_cell) # Erhält den aktuellen Pfad.
	var path_positions = []
	for id in id_path:
		path_positions.append(astar_grid.get_point_position(id)) # Erstellt eine Liste von Pfadpositionen.
	# Erstellt eine Kopie der Gegner-Instanzen, um sie zu durchlaufen.
	var valid_enemies = enemies.duplicate()
	for enemy in valid_enemies:
		if not is_instance_valid(enemy): # Überprüft, ob der Gegner noch gültig ist.
			enemies.erase(enemy) # Entfernt ungültige Gegner aus dem Array.
		else:
			enemy.set_path(path_positions) # Aktualisiert den Pfad des Gegners.

# Zeichnet das Grid zur Visualisierung von blockierten und nicht-blockierten Feldern.
# Diese Funktion wird automatisch von Godot aufgerufen, um das Grid zu zeichnen.
func _draw() -> void:
	# Durchläuft das Grid und zeichnet jedes Feld entsprechend seinem Status.
	for i in range(astar_grid.size.x):
		for j in range(astar_grid.size.y):
			var id = Vector2i(i, j)
			var position = astar_grid.get_point_position(id)
			var size = astar_grid.cell_size
			var rect = Rect2(position, size)
			
			if astar_grid.is_point_solid(id):
				# Blockierte Felder werden in Rot gezeichnet.
				draw_rect(rect, Color.RED, false)
			else:
				# Überprüft, ob das Feld an ein blockiertes Feld grenzt.
				var is_adjacent_to_solid = false
				for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
					var neighbor_id = id + offset
					if astar_grid.is_in_boundsv(neighbor_id) and astar_grid.is_point_solid(neighbor_id):
						is_adjacent_to_solid = true
						break
				
				if is_adjacent_to_solid:
					# Felder, die an blockierte Felder grenzen, werden in Orange gezeichnet.
					draw_rect(rect, Color.ORANGE, false)
				else:
					# Nicht-blockierte Felder werden in Grün gezeichnet.
					draw_rect(rect, Color.GREEN, false)

# Entfernt einen Gegner aus dem Array der Gegner, wenn dieser entfernt wird.
# Diese Funktion wird aufgerufen, wenn das Signal 'enemy_removed' von einem Gegner emittiert wird.
func _on_enemy_removed(enemy: Node) -> void:
	if enemy in enemies:
		enemies.erase(enemy) # Entfernt den Gegner aus dem Array der Gegner.



func _on_ui_options_updated(heuristic, diagonal, jump):
	pass # Replace with function body.



######################

#
#
#
#extends Node2D
#
## Verweise auf Spielobjekte und UI-Elemente, die für die Pfadfindung und Spiellogik benötigt werden.
#@onready var game_map = $GameMap as TileMap # Die Spielkarte.
#@onready var path = $path # Der Pfad, der im Spiel dargestellt wird.
#@onready var start = $spawn_zone_Scene # Startpunkt der Gegner.
#@onready var goal = $end_zone_Scene # Ziel der Gegner.
#@onready var ui = $pathfinding_settings_ui # Benutzeroberfläche für Einstellungen und Interaktionen.
#@onready var camera = $Camera2D as Camera2D
#
#
#signal path_updated(path_positions)
#
## Gegner-Szene, die für die Erstellung neuer Gegner-Instanzen vorab geladen wird.
#var enemy_scene = preload("res://enemies/Enemy T2/enemy_t_2.tscn")
## Die AStarGrid-Instanz, die für die Berechnung von Pfaden verwendet wird.
#var astar_grid: AStarGrid2D
## Start- und Zielzellen im AStar-Grid, die für die Pfadfindung verwendet werden.
#var start_cell: Vector2i
#var end_cell: Vector2i
## Array zur Speicherung von aktiven Gegner-Instanzen.
#var enemies: Array = []
#var spawn_zones = []
## Liste der Pfade zu den Spawn-Zonen-Szenen
#var spawn_zone_paths = [
	#"res://spawn_zone/spawn_zone_Scene.tscn",
	#"res://spawn_zone/spawn_zone_Scene_all.tscn",
	## Fügen Sie hier weitere Pfade hinzu
	#]
#
#
#func _ready() -> void:
	#find_spawn_zones()
	#load_and_initialize_spawn_zones()
	### Wird aufgerufen, wenn das Skript zum ersten Mal ausgeführt wird.
	## Verbindet UI-Signale mit Methoden, initialisiert das AStar-Grid und findet den ersten Pfad.
	#ui.options_updated.connect(_on_options_updated) # Verbindung zum UI-Signal für Optionen-Aktualisierungen.
	#_init_grid() # Initialisiert das AStar-Grid basierend auf der aktuellen Spielkarte.
	#_update_grid_from_tilemap() # Aktualisiert das Grid, um Hindernisse zu berücksichtigen.
	#find_path() # Findet den ersten Pfad von Start zu Ziel.
	#queue_redraw() # Fordert ein Neuzeichnen des Spielfensters an, um Änderungen sichtbar zu machen.
	#var map_limits := game_map.get_used_rect()
	#var tile_size: Vector2 = game_map.tile_set.tile_size
	#camera.limit_left = map_limits.position.x * tile_size.x
	#camera.limit_top = map_limits.position.y * tile_size.y
	#camera.limit_right = map_limits.end.x * tile_size.x
	#camera.limit_bottom = map_limits.end.y * tile_size.y
#
#
#func find_spawn_zones():
	#spawn_zones = get_tree().get_nodes_in_group("spawn_zone")
#
#func load_and_initialize_spawn_zones():
	#for spawn_zone_path in spawn_zone_paths:
		#var spawn_zone_resource = load(spawn_zone_path)
		#if spawn_zone_resource is PackedScene:
			#var spawn_zone_instance = spawn_zone_resource.instance()
			#add_child(spawn_zone_instance)
			#initialize_spawn_zone(spawn_zone_instance)
		#else:
			#print("Fehler: Der Pfad", spawn_zone_path, "ist keine gültige PackedScene.")
#
#
#func initialize_spawn_zone(spawn_zone_instance):
	#var spawn_container = spawn_zone_instance.get_node("SpawnContainer")
	#if spawn_container:
		#var spawn_locations = []
		#for marker in spawn_container.get_children():
			#if marker is Marker2D: # Stellen Sie sicher, dass das Kind ein Marker2D ist
				#spawn_locations.append(marker.global_position)
		## Hier können Sie spawn_locations für das Spawnen von Gegnern verwenden
		## Zum Beispiel könnten Sie spawn_locations an eine Gegner-Management-Funktion übergeben
#
#
#
#
#
#func _on_layout_updated() -> void:
	### Wird aufgerufen, wenn das Layout der Spielkarte aktualisiert wird, z.B. durch das Platzieren oder Entfernen von Hindernissen.
	## Aktualisiert das AStar-Grid und findet den Pfad neu.
	#_update_grid_from_tilemap() # Aktualisiert das Grid mit den neuesten Änderungen.
	#find_path() # Findet den Pfad neu basierend auf dem aktualisierten Grid.
	#queue_redraw() # Fordert erneut ein Neuzeichnen an, um die aktualisierten Informationen anzuzeigen.
#
#func _on_options_updated(heuristic: int, diagonal: int, jump: bool) -> void:
	### Reagiert auf Änderungen der Pfadfindungsoptionen durch den Benutzer über die UI.
	## Aktualisiert die Heuristik-, Diagonal- und Sprung-Einstellungen des AStarGrids und sucht den Pfad neu.
	#astar_grid.default_compute_heuristic = heuristic # Setzt die Heuristik für die Pfadberechnung.
	#astar_grid.default_estimate_heuristic = heuristic # Setzt die Heuristik für die Pfadschätzung.
	#astar_grid.diagonal_mode = diagonal # Aktiviert/Deaktiviert diagonale Bewegungen.
	#astar_grid.jumping_enabled = jump # Aktiviert/Deaktiviert Sprungfähigkeiten im Pfad.
	#
	#find_path() # Findet den Pfad basierend auf den neuen Einstellungen.
	#queue_redraw() # Fordert ein Neuzeichnen an, um den neuen Pfad anzuzeigen.
#
#func _on_spawn_end_zone_scene_position_updated() -> void:
	### Wird aufgerufen, wenn die Position des Spawn-Punkts oder des Ziels geändert wird.
	## Aktualisiert die Start- und Zielzellen im AStar-Grid und sucht den Pfad neu.
	#var new_start_cell = game_map.local_to_map(start.position) # Konvertiert die neue Startposition in Grid-Koordinaten.
	#var new_end_cell = game_map.local_to_map(goal.position) # Konvertiert die neue Zielposition in Grid-Koordinaten.
	#
	#if new_start_cell != start_cell or new_end_cell != end_cell:
		#start_cell = new_start_cell # Aktualisiert die Startzelle.
		#end_cell = new_end_cell # Aktualisiert die Zielzelle.
		#find_path() # Findet den Pfad neu basierend auf den aktualisierten Positionen.
		#queue_redraw() # Fordert ein Neuzeichnen an, um den aktualisierten Pfad anzuzeigen.
		#update_all_enemies_path() # Aktualisiert die Pfade aller Gegner, um die neuen Start- und Zielpositionen zu berücksichtigen.
#
#func _init_grid() -> void:
	### Initialisiert das AStar-Grid basierend auf der Größe und den Eigenschaften der Spielkarte.
	## Bereitet das Grid für die Pfadfindung vor.
	#astar_grid = AStarGrid2D.new() # Erstellt eine neue Instanz des AStarGrids.
	#astar_grid.size = game_map.get_used_rect().size # Setzt die Größe des Grids entsprechend der genutzten Fläche der Spielkarte.
	#astar_grid.cell_size = game_map.tile_set.tile_size # Setzt die Zellengröße des Grids entsprechend der Zellengröße des TileSets.
	#astar_grid.update() # Aktualisiert das Grid, um es für die Pfadfindung vorzubereiten.
	#queue_redraw() # Fordert ein Neuzeichnen an, um das initialisierte Grid anzuzeigen.
#
#func _update_grid_from_tilemap() -> void:
	### Überprüft jede Zelle der TileMap und aktualisiert das AStar-Grid entsprechend.
	## Zellen, die Hindernisse enthalten (z.B. Wände), werden als solide markiert.
	#for i in range(astar_grid.size.x):
		#for j in range(astar_grid.size.y):
			#var id = Vector2i(i, j)
			## Überprüft, ob in der aktuellen Zelle ein Hindernis-Tile platziert ist.
			#if game_map.get_cell_source_id(0, id) >= 0:
				#var tile_type = game_map.get_cell_tile_data(0, id).get_custom_data('tile_type')
				## Setzt den Punkt im AStar-Grid als solide, wenn der Tile-Typ 'wall' ist.
				#astar_grid.set_point_solid(Vector2i(i, j), tile_type == 'wall')
			#else:
				## Setzt den Punkt als solide, wenn keine Tile-Information vorhanden ist.
				#astar_grid.set_point_solid(Vector2i(i, j), true)
	#queue_redraw() # Fordert ein Neuzeichnen des Grids an, um Änderungen sichtbar zu machen.
	#update_all_enemies_path() # Aktualisiert die Pfade aller Gegner basierend auf den neuen Grid-Daten.
#
#func find_path() -> void:
	### Berechnet den optimalen Pfad von der Start- zur Zielzelle unter Verwendung des AStar-Grids.
	#path.clear() # Löscht den aktuellen Pfad.
	#start_cell = game_map.local_to_map(start.position) # Konvertiert die Startposition in Grid-Koordinaten.
	#end_cell = game_map.local_to_map(goal.position) # Konvertiert die Zielposition in Grid-Koordinaten.
	## Überprüft, ob ein gültiger Pfad existieren kann.
	#if start_cell == end_cell or !astar_grid.is_in_boundsv(start_cell) or !astar_grid.is_in_boundsv(end_cell):
		#return # Beendet die Funktion frühzeitig, wenn kein Pfad gefunden werden kann.
	#var id_path = astar_grid.get_id_path(start_cell, end_cell) # Erhält den Pfad als Liste von Punkt-IDs.
	#var path_positions = []
	#for id in id_path:
		#path_positions.append(astar_grid.get_point_position(id))
		#emit_signal("path_updated", path_positions)
		## Zeichnet den Pfad auf der TileMap für visuelle Darstellung.
		#path.set_cell(0, id, 4, Vector2(0, 0))
	#queue_redraw() # Fordert ein Neuzeichnen des Pfads an.
#
## Fügt Gegner basierend auf dem gefundenen Pfad hinzu und aktualisiert ihre Pfade.
## Diese Funktion wird aufgerufen, nachdem ein optimaler Pfad gefunden wurde.
## 	add_enemy_to_path(id_path)
	#update_all_enemies_path()
#
#func add_enemy_to_path(id_path: Array) -> void:
	### Erstellt und platziert Gegner-Instanzen entlang des Pfads.
	## Instanziert einen Gegner aus der vorab geladenen Szene.
	#var enemy_instance = enemy_scene.instantiate()
	#var path_positions = []
	## Erstellt eine Liste von Pfadpositionen basierend auf den Punkt-IDs im Pfad.
	#for id in id_path:
		#path_positions.append(astar_grid.get_point_position(id))
	#enemy_instance.set_path(path_positions) # Setzt den Pfad für den Gegner.
	## Verbindet das Signal 'enemy_removed' des Gegners mit der Funktion '_on_enemy_removed' in diesem Skript.
	#enemy_instance.connect("enemy_removed", Callable(self, "_on_enemy_removed"))
	#add_child(enemy_instance) # Fügt den Gegner der Szene hinzu.
	#enemies.append(enemy_instance) # Fügt den Gegner dem Array hinzu.
#
#func update_all_enemies_path() -> void:
	### Aktualisiert die Pfade aller Gegner basierend auf dem aktuellen Pfad.
	#var id_path = astar_grid.get_id_path(start_cell, end_cell) # Erhält den aktuellen Pfad.
	#var path_positions = []
	#for id in id_path:
		#path_positions.append(astar_grid.get_point_position(id)) # Erstellt eine Liste von Pfadpositionen.
	## Erstellt eine Kopie der Gegner-Instanzen, um sie zu durchlaufen.
	#var valid_enemies = enemies.duplicate()
	#for enemy in valid_enemies:
		#if not is_instance_valid(enemy): # Überprüft, ob der Gegner noch gültig ist.
			#enemies.erase(enemy) # Entfernt ungültige Gegner aus dem Array.
		#else:
			#enemy.set_path(path_positions) # Aktualisiert den Pfad des Gegners.
#
## Zeichnet das Grid zur Visualisierung von blockierten und nicht-blockierten Feldern.
## Diese Funktion wird automatisch von Godot aufgerufen, um das Grid zu zeichnen.
#func _draw() -> void:
	## Durchläuft das Grid und zeichnet jedes Feld entsprechend seinem Status.
	#for i in range(astar_grid.size.x):
		#for j in range(astar_grid.size.y):
			#var id = Vector2i(i, j)
			#var position = astar_grid.get_point_position(id)
			#var size = astar_grid.cell_size
			#var rect = Rect2(position, size)
			#
			#if astar_grid.is_point_solid(id):
				## Blockierte Felder werden in Rot gezeichnet.
				#draw_rect(rect, Color.RED, false)
			#else:
				## Überprüft, ob das Feld an ein blockiertes Feld grenzt.
				#var is_adjacent_to_solid = false
				#for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
					#var neighbor_id = id + offset
					#if astar_grid.is_in_boundsv(neighbor_id) and astar_grid.is_point_solid(neighbor_id):
						#is_adjacent_to_solid = true
						#break
				#
				#if is_adjacent_to_solid:
					## Felder, die an blockierte Felder grenzen, werden in Orange gezeichnet.
					#draw_rect(rect, Color.ORANGE, false)
				#else:
					## Nicht-blockierte Felder werden in Grün gezeichnet.
					#draw_rect(rect, Color.GREEN, false)
#
## Entfernt einen Gegner aus dem Array der Gegner, wenn dieser entfernt wird.
## Diese Funktion wird aufgerufen, wenn das Signal 'enemy_removed' von einem Gegner emittiert wird.
#func _on_enemy_removed(enemy: Node) -> void:
	#if enemy in enemies:
		#enemies.erase(enemy) # Entfernt den Gegner aus dem Array der Gegner.
#
#
#
#func _on_ui_options_updated(heuristic, diagonal, jump):
	#pass # Replace with function body.
