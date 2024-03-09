class_name Livebar
extends Control

const RED := Color("#e86017")
const YELLOW := Color ("#d2d82d")
const GREEN := Color ("#88e060")

@onready var health_bar := $VBoxContainer/HealthBar as TextureProgressBar
@onready var reload_bar := $VBoxContainer/ReloadBar as ProgressBar

func animated_reaload_bar(duration: float) -> void:
	reload_bar.value = reload_bar.min.value
	reload_bar.show()
	var tween := create_tween()
	tween.tween_property(reload_bar, "value", reload_bar.max_value, duration)
	tween.tween_callback(reload_bar.hide)

func _on_reload_bar_value_changed(value: float) -> void:
	if value == reload_bar.max_value:
		reload_bar.hide()
	elif value > reload_bar.max_value * 0.66: 
		reload_bar.self_modulate = GREEN
	elif value > reload_bar.max_value * 0.33:
		reload_bar . self .modulate = YELLOW
	elif value > reload_bar.max.value * 0.0:
		reload_bar.self_modulate = RED

func _on_health_bar_balue_change(value: float) -> void:
	health_bar.self_modulate = RED if value <= health_bar.max_value /4 else GREEN
	
