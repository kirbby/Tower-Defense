extends StaticBody2D

var bullet_scene = preload("res://towers/basic/bullet.tscn")
@export var bullet_damage = 5
@export var fire_rate = 1.0 # Schussrate in Schüssen pro Sekunde
var possible_targets = []
var current_target = null
var time_since_last_shot = 0.0

func _ready():
	# Verbindet das Signal für das Betreten des Bereichs mit der Funktion, die prüft, ob ein Gegner in Reichweite ist.
	$RangeArea.connect("body_entered", Callable(self, "_on_range_area_body_entered"))
	$RangeArea.connect("body_exited", Callable(self, "_on_range_area_body_exited"))

func _physics_process(delta):
	time_since_last_shot += delta
	turn()
	shoot()

func turn():
	if current_target != null and is_instance_valid(current_target):
		look_at(current_target.global_position)
	else:
		find_next_target()

func shoot():
	if current_target != null and time_since_last_shot >= 1.0 / fire_rate:
		var bullet_instance = bullet_scene.instantiate()
		bullet_instance.global_position = self.global_position
		bullet_instance.look_at(current_target.global_position)
		# Hier könntest du eine Funktion in deinem Bullet-Skript aufrufen, um das Ziel zu setzen oder die Richtung zu bestimmen
		add_child(bullet_instance)
		time_since_last_shot = 0.0


func find_next_target():
	current_target = null
	var max_progress = -1.0
	for target in possible_targets:
		if target is BasicEnemySceneAstar and target.progress > max_progress:
			current_target = target
			max_progress = target.progress

func _on_range_area_body_entered(body):
	if body is BasicEnemySceneAstar:
		possible_targets.append(body)
		find_next_target()

func _on_range_area_body_exited(body):
	if body in possible_targets:
		possible_targets.erase(body)
	if body == current_target:
		find_next_target()
