extends StaticBody2D

var missile_scene = preload("res://towers_weapons/weapons/homing_missile/homing_missile.tscn")
@export var bullet_damage = 5
@export var fire_rate = 1.0 # Schussrate in Schüssen pro Sekunde
var possible_targets = []
var current_target = null
var time_since_last_shot = 0.0
@onready var _shoot_position = $ShootPosition


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
		var missile = missile_scene.instantiate() as Missile
		missile.global_position = _shoot_position.global_position
		missile.look_at(current_target.global_position)
		missile.set_target(current_target)
		add_child(missile)
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
