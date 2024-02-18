extends CharacterBody2D

# Geschwindigkeit des Spielers
var speed: float = 400.0
@onready var bullet = preload("res://character/bullet.tscn")

func _physics_process(delta):
	look_at(get_global_mouse_position())
	checkInput(delta)
	move_and_slide()

# Walking and Shooting Solution
func checkInput(delta):
	var inputVector = Vector2(Input.get_axis("moveLeft", "moveRight"), Input.get_axis("moveUp", "moveDown")).normalized()
	# Direkte Zuweisung der berechneten Geschwindigkeit zur velocity-Eigenschaft
	velocity = inputVector * speed
	var direction = (self.global_position - get_global_mouse_position()).normalized()
	
	if Input.is_action_just_pressed("LeftClick"):
		var bulletTemp = bullet.instantiate()
		bulletTemp.velocity = -direction*800
		bulletTemp.global_position = $bullet.global_position
		get_parent().add_child(bulletTemp)
