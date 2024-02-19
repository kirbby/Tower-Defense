extends CharacterBody2D

# Geschwindigkeit, mit der sich der Charakter bewegen soll
@export var Player:CharacterBody2D
@export var path_to_player := NodePath()
var speed = 400
var acceleration = 7


@onready var navigation_agent: NavigationAgent2D = $Navigation/NavigationAgent2D


# Initialisiere Referenzen für den AnimatedSprite und AnimationPlayer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta):
	var direction = Vector2.ZERO
	
	direction = navigation_agent.get_next_path_position() - global_position
	direction = direction.normalized()
	
	velocity = velocity.lerp(direction * speed, acceleration + delta)
	move_and_slide()



func _on_timer_timeout():
	navigation_agent.target_position = Player.global_position














