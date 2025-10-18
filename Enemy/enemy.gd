extends CharacterBody2D
class_name Enemy

@export var patrol_points: Array[Vector2] = [] # Set in the editor
@export var patrol_speed: float = 50.0
@export var chase_speed: float = 100.0
@export var detection_radius: float = 100.0

var _current_point := 0
var _player: Node2D = null
var _is_chasing := false

func _ready() -> void:
	# Find the player automatically
	_player = get_tree().get_first_node_in_group("Player")
	if patrol_points.is_empty():
		push_warning("No patrol points set for %s!" % name)

func _physics_process(delta: float) -> void:
	if _is_chasing and _player:
		_chase_player(delta)
	else:
		_patrol(delta)

	_check_player_detection()

func _patrol(delta: float) -> void:
	if patrol_points.is_empty():
		return

	var target := patrol_points[_current_point]
	var direction := (target - global_position).normalized()
	velocity = direction * patrol_speed
	move_and_slide()

	# When close to target, switch to next point
	if global_position.distance_to(target) < 5.0:
		_current_point = (_current_point + 1) % patrol_points.size()

func _chase_player(delta: float) -> void:
	if not _player:
		return

	var direction := (_player.global_position - global_position).normalized()
	velocity = direction * chase_speed
	move_and_slide()

	# Lose interest if player goes far away
	if global_position.distance_to(_player.global_position) > detection_radius * 1.5:
		_is_chasing = false

func _check_player_detection() -> void:
	if not _player:
		return

	var dist := global_position.distance_to(_player.global_position)
	if dist < detection_radius:
		var space_state = get_world_2d().direct_space_state

		# ✅ create a proper raycast query
		var query := PhysicsRayQueryParameters2D.create(global_position, _player.global_position)
		query.exclude = [self]  # don’t detect itself

		var result := space_state.intersect_ray(query)

		# ✅ check result
		if result.is_empty() or result["collider"] == _player:
			_is_chasing = true
		else:
			_is_chasing = false
	else:
		_is_chasing = false
