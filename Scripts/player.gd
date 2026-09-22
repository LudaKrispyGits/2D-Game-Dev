extends CharacterBody2D

signal resources_changed(gold: int, wood: int)

@export var move_speed: float = 150.0
@export var knockback_frame: int = 1
@export var knockback_force: float = 250.0
@export var knockback_recovery_speed: float = 800.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
#@onready var swing_sound: AudioStreamPlayer2D = $SwingSound
@onready var hitbox: Area2D = $Hitbox
@onready var collision_shape_2d: CollisionShape2D = $Hitbox/CollisionShape2D

var gold: int = 2
var wood: int = 2

var last_direction: Vector2 = Vector2.RIGHT
var is_attacking: bool = false
var knockback_dealt_this_attack: bool = false
var bodies_in_hitbox: Array[Node2D] = []
var hitbox_offset: Vector2

var knockback_velocity: Vector2 = Vector2.ZERO
var is_knocked_back: bool = false


func _ready() -> void:
	hitbox_offset = hitbox.position
	hitbox.monitoring = false
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	hitbox.body_exited.connect(_on_hitbox_body_exited)
	animated_sprite_2d.frame_changed.connect(_on_frame_changed)
	animated_sprite_2d.animation_finished.connect(_on_animated_sprite_2d_animation_finished)


func _physics_process(delta: float) -> void:
	if is_knocked_back:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_recovery_speed * delta)
		if knockback_velocity.length() < 5.0:
			is_knocked_back = false
		move_and_slide()
		return
		

	var input_vector: Vector2 = Vector2.ZERO
	input_vector.x = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	input_vector.y = Input.get_action_strength("Down") - Input.get_action_strength("Up")
	input_vector = input_vector.normalized()

	if input_vector != Vector2.ZERO and not is_attacking:
		last_direction = _get_dominant_direction(input_vector)
		update_hitbox_offset()

	if Input.is_action_just_pressed("Attack") and not is_attacking:
		attack()

	if is_attacking:
		velocity = Vector2.ZERO
	else:
		velocity = input_vector * move_speed
		_update_movement_animation(input_vector)

	move_and_slide()


func _get_dominant_direction(dir: Vector2) -> Vector2:
	if abs(dir.x) > abs(dir.y):
		return Vector2.RIGHT if dir.x > 0 else Vector2.LEFT
	else:
		return Vector2.DOWN if dir.y > 0 else Vector2.UP


func _update_movement_animation(input_vector: Vector2) -> void:
	if input_vector == Vector2.ZERO:
		return  # add an Idle animation call here if you have one
	play_animation("Walk", last_direction)


func add_gold(amount: int) -> void:
	gold += amount
	print("Gold: ", gold)
	resources_changed.emit(gold, wood)


func add_wood(amount: int) -> void:
	wood += amount
	print("Wood: ", wood)
	resources_changed.emit(gold, wood)


func spend_resources(gold_cost: int, wood_cost: int) -> bool:
	if gold < gold_cost or wood < wood_cost:
		print("Player doesn't have enough gold or wood")
		return false
	gold -= gold_cost
	wood -= wood_cost
	resources_changed.emit(gold, wood)
	return true


func play_animation(prefix: String, dir: Vector2) -> void:
	if dir.x != 0:
		animated_sprite_2d.flip_h = dir.x < 0
		animated_sprite_2d.play(prefix + "_Right")
	elif dir.y < 0:
		animated_sprite_2d.play(prefix + "_Up")
	elif dir.y > 0:
		animated_sprite_2d.play(prefix + "_Down")


func attack() -> void:
	is_attacking = true
	knockback_dealt_this_attack = false
	hitbox.monitoring = true
	#swing_sound.play()
	play_animation("Attack", last_direction)


func _on_frame_changed() -> void:
	if not is_attacking or knockback_dealt_this_attack:
		return
	if animated_sprite_2d.frame != knockback_frame:
		return

	knockback_dealt_this_attack = true
	for body in bodies_in_hitbox:
		if is_instance_valid(body) and body.has_method("apply_knockback"):
			var direction: Vector2 = (body.global_position - global_position).normalized()
			body.apply_knockback(direction, knockback_force)


func _on_animated_sprite_2d_animation_finished() -> void:
	if is_attacking:
		is_attacking = false
		hitbox.monitoring = false
		bodies_in_hitbox.clear()


func apply_knockback(direction: Vector2, force: float) -> void:
	is_knocked_back = true
	knockback_velocity = direction.normalized() * force


func update_hitbox_offset() -> void:
	var x := hitbox_offset.x
	var y := hitbox_offset.y

	match last_direction:
		Vector2.LEFT:
			hitbox.position = Vector2(-x, y)
			collision_shape_2d.shape.size = Vector2(20, 20)
		Vector2.RIGHT:
			hitbox.position = Vector2(x, y)
			collision_shape_2d.shape.size = Vector2(20, 20)
		Vector2.UP:
			hitbox.position = Vector2(y, -x)
			collision_shape_2d.shape.size = Vector2(45, 20)
		Vector2.DOWN:
			hitbox.position = Vector2(-y, x)
			collision_shape_2d.shape.size = Vector2(45, 20)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body == self:
		return
	if not bodies_in_hitbox.has(body):
		bodies_in_hitbox.append(body)


func _on_hitbox_body_exited(body: Node2D) -> void:
	bodies_in_hitbox.erase(body)
