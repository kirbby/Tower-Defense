extends CharacterBody2D
class_name BasicEnemySceneAstar

# Signal, das ausgelöst wird, wenn der Gegner entfernt wurde.
signal enemy_removed
# Geschwindigkeit, mit der sich der Charakter bewegen soll.
@export var speed = 50
@export var health := 100

# Pfad, den der Gegner folgen wird (Liste von Vector2-Positionen).
var path = []
# Aktueller Index im Pfad.
var path_index = 0
# Gesamtfortschritt in Prozent.
var progress = 0.0

# Initialisiere Referenzen für den AnimatedSprite.
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	# Setze die Startposition auf den ersten Punkt im Pfad, wenn vorhanden.
	if path.size() > 0:
		global_position = path[0]

func _physics_process(delta):
	# Beende die Methode, wenn der Pfad abgeschlossen ist.
	if path_index >= path.size():
		return

	# Berechne die Bewegungsrichtung zum nächsten Punkt im Pfad.
	var target_position = path[path_index]
	var direction = (target_position - global_position).normalized()

	# Bewege den Charakter in Richtung des nächsten Punkts im Pfad.
	global_position += direction * speed * delta

	# Aktualisiere den Fortschritt entlang des Pfades.
	update_progress(direction * speed * delta)

	# Überprüfe, ob der nächste Punkt des Pfades erreicht wurde.
	if global_position.distance_to(target_position) < speed * delta:
		path_index += 1
		# Entferne den Gegner, wenn das Ziel erreicht ist.
		if path_index >= path.size():
			remove_enemy()

	# Aktualisiere die Animation basierend auf der Bewegungsrichtung.
	update_animation(direction)

func update_animation(direction: Vector2):
	# Aktualisiere die Animation basierend auf der Bewegungsrichtung.
	if animated_sprite == null:
		return

	if direction.length() > 0:
		direction = direction.normalized()
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				animated_sprite.play("walk_east")
			else:
				animated_sprite.play("walk_west")
		else:
			if direction.y > 0:
				animated_sprite.play("walk_south")
			else:
				animated_sprite.play("walk_north")

func update_progress(movement: Vector2):
	# Aktualisiere den Gesamtfortschritt basierend auf der Bewegung.
	progress += movement.length()

func set_path(new_path: Array):
	# Setze den neuen Pfad und aktualisiere die Animation.
	path = new_path
	path_index = find_nearest_path_index()
	progress = 0.0
	if path.size() > 0 and path_index < path.size() - 1:
		update_animation(path[path_index + 1] - path[path_index])
	else:
		update_animation(Vector2.ZERO)

func find_nearest_path_index() -> int:
	# Finde den Index des nächsten Punkts im Pfad zur aktuellen Position des Gegners.
	var nearest_index = 0
	var min_distance = 1e10
	for i in range(path.size()):
		var distance = global_position.distance_to(path[i])
		if distance < min_distance:
			min_distance = distance
			nearest_index = i
	return nearest_index

func remove_enemy() -> void:
	# Löst das Signal aus und zerstört das Gegner-Objekt.
	emit_signal("enemy_removed", self)
	queue_free()
