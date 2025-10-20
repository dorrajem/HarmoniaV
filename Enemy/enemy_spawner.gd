extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_radius: float = 400.0
@export var initial_count: int = 5
@export var boss_spawn_interval: float = 60.0 # seconds
@export var boss_scene_path: String = "res://scenes/Boss.tscn" # change path as needed

var boss_scene: PackedScene
var player: Node2D
var time_since_boss: float = 0.0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	if not player:
		push_warning("No player found in group 'Player'!")

	# Load boss scene dynamically
	if ResourceLoader.exists(boss_scene_path):
		boss_scene = load(boss_scene_path)
	else:
		push_error("Boss scene not found at %s" % boss_scene_path)

	spawn_initial_enemies()
	set_process(true)

func _process(delta: float) -> void:
	time_since_boss += delta

	if time_since_boss >= boss_spawn_interval:
		time_since_boss = 0.0
		spawn_boss()

func spawn_initial_enemies() -> void:
	for i in range(initial_count):
		spawn_enemy()

func spawn_enemy() -> void:
	if not enemy_scene or not player:
		return
	var enemy = enemy_scene.instantiate()
	var pos = get_random_position_around_player()
	enemy.global_position = pos
	add_child(enemy)

func spawn_boss() -> void:
	if not boss_scene or not player:
		return
	print("⚠️ Boss is spawning dynamically! ⚠️")

	var boss = boss_scene.instantiate()
	boss.global_position = get_random_position_around_player(spawn_radius * 0.8)
	add_child(boss)

func get_random_position_around_player(radius: float = spawn_radius) -> Vector2:
	var random_angle = randf() * TAU
	var random_distance = randf_range(100.0, radius)
	var offset = Vector2(cos(random_angle), sin(random_angle)) * random_distance
	return player.global_position + offset
