extends CharacterBody2D

@export var gold_pickup_scene: PackedScene
@export var wood_pickup_scene: PackedScene


@export var speed: float = 100
@export var health: float = 10
@export var strength: float = 1
@export var attack_rate: float = 1
@export var aggo_range: float = 100
@export var attack_range: float = 40

var knockback_velocity: Vector2 = Vector2.ZERO
var is_knocked_back: bool = false
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $Detection
@onready var attack_timer: Timer = $Timer
@onready var health_bar: ProgressBar = $ProgressBar

var player: Node2D = null
var current_health: int
var enemies_in_range: Array[Node2D] = []
var current_target: Node2D = null
var facing: String = "down"
var can_attack: bool = true
var is_attacking: bool = false
var is_dead: bool = false

func _ready() -> void:
	current_health = health
	_update_health_bar()

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		push_warning("Minion: no node in 'player' group found")

	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

	attack_timer.wait_time = attack_rate
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)


func _physics_process(_delta: float) -> void:
	if is_knocked_back:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 800.0 * _delta)
		if knockback_velocity.length() < 5.0:
			is_knocked_back = false
		move_and_slide()
		return
		
	_update_target()
	move_and_slide()
	

	if is_attacking:
		velocity = Vector2.ZERO
	elif current_target:
		var distance: float = global_position.distance_to(current_target.global_position)
		var direction: Vector2 = current_target.global_position - global_position

		if distance <= attack_range:
			velocity = Vector2.ZERO
			_face_direction(direction)
			_try_attack()
		else:
			velocity = direction.normalized() * speed
			_face_direction(direction)

	move_and_slide()
	_update_animation()


func _update_target() -> void:
	enemies_in_range = enemies_in_range.filter(func(e): return is_instance_valid(e))

	if current_target and not is_instance_valid(current_target):
		current_target = null

	if enemies_in_range.size() > 0:
		var nearest: Node2D = enemies_in_range[0]
		var nearest_dist: float = global_position.distance_to(nearest.global_position)
		for e in enemies_in_range:
			var d: float = global_position.distance_to(e.global_position)
			if d < nearest_dist:
				nearest = e
				nearest_dist = d
		current_target = nearest
	else:
		current_target = null


func _try_attack() -> void:
	if not can_attack or current_target == null:
		return
	can_attack = false
	is_attacking = true
	_play_attack_animation()
	attack_timer.start()

	if current_target.has_method("take_damage"):
		current_target.take_damage(strength)


func _on_attack_timer_timeout() -> void:
	can_attack = true
	is_attacking = false


func _face_direction(direction: Vector2) -> void:
	if direction.length() < 0.01:
		return
	if abs(direction.x) > abs(direction.y):
		facing = "right" if direction.x > 0 else "left"
	else:
		facing = "down" if direction.y > 0 else "up"


func _play_attack_animation() -> void:
	match facing:
		"right":
			anim.flip_h = false
			anim.play("Attack_Right")
		"left":
			anim.flip_h = true
			anim.play("Attack_Right")
		"down":
			anim.flip_h = false
			anim.play("Attack_Down")
		"up":
			anim.flip_h = false
			anim.play("Attack_Up")


func _update_animation() -> void:
	if is_attacking:
		return

	anim.flip_h = facing == "left"
	if velocity.length() > 2.0:
		anim.play("Run")
	else:
		anim.play("Idle")


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("minion"):
		enemies_in_range.append(body)
	elif body.is_in_group("player"):
		enemies_in_range.append(body)


func _on_detection_area_body_exited(body: Node2D) -> void:
	enemies_in_range.erase(body)
	if current_target == body:
		current_target = null


func take_damage(amount: int) -> void:
	if is_dead:
		return
	current_health = max(current_health - amount, 0)
	_update_health_bar()
	if current_health <= 0:
		is_dead = true
		_death()


func _update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = health
		health_bar.value = current_health
		
func apply_knockback(direction: Vector2, force: float) -> void:
	is_knocked_back = true
	knockback_velocity = direction.normalized() * force

func _death() -> void:
	set_physics_process(false)
	detection_area.monitoring = false
	detection_area.monitorable = false
	$Hurtbox.set_deferred("disabled",true)

	var pickup_scene: PackedScene
	if randf() < 0.6:
		pickup_scene = wood_pickup_scene
	else:
		pickup_scene = gold_pickup_scene

	if pickup_scene:
		var pickup = pickup_scene.instantiate()
		get_parent().add_child(pickup)
		pickup.global_position = global_position
	else:
		push_warning("Goblin: pickup scene not assigned")

	anim.play("die")
	await anim.animation_finished
	queue_free()
	
