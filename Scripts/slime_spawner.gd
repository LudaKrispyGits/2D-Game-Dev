extends Node2D

@export var slime_scene: PackedScene
@export var splash_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var spawn_radius: float = 30.0
@export var min_spawn_radius: float = 10.0
@export var splash_lead_time: float = 0.3
@export var max_alive: int = 1
@export var max_total_spawns: int = 3

@onready var spawn_timer: Timer = $Timer

var active_spawns: Array[Node2D] = []
var total_spawned: int = 0


func _ready() -> void:
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()


func _on_spawn_timer_timeout() -> void:
	if total_spawned >= max_total_spawns:
		spawn_timer.stop()
		return

	active_spawns = active_spawns.filter(func(s): return is_instance_valid(s))

	if active_spawns.size() >= max_alive:
		return

	if slime_scene == null:
		push_warning("SlimeSpawner: slime_scene not assigned")
		return

	var angle: float = randf_range(0.0, TAU)
	var distance: float = randf_range(min_spawn_radius, spawn_radius)
	var spawn_position: Vector2 = global_position + Vector2(cos(angle), sin(angle)) * distance

	if splash_scene:
		var splash = splash_scene.instantiate()
		get_parent().add_child(splash)
		splash.global_position = spawn_position

	await get_tree().create_timer(splash_lead_time).timeout

	var slime = slime_scene.instantiate()
	get_parent().add_child(slime)
	slime.global_position = spawn_position
	slime.scale = Vector2.ZERO
	active_spawns.append(slime)
	total_spawned += 1
	slime.tree_exiting.connect(_on_spawn_died.bind(slime))

	var tween := slime.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(slime, "scale", Vector2.ONE, 0.3)

	if total_spawned >= max_total_spawns:
		spawn_timer.stop()
		
func _on_spawn_died(slime: Node2D) -> void:
	active_spawns.erase(slime)
	_check_should_despawn()


func _check_should_despawn() -> void:
	active_spawns = active_spawns.filter(func(s): return is_instance_valid(s))
	if total_spawned >= max_total_spawns and active_spawns.is_empty():
		queue_free()
