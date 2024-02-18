extends CharacterBody2D

var bulletdamage = 50

func _process(delta):
	move_and_slide()

func _hit_enemy (body):
	if "CharacterBody2D" in body.name:
		body.Health -= bulletdamage
		queue_free()
