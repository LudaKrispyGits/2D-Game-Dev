extends StaticBody2D

@export var gold_pickup_scene: PackedScene
@export var spawn_interval: float = 15.0
@export var spawn_radius: float = 40.0 
@export var min_spawn_radius: float = 12.0   
@export var tween_duration: float = 0.4

@onready var spawn_timer: Timer = $Timer

func _ready() -> void:
	print("GoldRock ready() called")
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	if gold_pickup_scene == null:
		push_warning("gold drop cant be loaded in")
		return

	var pickup = gold_pickup_scene.instantiate()
	get_parent().add_child(pickup)

	# Spawn point: right at the rock
	pickup.global_position = global_position

	# Random target point in a ring around the rock (avoids min_spawn_radius dead zone)
	var angle: float = randf_range(0.0, TAU)
	var distance: float = randf_range(min_spawn_radius, spawn_radius)
	var target_position: Vector2 = global_position + Vector2(cos(angle), sin(angle)) * distance

	_animate_spawn(pickup, target_position)

func _animate_spawn(pickup: Node2D, target_position: Vector2) -> void:
	# Start small and invisible, pop out to full size while moving to target
	pickup.scale = Vector2.ZERO
	pickup.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	tween.tween_property(pickup, "global_position", target_position, tween_duration)
	tween.tween_property(pickup, "scale", Vector2.ONE, tween_duration)
	tween.tween_property(pickup, "modulate:a", 1.0, tween_duration * 0.6)
