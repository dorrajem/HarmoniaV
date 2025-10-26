extends Node2D
class_name RhythmBattle

@export var note_scene: PackedScene
@export var bpm: float = 120.0
@export var spawn_x: float = 270.0    # right-side X where notes spawn
@export var scroll_speed: float = 100.0 # pixels/sec moving left
@export var spawn_randomly: bool = true # if false, use beat_map
@export var beat_map: Array = []       # optional: array of (beat_time_seconds, lane_index)
@export var player : CharacterBody2D
@export var target_zone_1 : Vector2
@onready var tonic_sprite: Sprite2D = $Lanes/LaneTonic/TonicSprite
@onready var median_sprite: Sprite2D = $Lanes/LaneMedian/MedianSprite
@onready var dominant_sprite: Sprite2D = $Lanes/LaneDominant/DominantSprite
@onready var music: AudioStreamPlayer = $Music

# hit windows (in pixels)
const PERFECT_WINDOW = 30
const GOOD_WINDOW = 70

@onready var lanes = [
	$Lanes/LaneTonic,
	$Lanes/LaneMedian,
	$Lanes/LaneDominant
]
@onready var notes = [
	$Lanes/LaneTonic/Notes, $Lanes/LaneMedian/Notes, $Lanes/LaneDominant/Notes
]
@onready var target_zones : Array = [
	$Lanes/LaneTonic/TargetZone, $Lanes/LaneMedian/TargetZone, $Lanes/LaneDominant/TargetZone
]
@onready var fail_label: Label = %FailLabel
@onready var lose_label: Label = %LoseLabel

@onready var score_label: Label = $MozikUI/ScoreLabel
@onready var combo_label: Label = $MozikUI/ComboLabel

var beat_interval: float
var song_time: float = 0.0
var next_spawn_time: float = 0.0
var score: int = 0
var combo: int = 0
var combo_fails : int = 0
func _ready() -> void:
	player.visible = false
	player.ui.visible = false
	player.camera_2d.enabled = false
	player.current_octave = 4
	beat_interval = 60.0 / bpm
	next_spawn_time = beat_interval
	if music and music.stream:
		music.play()
	set_process(true)
	_update_ui()

func _process(delta: float) -> void:
	# time tracking (even without music)
	song_time += delta

	# spawn by beat interval or from beat_map
	if spawn_randomly:
		if song_time >= next_spawn_time:
			var lane_idx = randi() % lanes.size()
			spawn_note(lane_idx)
			next_spawn_time += beat_interval
	else:
		# spawn from beat_map (beat_map entries are absolute seconds)
		for entry in beat_map:
			var beat_time = entry[0]
			var lane_idx = entry[1]
			# spawn ahead so notes reach target at beat_time
			if song_time >= beat_time - (spawn_x / scroll_speed) and not entry.has("spawned"):
				spawn_note(lane_idx)
				entry["spawned"] = true

	## move notes (left)
	for note_a in notes:
		for note in note_a.get_children():
			if note:
				note.position.x -= scroll_speed * delta
			# if off-screen left, free and reset combo
				var target_x = 0.0
				if note.position.x < target_x:
					note.queue_free()
					_reset_combo()

func spawn_note(lane_idx: int) -> void:
	var colors = [Color(1,0.8,0.2), Color(0.8,1,0.4), Color(0.2,0.6,1)]
	if not note_scene:
		push_error("RhythmBattle.spawn_note: note_scene is not assigned in inspector.")
		return
	var note = note_scene.instantiate()
	# local position relative to lane: spawn_x (world) -> convert to lane coords
	var lane = lanes[lane_idx]
	var world_spawn = Vector2(spawn_x, lane.position.y + 15)
	note.position = lane.to_local(world_spawn)
	note.color = colors[lane_idx % colors.size()]
	notes[lane_idx].add_child(note)

