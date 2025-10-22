class_name Player extends CharacterBody2D

# --- On Ready's ---
@onready var ui: CanvasLayer = $UI
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var playback: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var beat_tick_timer: Timer = $BeatController/BeatTickTimer
@onready var beat_window_timer: Timer = $BeatController/BeatWindowTimer
@onready var hp_bar: ProgressBar = $HPBar
@onready var tonic_hitbox: Area2D = $TonicHitbox
@onready var median_hitbox: Area2D = $MedianHitbox
@onready var dominant_hitbox: Area2D = $DominantHitbox

# --- Combat Variables ---
@export var health : float = 100.0
var is_invinsible : bool = false
var has_life_steal : bool = false
var life_steal : float = 0.25
var experience : float = 0
var level : int = 1
var damage_cooldown : float = 0.5
var last_hit_time : Dictionary = {}
var base_damage : int = 3.5
var tonic_damage : float = 1
var median_damage : float = 1.5
var dominant_damage : float = 2.0
var major_damage : float = 3.0
var major_amplified : bool = false

# --- Movement Constatnts ---
const MOVE_SPEED : float = 150.0
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
var max_octave : int = 2
#var max_octave : int = 6
var current_octave : int = 2
var active_notes : Array = [] # store pressed notes

# --- Combo Variables ---
var combo_buffer : Array = [] # store last few notes pressed
var combo_timout : float = 0.5 # seconds before combo_buffer resets
var combo_timer : float = 0.0
var last_detected_combo : String = "" # to prevent repeated buttons
var combo_locked : bool = false # prevents redetection while the input is held (detect the combo only once)

# --- BPM Variables ---
const BPM : float = 60.0
const BEAT_INTERVAL : float = 60.0 / BPM
const BEAT_WINDOW : float = 0.25 # margin of error
var on_beat : bool = false

@export var debug_beats : bool = false

func _ready() -> void:
	hp_bar.value = health
	health = 100.0
	# make sure the tick and window timers are updated and start the beat tick timer
	beat_tick_timer.wait_time = BEAT_INTERVAL
	beat_window_timer.wait_time = BEAT_WINDOW
	beat_tick_timer.start()
	# connect timer signals
	beat_tick_timer.connect("timeout", _on_beat_tick)
	beat_window_timer.connect("timeout", _on_beat_window_end)
	
	ui.beat_tick_timer = self.beat_tick_timer

func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	handle_notes_and_octaves()
	if event is InputEventJoypadButton and not event.pressed:
		combo_locked = false

func _physics_process(delta: float) -> void:
	var state : String = playback.get_current_node()
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
	
	match state:
		"MoveState":
			handle_movement(delta)
			handle_attack_inputs(delta)
		"TonicState":
			handle_attack_inputs(delta)
		"MedianState":
			handle_attack_inputs(delta)
		"DominantState":
			handle_attack_inputs(delta)
		"DashState":
			handle_dash(delta)

# --- Movement Functions ---

func handle_movement(delta : float) -> void:
	# get movement inputs
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# change direction, blend animation & update the last input vector (facing)
	if input_vector != Vector2.ZERO:
		last_input_vector = input_vector
		var direction_vector : Vector2 = Vector2(input_vector.x, -input_vector.y)
		update_blend_positions(direction_vector)
		update_hitbox_positions(direction_vector)
	
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
		playback.travel("TonicState")
	if Input.is_action_just_pressed("median_major_attack") or Input.is_action_just_pressed("median_minor_attack"):
		playback.travel("MedianState")
	if Input.is_action_just_pressed("dominant_attack"):
		playback.travel("DominantState")
		
	velocity = input_vector * MOVE_SPEED
	move_and_slide()

func start_dash() -> void:
	is_dashing = true
	dash_timer = 0.0
	dash_cooldown_timer = DASH_COOLDOWN
	playback.travel("DashState")

func handle_dash(delta: float) -> void:
	dash_timer += delta
	is_invinsible = true
	velocity = last_input_vector.normalized() * DASH_SPEED
	move_and_slide()
	
	if dash_timer >= DASH_DURATION:
		is_dashing = false
		is_invinsible = false
		playback.travel("MoveState")

# --- Attack Functions ---

