extends CharacterBody2D

@export var health: int = 15
@export var move_speed: float = 80.0
@export var aggro_range: float = 250.0
@export var attack_range: float = 30.0
@export var contact_knockback_force: float = 300.0
#@export var wood_pickup_scene: PackedScene
#@export var gold_pickup_scene: PackedScene

@onready var death: AudioStreamPlayer2D = $Die
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var health_bar: ProgressBar = $ProgressBar

var player: Node2D = null
var current_health: int
var is_dead: bool = false

var knockback_velocity: Vector2 = Vector2.ZERO
var is_knocked_back: bool = false


func _ready() -> void:
	current_health = health
	_update_health_bar()

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	hitbox.body_entered.connect(_on_hitbox_body_entered)


func _physics_process(delta: float) -> void:
	if is_knocked_back:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 800.0 * delta)
		if knockback_velocity.length() < 5.0:
			is_knocked_back = false
		move_and_slide()
		return

	if is_dead:
		return

	if player == null or not is_instance_valid(player):
		velocity = Vector2.ZERO
		anim.play("Idle")
		move_and_slide()
		return

	var distance: float = global_position.distance_to(player.global_position)
	var direction: Vector2 = player.global_position - global_position
	anim.flip_h = direction.x < 0

	if distance <= attack_range:
		velocity = Vector2.ZERO
		anim.play("Idle")
	elif distance <= aggro_range:
		velocity = direction.normalized() * move_speed
		anim.play("Hop")
	else:
		velocity = Vector2.ZERO
		anim.play("Idle")

	move_and_slide()


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("apply_knockback"):
		var direction: Vector2 = (body.global_position - global_position).normalized()
		body.apply_knockback(direction, contact_knockback_force)


func apply_knockback(direction: Vector2, force: float) -> void:
	is_knocked_back = true
	knockback_velocity = direction.normalized() * force


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


func _death() -> void:
	set_physics_process(false)
	hitbox.monitorable = false
	hitbox.monitoring = false
	death.play()
	#var pickup_scene: PackedScene
	#if randf() < 0.6:
		#pickup_scene = wood_pickup_scene
	#else:
		#pickup_scene = gold_pickup_scene

	#if pickup_scene:
		#var pickup = pickup_scene.instantiate()
		#get_parent().add_child(pickup)
		#pickup.global_position = global_position

	anim.play("Death")
	await anim.animation_finished
	queue_free()
