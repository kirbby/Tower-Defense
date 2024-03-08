extends Area2D

@export var health := 500:
	set = set_health
@onready var collision_shape := $end_zone_CollisionShape as CollisionShape2D
@onready var Sprite := $end_zone_AtlasTexture as Sprite2D

signal position_updated
var is_dragging := false
var is_mouse_over := false

func set_health(value: int) -> void:
	health = max(0, value)
	if health == 0:
		collision_shape.set_deferred("disalbed",true)
		
		


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect('mouse_entered', _on_mouse_entered)
	connect('mouse_exited', _on_mouse_exited)
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MASK_LEFT:
		is_dragging = event.pressed and is_mouse_over
		if is_dragging:
			get_viewport().set_input_as_handled()
		return
	
	if event is InputEventMouseMotion and is_dragging:
		global_position = get_global_mouse_position()
		emit_signal('position_updated')

func _on_mouse_entered() -> void:
	is_mouse_over = true

func _on_mouse_exited() -> void:
	is_mouse_over = false
