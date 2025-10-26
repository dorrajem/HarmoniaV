extends CharacterBody2D
class_name Enemy

@onready var hp_bar: ProgressBar = $HPBar

@export var patrol_point_count: int = 4               # how many random patrol points
@export var patrol_radius: float = 250.0              # how far from spawn point
@export var patrol_speed: float = 50.0
@export var chase_speed: float = 100.0
@export var detection_radius: float = 100.0

@onready var guitar: AnimatedSprite2D = $Guitar
@onready var drum: AnimatedSprite2D = $Drum

signal enemy_died

var _current_point := 0
var _patrol_points: Array[Vector2] = []
var _player: Node2D = null
var _is_chasing := false

var health : float = 50.0


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("Player")
	enemy_died.connect(_player.gain_exp)
	hp_bar.value = health
	hp_bar.max_value = health
	var x = randi_range(0, 1)
	match x:
		0:
			guitar.visible = true
		1:
			drum.visible = true

	_generate_patrol_points()


func _physics_process(delta: float) -> void:
	if _is_chasing and _player:
		_chase_player(delta)
	else:
		_patrol(delta)

	_check_player_detection()


func _generate_patrol_points() -> void:
	_patrol_points.clear()
	for i in range(patrol_point_count):
		var random_offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * randf_range(0, patrol_radius)
		var point = global_position + random_offset
		_patrol_points.append(point)

	print("%s generated patrol points: %s" % [name, _patrol_points])


func _patrol(delta: float) -> void:
	if _patrol_points.is_empty():
		return

	var target := _patrol_points[_current_point]
	var direction := (target - global_position).normalized()
	velocity = direction.normalized() * patrol_speed
	move_and_slide()

	if global_position.distance_to(target) < 5.0:
		_current_point = (_current_point + 1) % _patrol_points.size()
	
	_check_player_detection()


func _chase_player(delta: float) -> void:
	if not _player:
		return
	var direction := (_player.global_position - global_position).normalized()
	velocity = direction.normalized() * chase_speed
	move_and_slide()

	if global_position.distance_to(_player.global_position) > detection_radius * 1.5:
		_is_chasing = false


func _check_player_detection() -> void:
	if not _player:
		return
	var dist := global_position.distance_to(_player.global_position)
	if dist < detection_radius:
		var space_state = get_world_2d().direct_space_state
		var query := PhysicsRayQueryParameters2D.create(global_position, _player.global_position)
		query.exclude = [self]
		var result := space_state.intersect_ray(query)

		if result.is_empty() or result["collider"] == _player:
			_is_chasing = true
		else:
			_is_chasing = false
	else:
		_is_chasing = false

func apply_knockback(from_position : Vector2, strength : float = 2000.0) -> void:
	var direction : Vector2 = (global_position - from_position).normalized()
	velocity = direction * strength
	move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount
	hp_bar.value = clamp(health, 0.0, 100.0)
	print("%s took %d damage, remaining health: %d" % [name, amount, health])
	apply_knockback(_player.global_position, 1000.0)
	velocity *= 0
	await get_tree().create_timer(0.25).timeout
	velocity *= 1
	if health <= 0:
		die()

func die() -> void:
	print("%s has died!" % name)
	enemy_died.emit()
	queue_free()
