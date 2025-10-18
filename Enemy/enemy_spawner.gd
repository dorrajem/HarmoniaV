extends Node2D
class_name EnemySpawner

@export var enemy_scene: PackedScene
@export var initial_enemy_count: int = 5
@export var spawn_interval: float = 20.0       # seconds between spawns
@export var spawn_area_size: Vector2 = Vector2(1000, 800)
@export var min_distance_from_player: float = 200.0
@export var max_enemies: int = 100


var _player: Node2D = null
var _wave_count: int = 0
var _timer: Timer


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("Player")
	if not enemy_scene:
		push_error("EnemySpawner: enemy_scene not assigned!")
		return

	# spawn initial enemies
	_spawn_enemies(initial_enemy_count)

	# setup timer for new waves
	_timer = Timer.new()
	_timer.wait_time = spawn_interval
	_timer.autostart = true
	_timer.one_shot = false
	add_child(_timer)
	_timer.connect("timeout", _on_spawn_wave)


func _spawn_enemies(count: int) -> void:
	if not enemy_scene:
		return

	for i in range(count):
		var enemy = enemy_scene.instantiate()
		add_child(enemy)

		# random spawn position in area
		var spawn_pos: Vector2
		var too_close := true
		while too_close:
			spawn_pos = Vector2(
				randf_range(-spawn_area_size.x/2, spawn_area_size.x/2),
				randf_range(-spawn_area_size.y/2, spawn_area_size.y/2)
			)
			too_close = _player and spawn_pos.distance_to(_player.global_position) < min_distance_from_player

		enemy.global_position = spawn_pos
		print("Spawned enemy at ", spawn_pos)



func _on_spawn_wave() -> void:
	_wave_count += 1
	var new_enemy_count = int(initial_enemy_count * pow(2, _wave_count))
	var current_enemy_count = get_child_count()
	if current_enemy_count + new_enemy_count > max_enemies:
		new_enemy_count = max_enemies - current_enemy_count
	if new_enemy_count > 0:
		_spawn_enemies(new_enemy_count)
