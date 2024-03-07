# Missile.gd
class_name Missile
extends Node2D

# Konstanten und Variablen
const LAUNCH_SPEED := 0.1
@export var lifetime := 20.0
var max_speed := 100.0
var drag_factor := 0.15
var _target: Node = null # Ziel, das die Rakete verfolgen wird
var _current_velocity := Vector2.ZERO

# Node-Referenzen
@onready var _sprite := $Sprite
@onready var _hitbox := $HitBox
@onready var _enemy_detector := $EnemyDetector
@onready var _aim_line := $AimLine
@onready var _target_line := $TargetLine
@onready var _change_line := $ChangeLine

func _ready():
	_aim_line.add_point(Vector2.ZERO)
	_aim_line.add_point(Vector2.ZERO)
	_target_line.add_point(Vector2.ZERO)
	_target_line.add_point(Vector2.ZERO)
	_change_line.add_point(Vector2.ZERO)
	_change_line.add_point(Vector2.ZERO)
	set_as_top_level(true)
	_aim_line.set_as_top_level(true)
	_target_line.set_as_top_level(true)
	_change_line.set_as_top_level(true)
	
	# Verbindungen für Kollisionserkennung und Zielverfolgung
	_hitbox.connect("body_entered", Callable(self, "_on_HitBox_body_entered"))
	_enemy_detector.connect("body_entered", Callable(self, "_on_EnemyDetector_body_entered"))

	# Lebensdauer-Timer
	var timer := get_tree().create_timer(lifetime)
	timer.connect("timeout", Callable(self, "queue_free"))
	
	# Initialgeschwindigkeit
	_current_velocity = LAUNCH_SPEED * Vector2.RIGHT.rotated(rotation)

func _physics_process(delta: float) -> void:
	if _target and is_instance_valid(_target):
		var direction = global_position.direction_to(_target.global_position)
		var desired_velocity = direction * max_speed
		var change = (desired_velocity - _current_velocity) * drag_factor
		_current_velocity += change
	else:
		_current_velocity = _current_velocity.normalized() * max_speed
	
	position += _current_velocity * delta
	rotation = _current_velocity.angle()

	# Aktualisierung der visuellen Hilfslinien
	update_lines()

func update_lines() -> void:
	_aim_line.set_point_position(0, global_position)
	_aim_line.set_point_position(1, global_position + _current_velocity.normalized() * 150)
	if _target and is_instance_valid(_target):
		var direction = global_position.direction_to(_target.global_position)
		_target_line.set_point_position(0, global_position)
		_target_line.set_point_position(1, global_position + direction * 150)
	_change_line.set_point_position(0, global_position)
	_change_line.set_point_position(1, global_position + _current_velocity.normalized() * 150)

func set_target(target: Node) -> void:
	_target = target

func _on_HitBox_body_entered(_body: Node) -> void:
	queue_free()

func _on_EnemyDetector_body_entered(enemy: Node):
	if _target == null:
		_target = enemy
