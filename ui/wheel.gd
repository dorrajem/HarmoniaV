extends Node2D

@export var ui : UI
@onready var note_anchor: Node2D = $NoteAnchor
@onready var octaves_anchor: Node2D = $OctavesAnchor

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func rotate_notes(note : String) -> void:
	var degree : float
	match note:
		"C":
			degree = 42.4
		"D":
			degree = 85
		"E":
			degree = 133
		"F":
			degree = 180
		"G":
			degree = 255.5
		"A":
			degree = 268
		"B":
			degree = 316.5
	create_tween().tween_property(note_anchor, "rotation_degrees", degree, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func rotate_octaves(oct : int) -> void:
	var degree : float 
	match oct:
		2: degree = 87.5
		3: degree = 141
		4: degree = 182
		5: degree = 224.5
		6: degree = 270
	create_tween().tween_property(octaves_anchor, "rotation_degrees", degree, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
