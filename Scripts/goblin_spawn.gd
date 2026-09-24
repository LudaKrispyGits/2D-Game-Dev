extends StaticBody2D

@export var spawn_y_offset: float = 0.0
@export var GoblinSpawn: PackedScene
@export var explosion_scene: PackedScene
@export var spawn_interval: float = 7.0
@export var spawn_radius: float = 40.0
@export var min_spawn_radius: float = 15.0
@export var tween_duration: float = 0.4
@export var goblin_target_scale: Vector2 = Vector2(0.6, 0.6)

@export var max_health: int = 30

@export var gold_pickup_scene: PackedScene
@export var gold_drop_amount: int = randf_range(3,6)

@export var wood_pickup_scene: PackedScene
@export var wood_drop_amount: int = randf_range(6,8)

@onready var spawn_timer: Timer = $Timer
@onready var hurtbox: Area2D = $Hurtbox
@onready var health_bar: ProgressBar = $ProgressBar

var current_health: int
var is_destroyed: bool = false


func _ready() -> void:
	current_health = max_health
	_update_health_bar()

	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()


func _on_spawn_timer_timeout() -> void:
	if GoblinSpawn == null:
		return

	var enemy = GoblinSpawn.instantiate()
	get_parent().add_child(enemy)

	var spawn_position: Vector2 = global_position + Vector2(0, spawn_y_offset)
	enemy.global_position = spawn_position

	var angle: float = randf_range(0.0, TAU)
	var distance: float = randf_range(min_spawn_radius, spawn_radius)
	var target_position: Vector2 = spawn_position + Vector2(cos(angle), sin(angle)) * distance

	_animate_spawn(enemy, target_position)


func _animate_spawn(enemy: Node2D, target_position: Vector2) -> void:
	enemy.scale = Vector2.ZERO
	enemy.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	tween.tween_property(enemy, "global_position", target_position, tween_duration)
	tween.tween_property(enemy, "scale", goblin_target_scale, tween_duration)
	tween.tween_property(enemy, "modulate:a", 1.0, tween_duration * 0.6)


func take_damage(amount: int) -> void:
	if is_destroyed:
		return
	current_health = max(current_health - amount, 0)
	_update_health_bar()
	if current_health <= 0:
		is_destroyed = true
		_destroy()


func _update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health


func _destroy() -> void:
	spawn_timer.stop()
	hurtbox.monitorable = false

	if gold_pickup_scene:
		for i in range(gold_drop_amount):
			var pickup = gold_pickup_scene.instantiate()
			get_parent().add_child(pickup)
			var offset: Vector2 = Vector2(randf_range(-15, 15), randf_range(-15, 15))
			pickup.global_position = global_position + offset
	if wood_pickup_scene:
		for i in range(wood_drop_amount):
			var wpickup = wood_pickup_scene.instantiate()
			get_parent().add_child(wpickup)
			var offset: Vector2 = Vector2(randf_range(-15, 15), randf_range(-15, 15))
			wpickup.global_position = global_position + offset
		
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_position = global_position
	queue_free()
