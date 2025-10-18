extends CanvasLayer

@onready var note_display: Label = $NoteDisplay
@onready var combo_meter: HBoxContainer = $ComboMeter
@onready var combo_label: Label = $ComboMeter/ComboLabel
@onready var combo_bar: ProgressBar = $ComboMeter/ComboBar
@onready var rythm_bar: ProgressBar = $RythmBar

@export var player : Player
@export var beat_tick_timer : Timer

var combo_value : int = 0
var combo_decay_rate : float = 0.2

func _ready() -> void:
	reset_combo()

func _process(delta: float) -> void:
	combo_bar.value = max(combo_value - combo_decay_rate * delta, 0)
	
	if beat_tick_timer.time_left >= player.BEAT_INTERVAL:
		rythm_bar.value = 100
	else:
		rythm_bar.value = 100 - (beat_tick_timer.wait_time / player.BEAT_INTERVAL) * 100

func update_note_display(note : String, octave : int) -> void:
	note_display.text = "%s%d" % [note, octave]

func add_combo() -> void:
	combo_value += 1
	combo_label.text = "Combo x%d" % combo_value
	combo_bar.value = 100

func reset_combo() -> void:
	combo_value = 0
	combo_label.text = ""
	combo_bar.value = 0
