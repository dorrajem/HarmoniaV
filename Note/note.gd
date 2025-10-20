extends Node2D

# Lane index (0 = tonic, 1 = median, 2 = dominant)
@export var lane: int = 0

# Beat time when this note should reach the target
@export var target_beat: float = 0.0

@export var speed: float = 400.0

func _process(delta: float) -> void:
	# Move note downward along Y axis
	position.y += speed * delta

	# Remove if it goes off screen
	if position.y > 1000:
		queue_free()
