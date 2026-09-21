extends StaticBody2D


@export var spawn_y_offset: float = 115.0
@export var wood_pickup_scene: PackedScene
@export var spawn_interval: float = 10.0
@export var spawn_radius: float = 55.0       # how far gold can land from the rock
@export var min_spawn_radius: float = 20.0   # avoid spawning right on top of the rock
@export var tween_duration: float = 0.4

@onready var spawn_timer: Timer = $Timer

func _ready() -> void:
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	if wood_pickup_scene == null:
		push_warning("gold drop cant be loaded in")
		return

	var pickup = wood_pickup_scene.instantiate()
	get_parent().add_child(pickup)

	# Spawn point: offset below the rock
	var spawn_position: Vector2 = global_position + Vector2(0, spawn_y_offset)
	pickup.global_position = spawn_position

	# Random target point in a ring around the rock
	var angle: float = randf_range(0.0, TAU)
	var distance: float = randf_range(min_spawn_radius, spawn_radius)
	var target_position: Vector2 = spawn_position + Vector2(cos(angle), sin(angle)) * distance

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
