extends Node2D
class_name RhythmBattle

@export var note_scene: PackedScene
@export var bpm: float = 120.0
@export var spawn_ahead_beats: int = 4        # how many beats ahead notes are spawned
@export var scroll_speed: float = 400.0       # pixels per second
@export var beat_map: Array = []              # holds tuples of (beat_time, lane_index)

@onready var lanes := [
	$Lanes/Lane_Tonic,
	$Lanes/Lane_Median,
	$Lanes/Lane_Dominant
]

@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var combo_label: Label = $CanvasLayer/ComboLabel
@onready var music: AudioStreamPlayer = $Music

var beat_interval: float
var song_time: float = 0.0
var combo: int = 0
var score: int = 0
var active_notes: Array = []


func _ready() -> void:
	beat_interval = 60.0 / bpm
	music.play()
	set_process(true)
	print("Rhythm battle started!")


func _process(delta: float) -> void:
	if not music.playing:
		return
	song_time += delta

	# Spawn notes in sync with the beat map
	for data in beat_map:
		var beat_time = data[0]
		var lane_idx = data[1]
		if song_time + (spawn_ahead_beats * beat_interval) >= beat_time and data not in active_notes:
			spawn_note(lane_idx, beat_time)
			active_notes.append(data)

	# Move existing notes
	for lane in lanes:
		for note in lane.get_children():
			note.position.y += scroll_speed * delta
			if note.position.y > lane.get_node("TargetZone").position.y + 50:
				note.queue_free()
				reset_combo()


#func spawn_note(lane_idx: int, beat_time: float) -> void:
	#if not note_scene:
		#push_error("No note scene assigned!")
		#return
	#var note = note_scene.instantiate()
	#note.position = Vector2(0, -600) # start high above lane
	#note.set("target_beat", beat_time)
	#lanes[lane_idx].add_child(note)
func spawn_note(lane_idx: int, beat_time: float) -> void:
	if not note_scene:
		push_error("No note scene assigned!")
		return
	var note = note_scene.instantiate()
	note.lane = lane_idx           
	note.target_beat = beat_time
	# Start at the top of the lane
	note.position = Vector2(0, 45)
	lanes[lane_idx].add_child(note)



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("tonic_attack"):
		check_hit(0)
	if event.is_action_pressed("median_attack"):
		check_hit(1)
	if event.is_action_pressed("dominant_attack"):
		check_hit(2)


func check_hit(lane_idx: int) -> void:
	var lane = lanes[lane_idx]
	for note in lane.get_children():
		var target_zone = lane.get_node("TargetZone")
		var distance = abs(note.position.y - target_zone.position.y)

		if distance <= 20: # perfect
			score += 100
			combo += 1
			score_label.text = "Score: %d" % score
			combo_label.text = "Combo: %d" % combo
			note.queue_free()
			return
		elif distance <= 50: # good
			score += 50
			combo += 1
			score_label.text = "Score: %d" % score
			combo_label.text = "Combo: %d" % combo
			note.queue_free()
			return

	reset_combo()


func reset_combo() -> void:
	if combo > 0:
		print("Combo lost: ", combo)
	combo = 0
	combo_label.text = "Combo: 0"
