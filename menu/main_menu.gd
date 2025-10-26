extends Node
@onready var button: Button = $HBoxContainer/VBoxContainer/Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("start_game"):
		button.pressed.emit()

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world scenes/hack_n_slash.tscn")
