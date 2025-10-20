extends Node2D
@export var target_beat: float = 0.0
@export var beat_map: Array = [
	[1.0, 0], # beat 1, tonic lane
	[2.0, 1], # beat 2, median lane
	[2.5, 2], # beat 2.5, dominant lane
	[3.0, 0],
	[4.0, 1],
]
