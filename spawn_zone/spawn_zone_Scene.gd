extends Area2D
signal position_updated

#Spawn Settings
@export_range (0.5, 5.0, 0.5) var spawn_rate := 2.0
@export var wave_count := 3
@export var enemies_per_wave_count := 10

var spawn_locations := []
var current_wave := 0
var current_enemy_count := 0
var path_positions = []
var spawned_enemies = []

@onready var wave_timer := $WaveTimer as Timer
@onready var spawn_timer := $SpawnTimer as Timer
@onready var spawn_container := $SpawnContainer as Node2D


# Move Spawn Settings
var is_dragging := false
var is_mouse_over := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect('mouse_entered', _on_mouse_entered)
	connect('mouse_exited', _on_mouse_exited)
	for marker in spawn_container.get_children():
		spawn_locations.append(marker)
	wave_timer.start()
	
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

func _start_wave() -> void:
	current_wave += 1
	spawn_timer.start()
	current_enemy_count = 0

func _on_path_updated(path_positions):
	# Speichert die neuen Pfadpositionen
	self.path_positions = path_positions
	# Aktualisiert die Pfade aller gespawnten Gegner
	update_spawned_enemies_path()


func _spawn_new_enemy(enemy_path: String):
	var enemy: BasicEnemySceneAstar = load(enemy_path).instantiate()
	get_parent().add_child(enemy)
	var spawner_marker = spawn_locations.pick_random()
	enemy.global_position = spawner_marker.global_position
	# Hier weisen Sie dem Gegner den gespeicherten Pfad zu
	enemy.set_path(path_positions)
	current_enemy_count += 1
	spawned_enemies.append(enemy) # Fügt den Gegner der Liste hinzu


func update_spawned_enemies_path():
	for enemy in spawned_enemies: # Angenommen, `spawned_enemies` ist die Liste der gespawnten Gegner
		if is_instance_valid(enemy):
			enemy.set_path(self.path_positions)

func _end_wave():
	if current_wave < wave_count:
		wave_timer.start()
		

func _on_wave_timer_timeout() -> void:
	_start_wave()

func _on_spawn_timer_timeout():
	if current_enemy_count < enemies_per_wave_count:
		_spawn_new_enemy("res://enemies/Enemy T2/enemy_t_2.tscn")
		var spawn_delay := randf_range(spawn_rate /2.0, spawn_rate)
		spawn_timer.start(spawn_delay)
	else:
		_end_wave()
