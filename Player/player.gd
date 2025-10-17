extends CharacterBody2D

# --- On Ready's ---
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var note_synth : AudioStreamPlayer2D = $NoteSynth

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

# --- Dash Variables ---
var dash_timer : float = 0.0
var dash_cooldown_timer : float = 0.0
var is_dashing : bool = false

# --- Notes & Octaves ---
var notes : Array = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
var current_note_index : int = 0
var current_tonic_index : int = 0
var min_octave : int = 2
var max_octave : int = 6
var current_octave : int = 4
var active_notes : Array = [] # store pressed notes

# --- BPM Variables ---
const BPM : float = 120.0
const BEAT_INTERVAL : float = 60.0 / BPM
var beat_timer : float = 0.0
var beat_window : float = 0.15 # margin of error
var on_beat : bool = false

func _ready() -> void:
	if note_synth.stream == null:
		var generator : AudioStreamGenerator = AudioStreamGenerator.new()
		generator.mix_rate = 44100
		note_synth.stream = generator
	note_synth.play()

func _process(delta: float) -> void:
	beat_timer += delta
	if beat_timer >= BEAT_INTERVAL:
		beat_timer = 0.0
		on_beat = true
		await get_tree().create_timer(beat_window).timeout
		on_beat = false

func _input(event: InputEvent) -> void:
	handle_notes_and_octaves()

func _physics_process(delta: float) -> void:
	var state = playback.get_current_node()
	
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
	
	match state:
		"MoveState":
			handle_movement(delta)
			handle_attack_inputs()
		"AttackState":
			handle_attack_inputs()
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

func handle_attack_inputs() -> void:
	# tonic
	if Input.is_action_just_pressed("tonic_attack"):
		active_notes.append("tonic")
		print("Active Notes : ", active_notes)
		play_note_by_name(notes[current_note_index], current_octave)
		print(notes[current_note_index], current_octave)
	# major third from tonic
	if Input.is_action_just_pressed("median_major_attack"):
		active_notes.append("major")
		print("Active Notes : ", active_notes)
		var info : Dictionary = get_interval_note(current_note_index, 4, current_octave)
		play_note_by_name(info["name"], info["octave"])
		print(info["name"], info["octave"])
	# minor third from tonic
	if Input.is_action_just_pressed("median_minor_attack"):
		active_notes.append("minor")
		print("Active Notes : ", active_notes)
		var info : Dictionary = get_interval_note(current_note_index, 3, current_octave)
		play_note_by_name(info["name"], info["octave"])
		print(info["name"], info["octave"])
	# dominant fifth from tonic
	if Input.is_action_just_pressed("dominant_attack"):
		active_notes.append("dominant")
		var info : Dictionary = get_interval_note(current_note_index, 7, current_octave)
		play_note_by_name(info["name"], info["octave"])
		print(info["name"], info["octave"])
	#if on_beat:
		#print("Perfect Timing! Bonus Damage!")
		# need to increase damage, combo meter, visual flash, ...
	#else:
		#print("Off-Beat. Reduced Efficiency")
	
	# combo detection
	if "tonic" in active_notes and "dominant" in active_notes:
		if "major" in active_notes:
			trigger_combo("major_chord")
		if "minor" in active_notes:
			trigger_combo("minor_chord")
	
	# reset after a delay
	if active_notes.size() > 0:
		await get_tree().create_timer(0.75).timeout
		active_notes.clear()

func get_interval_note(tonic_index : int, semitone_offset : int, tonic_octave : int) -> Dictionary:
	var total : int = tonic_index + semitone_offset
	var wrapped_index : int = total % notes.size()
	var octave_shift : int = int(floor(float(total) / 12.0))
	return {"name": notes[wrapped_index], "octave": tonic_octave + octave_shift, "index": wrapped_index}

func trigger_combo(type : String) -> void:
	match type:
		"major_chord":
			#playback.travel("MajorChord")
			print("Major Combo!")
		"minor_chord":
			#playback.travel("MinorChord")
			print("Minor Combo!")

func handle_notes_and_octaves() -> void:
	if Input.is_action_just_pressed("next_note"):
		current_note_index = (current_note_index + 1) % notes.size()
		if notes[current_note_index].length() == 2:
			current_note_index = (current_note_index + 1) % notes.size()
		current_tonic_index = current_note_index
		print("Note : ", notes[current_note_index], current_octave)
	if Input.is_action_just_pressed("previous_note"):
		current_note_index = (current_note_index - 1 + notes.size()) % notes.size()
		if notes[current_note_index].length() == 2:
			current_note_index = (current_note_index - 1 + notes.size()) % notes.size()
		current_tonic_index = current_note_index
		print("Note : ", notes[current_note_index], current_octave)
	if Input.is_action_just_pressed("next_octave") and current_octave < max_octave:
		current_octave += 1
		print("Octave : ", current_octave)
	if Input.is_action_just_pressed("previous_octave") and current_octave > min_octave:
		current_octave -= 1
		print("Octave : ", current_octave)

func note_to_frequency(note_name : String, octave : int) -> float:
	var note_index : int = notes.find(note_name)
	if note_index == -1:
		return 440.0
	var a4_index : int = notes.find("A4") + 4 * 12
	var current_index : int = note_index + octave * 12
	var n : int = current_index - a4_index
	return 440.0 * pow(2.0, n /12.0)

func play_note_by_name(note_name : String, octave : int, duration : float = 0.7) -> void:
	var frequency : float = note_to_frequency(note_name, octave)
	var amplitude : float = 0.35
	
	# create a temporary AudioStreamPlayer2D
	var temp_player : AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	var generator : AudioStreamGenerator = AudioStreamGenerator.new()
	generator.mix_rate = 44100.0
	temp_player.stream = generator
	
	add_child(temp_player)
	temp_player.play()
	
	# create playback
	var playback : AudioStreamGeneratorPlayback = temp_player.get_stream_playback()
	if playback == null:
		push_warning("Playback is not ready for note %s !!!" % note_name)
	
	# generate waveform buffer
	var sample_rate : float = generator.mix_rate
	var samples : int = int(duration * sample_rate)
	var buffer : PackedVector2Array = PackedVector2Array()
	
	for i in range(samples):
		var t = float(i) / sample_rate
		# harmonic mix so lower notes are fuller
		var s : float
		s = 0.7 * sin(2.0 * PI * frequency * t)
		s += 0.2 * sin(2.0 * PI * 2.0 * frequency * t)
		# envelope
		var envelope : float = lerp(1.0, 0.0, t / duration)
		var sample = s * amplitude * 4 / octave * envelope
		
		buffer.append(Vector2(sample, sample))
	playback.push_buffer(buffer)
	
	# clean the temporary player
	await get_tree().create_timer(duration + 0.05).timeout
	temp_player.queue_free()

func update_blend_positions(direction_vector : Vector2) -> void:
	animation_tree.set("parameters/StateMachine/MoveState/RunState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/MoveState/MoveState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/AttackState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/DashState/blend_position", direction_vector)
