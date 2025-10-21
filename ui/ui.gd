extends CanvasLayer

@onready var v_box_container: VBoxContainer = $VBoxContainer
@onready var h_box_container: HBoxContainer = $VBoxContainer/HBoxContainer
@onready var note_pulse: ColorRect = $VBoxContainer/HBoxContainer/NotePulse
@onready var rythm_bar: ProgressBar = $VBoxContainer/HBoxContainer/RythmBar
@onready var combo_history: VBoxContainer = $VBoxContainer/Separator/ComboHistory
@onready var note_display: Label = $VBoxContainer/NoteDisplay
@onready var combo_meter: HBoxContainer = $VBoxContainer/ComboMeter
@onready var combo_bar: ProgressBar = $VBoxContainer/ComboMeter/ComboBar
@onready var combo_label: Label = $VBoxContainer/ComboMeter/ComboLabel


@export var player : Player
@export var beat_tick_timer : Timer

var combo_value : int = 0
var combo_decay_rate : float = 0.2

func _ready() -> void:
	reset_combo()
	# connect to beat tick
	if beat_tick_timer:
		beat_tick_timer.connect("timeout", _on_beat_tick)
	else:
		push_warning("UI : beat_tick_timer is missing or not assigned")

func _process(delta: float) -> void:
	combo_bar.value = max(combo_value - combo_decay_rate * delta * 60, 0)

func update_note_display(note : String, octave : int) -> void:
	note_display.text = "%s%d" % [note, octave]

func add_combo() -> void:
	combo_value += 1
	combo_label.text = "Combo x%d" % combo_value
	combo_bar.value = 100

func reset_combo() -> void:
	combo_value = 0
	combo_label.text = "Combo "
	combo_bar.value = 0
	create_tween().tween_property(combo_label, "modulate", Color.WHITE, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_beat_tick() -> void:
	if note_pulse:
		note_pulse.scale = Vector2.ONE
		var tween_pulse : Tween = create_tween()
		tween_pulse.tween_property(note_pulse, "scale", Vector2(1.5, 1.5), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween_pulse.tween_property(note_pulse, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	rythm_bar.value = 100
	var tween_rythm_bar : Tween = create_tween()
	tween_rythm_bar.tween_property(rythm_bar, "value", 0, beat_tick_timer.wait_time).set_trans(Tween.TRANS_LINEAR)

func _on_rythm_tween_process() -> void:
	rythm_bar.value = clamp(rythm_bar.value * 100, 0, 100)

func pulse_on_hit(on_beat : bool) -> void:
	if on_beat:
		note_pulse.color = Color(0.3, 1, 0.3)
	else:
		note_pulse.color = Color(1, 0.3, 0.3)
	create_tween().tween_property(note_pulse, "color", Color.WHITE, 0.2)

func flash(node, str : String) -> void:
	create_tween().tween_property(node, "modulate", Color(0.3, 1, 0.3), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

var combo_labels_index : int = 0
func display_combo_history(combo_str : String) -> void:
	var combo_label : Label = combo_history.get_child(combo_labels_index)
	combo_label.text = combo_str
	combo_labels_index += 1
	if combo_label.text != "" and combo_labels_index >= combo_history.get_child_count():
		combo_labels_index = 0
