extends CharacterBody2D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback

@export var move_speed : float = 100.0

var input_vector : Vector2 = Vector2.ZERO
var dash_timer : float = 0.0

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	
	var state = playback.get_current_node()
	
	if state == "MoveState":
		input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		
		if input_vector != Vector2.ZERO:
			var direction_vector : Vector2 = Vector2(input_vector.x, -input_vector.y)
			update_blend_positions(direction_vector)
		
		if Input.is_action_just_pressed("move_right"):
			dash_timer += delta
			if dash_timer >= 0.6:
				dash_timer = 0.0
			if (dash_timer < 0.6 and Input.is_action_just_pressed("move_right")):
				var is_dashing : float = 0.5
				if is_dashing > 0.0:
					velocity = input_vector * move_speed * 20
					is_dashing -= delta
		
		if Input.is_action_just_pressed("tonic_attack"):
			playback.travel("AttackState")
		
		velocity = input_vector * move_speed
		move_and_slide()
	elif state == "AttackState":
		pass

func update_blend_positions(direction_vector : Vector2) -> void:
	animation_tree.set("parameters/StateMachine/MoveState/RunState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/MoveState/MoveState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/AttackState/blend_position", direction_vector)
