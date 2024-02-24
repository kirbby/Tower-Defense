extends StaticBody2D

var bullet = preload("res://towers/basic/bullet.tscn")
@export var bulletDamage = 5
var pathName
var possibleTargets = []
var currentTarget

func _physics_process(delta):
	turn()
	
func turn():
	if currentTarget != null:
		look_at(currentTarget.position)


func _on_range_area_body_entered(body):
	if "BasicEnemyScene" in body.name:
		var tempTargets = []
		possibleTargets = get_node("RangeArea").get_overlapping_bodies()
		
		for target in possibleTargets:
			if "Enemy" in target.name:
				tempTargets.append(target)
		
		for target in tempTargets:
			if currentTarget == null:
				currentTarget = target
			#else:
				#if target.get_parent().get_progress() > currentTarget.get_progress():
					#currentTarget = target.get_node("../")
	


func _on_range_area_body_shape_exited(body_rid, body, body_shape_index, local_shape_index):
	if body == currentTarget:
		currentTarget = null
