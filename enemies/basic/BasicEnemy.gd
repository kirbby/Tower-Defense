extends CharacterBody2D

@export var Target: Node2D
@export var speed = 40

@onready var navigation_agent := $Navigation/NavigationAgent2D as NavigationAgent2D

# Initialisiere Referenzen für den AnimatedSprite und AnimationPlayer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	var direction = to_local(navigation_agent.get_next_path_position()).normalized()
	velocity = direction * speed
	move_and_slide()
	update_animation(direction) # Aktualisiere die Animation basierend auf der Bewegungsrichtung

func makepath() -> void:
	navigation_agent.target_position = Target.global_position

func _on_timer_timeout():
	makepath()

func update_animation(movement_direction: Vector2):
	if movement_direction.length() > 0:
		# Prüfe die Richtung und spiele die entsprechende Animation
		if abs(movement_direction.x) > abs(movement_direction.y):
			if movement_direction.x > 0:
				animated_sprite.play("walk_east")
			else:
				animated_sprite.play("walk_west")
		else:
			if movement_direction.y > 0:
				animated_sprite.play("walk_south")
			else:
				animated_sprite.play("walk_north")
	else:
		# Optional: Spiele eine Idle-Animation, wenn keine Bewegung vorliegt
		animated_sprite.play("idle")
