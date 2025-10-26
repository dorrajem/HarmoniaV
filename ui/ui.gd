class_name UI extends CanvasLayer


@onready var v_box_container: VBoxContainer = %VBoxContainer
@onready var h_box_container: HBoxContainer = %HBoxContainer
@onready var h_1: Control = %H1
@onready var note_pulse: ColorRect = %NotePulse
#@onready var rythm_bar: ProgressBar = %RythmBar
@onready var separator: HBoxContainer = %Separator
@onready var note_display: Label = %NoteDisplay
@onready var combo_meter: HBoxContainer = %ComboMeter
@onready var combo_bar: ProgressBar = %ComboBar
@onready var combo_label: Label = %ComboLabel
@onready var exp_bar: ProgressBar = %ExpBar
@onready var level_label: Label = %LevelLabel
@onready var combo_display_label: Label = %ComboDisplayLabel
@onready var die_label: Label = %DieLabel
@onready var wheel: Node2D = $Wheel


@export var player : Player
@export var beat_tick_timer : Timer

var combo_value : int = 0
var combo_decay_rate : float = 0.2

func _ready() -> void:
	reset_combo()
	update_note_display("C", 2)
	exp_bar.value = clamp(player.experience, 0.0, 100.0)
	# connect to beat tick
	if beat_tick_timer:
		beat_tick_timer.connect("timeout", _on_beat_tick)
	else:
		push_warning("UI : beat_tick_timer is missing or not assigned")

func _process(delta: float) -> void:
	exp_bar.value = lerp(clamp(player.experience, 0.0, 100.0), clamp(player.experience, 0.0, 100.0), 0.2)
	combo_bar.value = max(combo_value - combo_decay_rate * delta * 60, 0)
	level_label.text = "Level " + str(player.level)
	
	

func update_note_display(note : String, octave : int) -> void:
	note_display.text = "%s%d" % [note, octave]
	wheel.rotate_notes(note)
	wheel.rotate_octaves(octave)

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
	#rythm_bar.value = 100
	#var tween_rythm_bar : Tween = create_tween()
	#tween_rythm_bar.tween_property(rythm_bar, "value", 0, beat_tick_timer.wait_time).set_trans(Tween.TRANS_LINEAR)

#func _on_rythm_tween_process() -> void:
	#rythm_bar.value = clamp(rythm_bar.value * 100, 0, 100)

func pulse_on_hit(on_beat : bool) -> void:
	if on_beat:
		note_pulse.color = Color(0.3, 1, 0.3)
	else:
		note_pulse.color = Color(1, 0.3, 0.3)
	create_tween().tween_property(note_pulse, "color", Color.WHITE, 0.35)

func flash(node, str : String) -> void:
	create_tween().tween_property(node, "modulate", Color(0.3, 1, 0.3), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func combo_display(combo : String, ability : String) -> void:
	create_tween().tween_property(combo_display_label, "text", combo + "Combo\n" + "Effect : " + ability, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await get_tree().create_timer(2.5).timeout
	create_tween().tween_property(combo_display_label, "text", "", 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func level_display(level : int) -> void:
	create_tween().tween_property(combo_display_label, "text", "Level Up!\nNew Octave Unlocked", 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await get_tree().create_timer(2.5).timeout
	create_tween().tween_property(combo_display_label, "text", "", 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func die_display() -> void:
	create_tween().tween_property(die_label, "text", "Dieded", 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	create_tween().tween_property(die_label, "modulate", Color.RED, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await get_tree().create_timer(2.5).timeout
	create_tween().tween_property(die_label, "text", "", 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	create_tween().tween_property(die_label, "modulate", Color.WHITE, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
