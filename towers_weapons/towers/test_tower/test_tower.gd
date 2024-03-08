extends Node2D

const MissileScene := preload("res://towers_weapons/weapons/homing_missile/homing_missile.tscn")

@onready var _shoot_position := $ShootPosition

func _physics_process(_delta: float) -> void:
	look_at(get_global_mouse_position())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("LeftClick"):
		shoot()


func shoot() -> void:
	var missile := MissileScene.instantiate() as Missile

	if _shoot_position:
		missile.global_position = _shoot_position.global_position

	missile.rotation = rotation
	add_child(missile)