func handle_attack_inputs(delta : float) -> void:
	# combo
	combo_timer -= delta
	if combo_timer <= 0.0:
		combo_buffer.clear()
		last_detected_combo = ""
		combo_locked = false
		ui.reset_combo()
	
	# tonic
	if Input.is_action_just_pressed("tonic_attack"):
		play_note_by_name(notes[current_note_index], current_octave)
		register_note_input("Tonic")
		ui.add_combo()
		ui.pulse_on_hit(on_beat)
	# major third from tonic
	if Input.is_action_just_pressed("median_major_attack"):
		var info : Dictionary = get_interval_note(current_note_index, 4, current_octave)
		play_note_by_name(info["name"], info["octave"])
		register_note_input("Major")
		ui.add_combo()
		ui.pulse_on_hit(on_beat)
	# minor third from tonic
	if Input.is_action_just_pressed("median_minor_attack"):
		var info : Dictionary = get_interval_note(current_note_index, 3, current_octave)
		play_note_by_name(info["name"], info["octave"])
		register_note_input("Minor")
		ui.add_combo()
		ui.pulse_on_hit(on_beat)
	# dominant fifth from tonic
	if Input.is_action_just_pressed("dominant_attack"):
		var info : Dictionary = get_interval_note(current_note_index, 7, current_octave)
		play_note_by_name(info["name"], info["octave"])
		register_note_input("Dominant")
		ui.add_combo()
		ui.pulse_on_hit(on_beat)
	perform_attack()


# --- Music Functions ---

func get_interval_note(tonic_index : int, semitone_offset : int, tonic_octave : int) -> Dictionary:
	var total : int = tonic_index + semitone_offset
	var wrapped_index : int = total % notes.size()
	var octave_shift : int = int(floor(float(total) / 12.0))
	return {"name": notes[wrapped_index], "octave": tonic_octave + octave_shift, "index": wrapped_index}

func handle_notes_and_octaves() -> void:
	if Input.is_action_just_pressed("next_note"):
		current_note_index = (current_note_index + 1) % notes.size()
		if notes[current_note_index].length() == 2:
			current_note_index = (current_note_index + 1) % notes.size()
		current_tonic_index = current_note_index
		print("Note : ", notes[current_note_index], current_octave)
		ui.update_note_display(notes[current_note_index], current_octave)
	if Input.is_action_just_pressed("previous_note"):
		current_note_index = (current_note_index - 1 + notes.size()) % notes.size()
		if notes[current_note_index].length() == 2:
			current_note_index = (current_note_index - 1 + notes.size()) % notes.size()
		current_tonic_index = current_note_index
		print("Note : ", notes[current_note_index], current_octave)
		ui.update_note_display(notes[current_note_index], current_octave)
	if Input.is_action_just_pressed("next_octave") and current_octave < max_octave:
		current_octave += 1
		print("Octave : ", current_octave)
		ui.update_note_display(notes[current_note_index], current_octave)
	if Input.is_action_just_pressed("previous_octave") and current_octave > min_octave:
		current_octave -= 1
		print("Octave : ", current_octave)
		ui.update_note_display(notes[current_note_index], current_octave)

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
	#var amplitude : float = 0.35
	var amplitude : float = randf_range(0.3, 0.5)
	print("AMP : ", amplitude)
	
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
	await get_tree().create_timer(duration + 0.25).timeout
	temp_player.queue_free()

# --- Combo Functions ---
func register_note_input(note_type : String) -> void:
	combo_buffer.append(note_type)
	combo_timer = combo_timout
	
	# keep only the last 3 inputs (our combo size)
	#if combo_buffer.size() > 3:
		#combo_buffer.pop_front()
	check_for_combos()

func check_for_combos() -> void:
	var combo_str = ",".join(combo_buffer)
	
	# prevent repeated detections while the same combo presists
	if combo_locked and combo_str == last_detected_combo:
		return
	
	# --- Combo Detection Rules --
	if combo_buffer == ["Tonic", "Major", "Dominant"]:
		on_combo_detected("Major", on_beat)
	elif combo_buffer == ["Tonic", "Minor", "Dominant"]:
		on_combo_detected("Minor", on_beat)

func on_combo_detected(combo_type : String, on_beat : bool) -> void:
	print(combo_type, " Combo Detected! On Beat : ", on_beat)
	match combo_type:
		"Major":
			major_amplified = true
			await get_tree().create_timer(0.1).timeout
			major_amplified = false
		"Minor":
			has_life_steal = true
			print("Life Steal")
			await get_tree().create_timer(5).timeout
			has_life_steal = false
			print("No More Life Steal")
	last_detected_combo = ",".join(combo_buffer)
	combo_locked = true
	
	if on_beat:
		ui.flash(ui.combo_label, combo_type)

