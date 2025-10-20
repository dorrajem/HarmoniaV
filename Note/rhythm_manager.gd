extends Node2D

@export var bpm: int = 120  # beats per minute
@export var beats_per_bar: int = 4
@export var note_lanes: int = 3  # tonic, median, dominant
var beat_count: int
var beat_interval: float
var time_elapsed: float = 0.0
var next_note_time: float = 0.0

var note_scene: PackedScene


@export var spawn_x: float = 800.0
@export var lane_spacing: float = 100.0
@export var lanes_count: int = 3
@export var lane_center_y: float = 0.0

func get_lane_spawn_position(lane_index: int) -> Vector2:
	# clamp to valid indices to avoid errors
	lane_index = clamp(lane_index, 0, lanes_count - 1)
	# lane 0 = top, lane 1 = middle, lane 2 = bottom
	var offset = (lane_index - (lanes_count - 1) / 2.0) * lane_spacing
	return Vector2(spawn_x, lane_center_y + offset)

# Usage example:
func spawn_random_note():
	var note = preload("res://Note/note_scene.tscn").instantiate()
	var lane_index = randi() % lanes_count
	note.position = get_lane_spawn_position(lane_index)
	$NoteContainer.add_child(note)

func _ready():
	beat_interval = 60.0 / bpm
	note_scene = preload("res://Note/note_scene.tscn")
	next_note_time = beat_interval  # first note after one beat

func _process(delta):
	time_elapsed += delta
	
	if time_elapsed >= next_note_time:
		generate_note()
		next_note_time += beat_interval

var lane_y_positions = {
	"tonic": -100,
	"median": 0,
	"dominant": 100
}


func generate_note():
	beat_count += 1

	# Every bar (4 beats), maybe have a different pattern type
	var pattern_type = beat_count % 8

	match pattern_type:
		0, 4:
			spawn_note_in_lane(0)  # tonic
		1, 5:
			spawn_note_in_lane(1)  # median
		2, 6:
			spawn_note_in_lane(2)  # dominant
		3, 7:
			spawn_chord()  # 3 notes together
func spawn_note_in_lane(lane_index: int):
	var note = note_scene.instantiate()
	note.lane = lane_index
	add_child(note)
	note.position = get_lane_spawn_position(lane_index)

func spawn_chord():
	for i in range(note_lanes):
		spawn_note_in_lane(i)

	
	
