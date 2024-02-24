extends Node2D

@onready var gridSelector = get_node("GridSelector")
@onready var tileMap = get_node("NavigationRegion2D/TileMap")
@onready var towers = get_node("Towers")

var currentTower = preload("res://towers/basic/BasicTowerScene.tscn")

func _on_player_build_tower():
	var cellLocalCoordinates = tileMap.local_to_map(gridSelector.global_position)
	var tile: TileData = tileMap.get_cell_tile_data(0, cellLocalCoordinates)
	
	if tile == null or currentTower == null:
		return
	
	if tile.get_custom_data("towers"):
		var tower = currentTower.instantiate()
		towers.add_child(tower)
		tower.global_position = gridSelector.global_position
