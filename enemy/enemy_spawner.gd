extends Node2D

@onready var spawn_timer: Timer = $SpawnTimer
@onready var boss_spawn_timer: Timer = $BossSpawnTimer

@export_group("Packed Scenes")
@export var player : CharacterBody2D
@export var enemy_scene: PackedScene
@export var boss_scene: PackedScene
@export_group("Spawner Variables")
@export var spawn_radius: float = 560.0
@export var initial_spawn_count: int = 3
@export_range(10.0, 120.0, 1.0, "or_greater", "suffix: s") var boss_spawn_interval: float = 60.0 # seconds
@export_range(0.5, 60.0, 0.5, "or_greater", "suffix: s") var spawn_interval: float = 8.0 # seconds

var total_enemies_spawned : int = 0

func _ready() -> void:
	ready_timers()
	spawn_initial_enemies()
	set_process(true)

func _process(delta: float) -> void:
	pass
	#if time_since_boss >= boss_spawn_interval:
		#time_since_boss = 0.0
		#spawn_boss()

func ready_timers() -> void:
	spawn_timer.wait_time = spawn_interval
	boss_spawn_timer.wait_time = boss_spawn_interval
	spawn_timer.autostart = true
	boss_spawn_timer.autostart = true

func spawn_initial_enemies() -> void:
	for i in range(initial_spawn_count):
		spawn_enemy()

func spawn_enemy() -> void:
	if not enemy_scene or not player:
		return
	var enemy = enemy_scene.instantiate()
	var spawn_position = get_random_position_around_player()
	enemy.global_position = spawn_position
	add_child(enemy)
	total_enemies_spawned += 1

func get_random_position_around_player(radius: float = spawn_radius) -> Vector2:
	var random_angle = randf() * TAU
	var random_distance = randf_range(radius - 50.0 , radius + 100.0)
	var offset = Vector2.ONE.from_angle(random_angle) * random_distance
	return player.global_position + offset

func spawn_boss() -> void:
	if not boss_scene or not player:
		return
	print("⚠️ Boss is spawning dynamically! ⚠️")

	var boss = boss_scene.instantiate()
	boss.global_position = get_random_position_around_player(spawn_radius * 0.5)
	add_child(boss)


func _on_spawn_timer_timeout() -> void:
	spawn_enemy()
	spawn_timer.wait_time = max(min(spawn_interval / (player.level * total_enemies_spawned / player.level * 0.1), spawn_interval), 0.5)
	print("Spawn Timer Changed To : ", spawn_timer.wait_time)

func _on_boss_spawn_timer_timeout() -> void:
	spawn_boss()
	pass
