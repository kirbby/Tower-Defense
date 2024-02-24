extends CharacterBody2D

@export var speed: float = 400.0

@onready var bullet = preload("res://character/bullet.tscn")
@onready var grid_selector = $"../GridSelector"

var direction: Vector2 = Vector2.ZERO

func _physics_process(delta):
	look_at(get_global_mouse_position())
	checkInput(delta)
	move_and_slide()
	
# Calculate the new position based on the direction the player is looking
	var direction = Vector2(1, 0).rotated(rotation)  # Get the forward vector
	var new_position = global_position + direction * 48  # Move 32 units in the forward direction

	# Snap the new position to the grid
	grid_selector.global_position = Vector2(snapped(new_position.x, 32), snapped(new_position.y, 32))
	

# Walking and Shooting Solution
func checkInput(delta):
	var inputVector = Vector2(Input.get_axis("moveLeft", "moveRight"), Input.get_axis("moveUp", "moveDown")).normalized()
	# Direkte Zuweisung der berechneten Geschwindigkeit zur velocity-Eigenschaft
	velocity = inputVector * speed
	direction = (self.global_position - get_global_mouse_position()).normalized()
	
	if Input.is_action_just_pressed("LeftClick"):
		var bulletTemp = bullet.instantiate()
		bulletTemp.velocity = -direction*800
		bulletTemp.global_position = $bullet.global_position
		get_parent().add_child(bulletTemp)

signal player_ready(player_instance)

func _ready():
	emit_signal("player_ready", self)
