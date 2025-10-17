extends CharacterBody2D

# --- On Ready's ---
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback

# --- Movement Constatnts ---
const MOVE_SPEED : float = 100.0
const DASH_SPEED : float = MOVE_SPEED * 2
const DASH_DURATION : float = 0.2
const DASH_COOLDOWN : float = 0.7
const DOUBLE_TAP_TIME : float = 0.3

# --- State Variables ---
var input_vector : Vector2 = Vector2.ZERO
var last_input_vector : Vector2 = Vector2.ZERO
var last_tap_time : Dictionary = {
	"move_left" : -1.0,
	"move_right" : -1.0,
	"move_up" : -1.0,
	"move_down" : -1.0
}

var dash_timer : float = 0.0
var dash_cooldown_timer : float = 0.0
var is_dashing : bool = false

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	var state = playback.get_current_node()
	
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
	
	match state:
		"MoveState":
			handle_movement(delta)
		"AttackState":
			pass
		"DashState":
			handle_dash(delta)

func handle_movement(delta : float) -> void:
	# get movement inputs
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# change direction, blend animation & update the last input vector (facing)
	if input_vector != Vector2.ZERO:
		last_input_vector = input_vector
		var direction_vector : Vector2 = Vector2(input_vector.x, -input_vector.y)
		update_blend_positions(direction_vector)
	
	# detect double tap
	if dash_cooldown_timer <= 0.0:
		for tap_direction in last_tap_time.keys():
			if Input.is_action_just_pressed(tap_direction):
				var now = Time.get_ticks_msec() / 1000.0
				if now - last_tap_time[tap_direction] <= DOUBLE_TAP_TIME:
					print("Dash Triggered: ", tap_direction)
					start_dash()
					return
				last_tap_time[tap_direction] = now
	
	if Input.is_action_just_pressed("tonic_attack"):
		playback.travel("AttackState")
	
	velocity = input_vector * MOVE_SPEED
	move_and_slide()

func start_dash() -> void:
	is_dashing = true
	dash_timer = 0.0
	dash_cooldown_timer = DASH_COOLDOWN
	playback.travel("DashState")

func handle_dash(delta: float) -> void:
	dash_timer += delta
	velocity = last_input_vector.normalized() * DASH_SPEED
	move_and_slide()
	
	if dash_timer >= DASH_DURATION:
		is_dashing = false
		playback.travel("MoveState")

func update_blend_positions(direction_vector : Vector2) -> void:
	animation_tree.set("parameters/StateMachine/MoveState/RunState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/MoveState/MoveState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/AttackState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/DashState/blend_position", direction_vector)
