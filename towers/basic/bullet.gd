extends CharacterBody2D

class_name bullet_scene


# Geschwindigkeit, mit der sich das Geschoss bewegt.
var speed: float = 400.0
# Schaden, den das Geschoss beim Treffen eines Ziels verursacht.
var damage: int = 50

func _ready():
	# Richtet das Geschoss in Bewegungsrichtung aus.
	look_at(get_global_mouse_position())

	# Stelle sicher, dass das Geschoss nach einer gewissen Zeit automatisch gelöscht wird, falls es kein Ziel trifft.
	queue_free_after(5) # Löscht das Geschoss nach 5 Sekunden.

func _physics_process(delta: float) -> void:
	# Bewegt das Geschoss in die Richtung, in die es zeigt.
	var velocity: Vector2 = transform.x * speed
	move_and_slide()

func queue_free_after(seconds: float) -> void:
	# Verzögert das Löschen des Geschosses.
	await get_tree().create_timer(seconds).timeout
	queue_free()

func _on_Geschoss_body_entered(body: Node) -> void:
	# Diese Funktion wird aufgerufen, wenn das Geschoss ein anderes Objekt trifft.
	if body.has_method("apply_damage"):
		# Ruft die 'apply_damage'-Methode des getroffenen Objekts auf, falls vorhanden, und übergibt den Schaden.
		body.apply_damage(damage)
	# Löscht das Geschoss nach der Kollision.
	queue_free()
