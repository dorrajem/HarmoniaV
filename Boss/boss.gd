extends "res://Enemy/enemy.gd"

@export var phase: int = 1
@export var is_rhythm_battle_triggered: bool = false

func _ready() -> void:
	add_to_group("Boss")
	max_health = 100
	health = max_health
	print("Boss spawned with %d HP" % max_health)

func take_damage(amount: int) -> void:
	# Keep base enemy behavior
	super(amount)

	# Add boss-specific logic
	if health <= max_health * 0.5 and not is_rhythm_battle_triggered:
		trigger_rhythm_battle()

func trigger_rhythm_battle() -> void:
	is_rhythm_battle_triggered = true
	print("Boss entering rhythm battle phase!")
	
	var rhythm_scene = preload("res://Scenes/World Scenes/rhythm_section.tscn").instantiate()
	get_tree().current_scene.add_child(rhythm_scene)

	# Optionally disable boss while rhythm battle happens
	hide()
	set_physics_process(false)