# --- BPM functions ---
func _on_beat_tick() -> void:
	on_beat = true
	beat_window_timer.start()
	if debug_beats:
		print("[Beat] tick at ", Time.get_ticks_msec() / 1000.0)

func _on_beat_window_end() -> void:
	on_beat = false
	if debug_beats:
		print("[Beat] window end at ", Time.get_ticks_msec() / 1000.0)

# --- Combat Functions ---

func take_damage(amount : float) -> void:
	if (health - amount) <= 0.0:
		health = max(0.0, health - amount)
		handle_death()
		return
	health -= amount
	hp_bar.value = clamp(health, 0.0, 100.0)
	print("Player hit, HP remaining : ", health)
	
	create_tween().tween_property(self, "modulate", Color(1, 0.5, 0.5), 0.25).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.2).timeout
	create_tween().tween_property(self, "modulate", Color(1, 1, 1), 0.25).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)

func handle_death() -> void:
	print("Dieded")

# --- Animation Functions ---

func update_blend_positions(direction_vector : Vector2) -> void:
	animation_tree.set("parameters/StateMachine/MoveState/RunState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/MoveState/MoveState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/TonicState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/MedianState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/DominantState/blend_position", direction_vector)
	animation_tree.set("parameters/StateMachine/DashState/blend_position", direction_vector)


func _on_player_hurtbox_area_entered(area: Area2D) -> void:
	if is_invinsible:
		return
	
	if not("Hitbox" in area.name):
		return
	
	var enemy := area.get_parent()
	if not(enemy is Enemy):
		return
	
	var now = Time.get_ticks_msec() / 1000.0
	if enemy not in last_hit_time:
		last_hit_time[enemy] = 0.0
		
	if now - last_hit_time[enemy] < damage_cooldown:
		return
	
	last_hit_time[enemy] = now
	take_damage(10)
	apply_knockback(enemy.global_position)

func apply_knockback(from_position : Vector2, strength : float = 1000.0) -> void:
	var direction : Vector2 = (global_position - from_position).normalized()
	velocity = direction * strength
	move_and_slide()

func update_hitbox_positions(direction_vector : Vector2) -> void:
	if direction_vector.angle() in [PI/2, PI/4]:
		tonic_hitbox.rotation = direction_vector.angle()
		median_hitbox.rotation = direction_vector.angle()
		dominant_hitbox.rotation = direction_vector.angle()
	else:
		tonic_hitbox.rotation = -direction_vector.angle()
		median_hitbox.rotation = -direction_vector.angle()
		dominant_hitbox.rotation = -direction_vector.angle()

func activate_hitbox(hitbox : Area2D) -> void:
	hitbox.monitoring = true
	await get_tree().create_timer(0.2).timeout
	hitbox.monitoring = false

func perform_attack() -> void:
	var state : String = playback.get_current_node()
	match state:
		"TonicState":
			activate_hitbox(tonic_hitbox)
		"MedianState":
			activate_hitbox(median_hitbox)
		"DominantState":
			activate_hitbox(dominant_hitbox)

func _on_tonic_hit(area: Area2D) -> void:
	var damage : float = tonic_damage * base_damage * (1.25 if on_beat else 1) * max(float(current_octave) / float(current_note_index + 1), float(current_note_index + 1) / float(current_octave))
	if area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(damage)
		if has_life_steal:
			health = clamp(health + damage * life_steal, 0.0, 100.0)
			hp_bar.value = clamp(health, 0.0, 100.0)

func _on_median_hit(area: Area2D) -> void:
	var damage : float = median_damage * base_damage * (1.25 if on_beat else 1) * max(float(current_octave) / float(current_note_index + 1), float(current_note_index + 1) / float(current_octave))
	if area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(damage)
		if has_life_steal:
			health = clamp(health + damage * life_steal, 0.0, 100.0)
			hp_bar.value = clamp(health, 0.0, 100.0)

func _on_dominant_hit(area: Area2D) -> void:
	var damage : float = (major_damage if major_amplified else dominant_damage) * base_damage * (1.25 if on_beat else 1) * max(float(current_octave) / float(current_note_index + 1), float(current_note_index + 1) / float(current_octave))
	if area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(damage)
		if has_life_steal:
			health = clamp(health + damage * life_steal, 0.0, 100.0)
			hp_bar.value = clamp(health, 0.0, 100.0)

func gain_exp() -> void:
	experience += 25.0 / level
	if experience >= 100.0:
		experience -= 100.0
		level += 1
		if max_octave < 6:
			max_octave += 1
