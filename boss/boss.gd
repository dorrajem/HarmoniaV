extends "res://enemy/enemy.gd"

@export var phase: int = 1
@export var is_rhythm_battle_triggered: bool = false

var max_health : float = 250.0



func _ready() -> void:
	super()
	hp_bar.value = 250.0
	hp_bar.max_value = health
	health = 250.0
	guitar.visible = false
	drum.visible = false
	health = max_health
	add_to_group("Boss")
	print("Boss spawned with %d HP" % max_health)

func _process(delta: float) -> void:
	$HPBar.value = clamp(health, 0.0, max_health)

func _physics_process(delta: float) -> void:
	super(delta)
	

func take_damage(amount: int) -> void:
	# Keep base enemy behavior
	hp_bar.value = clamp(health, 0.0, 250.0)
	super(amount)

	# Add boss-specific logic
	if health <= max_health * 0.125 and not is_rhythm_battle_triggered:
		trigger_rhythm_battle()

func trigger_rhythm_battle() -> void:
	is_rhythm_battle_triggered = true
	print("Boss entering rhythm battle phase!")
	
	get_tree().change_scene_to_file("res://scenes/world scenes/rhythm_battle.tscn")

	# Optionally disable boss while rhythm battle happens
	hide()
	set_physics_process(false)