func _input(event) -> void:
	if event.is_action_pressed("tonic_attack"):
		_check_hit(0)
		create_tween().tween_property(tonic_sprite, "modulate", Color.WHITE, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await get_tree().create_timer(0.2).timeout
		create_tween().tween_property(tonic_sprite, "modulate", Color(0.74, 0.75, 0.75), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	elif event.is_action_pressed("median_major_attack") or event.is_action_pressed("median_minor_attack"):
		_check_hit(1)
		create_tween().tween_property(median_sprite, "modulate", Color.WHITE, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await get_tree().create_timer(0.2).timeout
		create_tween().tween_property(median_sprite, "modulate", Color(0.74, 0.75, 0.75), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	elif event.is_action_pressed("dominant_attack"):
		_check_hit(2)
		create_tween().tween_property(dominant_sprite, "modulate", Color.WHITE, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await get_tree().create_timer(0.2).timeout
		create_tween().tween_property(dominant_sprite, "modulate", Color(0.74, 0.75, 0.75), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _check_hit(lane_idx: int) -> void:
	var target_zone : Area2D = target_zones[lane_idx]
	target_zone.monitoring = true
	await get_tree().create_timer(0.1).timeout
	target_zone.monitoring = false
	# find closest note by abs(x - target_x)
	#var best_note = null
	#var best_dist = 1e9
	#for note in lane.get_children():
		#var d = abs(note.position.x - target_x)
		#if d < best_dist:
			#best_dist = d
			#best_note = note

	#if best_note:
		#if best_dist <= PERFECT_WINDOW:
			#_on_hit(best_note, "perfect")
		#elif best_dist <= GOOD_WINDOW:
			#_on_hit(best_note, "good")
		#else:
			#_on_miss()
	#else:
		#_on_miss()

func _on_hit(note, quality: String) -> void:
	note.queue_free()
	if quality == "perfect":
		score += 100
		combo += 1
	elif quality == "good":
		score += 50
		combo += 1
	_update_ui()
	# visual debug
	print("%s hit! score=%d combo=%d" % [quality.capitalize(), score, combo])

func _on_miss() -> void:
	_reset_combo()
	print("Miss!")

func _reset_combo() -> void:
	if combo > 0:
		print("Combo lost:", combo)
	combo = 0
	combo_fails += 1
	$MozikUI/ComboFails.text = "Combo Fails = " + str(combo_fails)
	if combo_fails <= 10:
		display_fail()
	else:
		display_loss()
	_update_ui()

func _update_ui() -> void:
	if score_label:
		score_label.text = "Score: %d" % score
	if combo_label:
		combo_label.text = "Combo: %d" % combo


func _on_target_zone_tonic_entered(area: Area2D, me = target_zones[0]) -> void:
	if area.name != "NoteArea":
		return
	create_tween().tween_property(tonic_sprite, "modulate", Color(0.7, 1, 0.5), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.2).timeout
	create_tween().tween_property(tonic_sprite, "modulate", Color(0.75, 0.75, 0.75), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_on_hit(area.get_parent(), "perfect")
	me.monitoring = false


func _on_target_zone_median_entered(area: Area2D, me = target_zones[1]) -> void:
	if area.name != "NoteArea":
		return
	create_tween().tween_property(median_sprite, "modulate", Color(0.7, 1, 0.5), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.2).timeout
	create_tween().tween_property(median_sprite, "modulate", Color(0.75, 0.75, 0.75), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_on_hit(area.get_parent(), "perfect")
	me.monitoring = false


func _on_target_zone_dominant_entered(area: Area2D, me = target_zones[2]) -> void:
	if area.name != "NoteArea":
		return
	create_tween().tween_property(dominant_sprite, "modulate", Color(0.7, 1, 0.5), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.2).timeout
	create_tween().tween_property(dominant_sprite, "modulate", Color(0.75, 0.75, 0.75), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_on_hit(area.get_parent(), "perfect")
	me.monitoring = false

func display_fail() -> void:
	create_tween().tween_property(fail_label, "text", "Combo Failed", 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	create_tween().tween_property(fail_label, "modulate", Color.RED, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await get_tree().create_timer(2.5).timeout
	create_tween().tween_property(fail_label, "text", "", 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	create_tween().tween_property(fail_label, "modulate", Color.WHITE, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func display_loss() -> void:
	fail_label.visible = false
	create_tween().tween_property(lose_label, "text", "YOU LOST", 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	create_tween().tween_property(lose_label, "modulate", Color.RED, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	self.process_mode = Node.PROCESS_MODE_DISABLED
	await get_tree().create_timer(2.5).timeout
	create_tween().tween_property(lose_label, "text", "", 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	create_tween().tween_property(lose_label, "modulate", Color.WHITE, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	get_tree().change_scene_to_file("res://menu/main_menu.tscn")
