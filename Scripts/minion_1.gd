extends CharacterBody2D

@export var move_speed: float = 120.0
@export var follow_offset: Vector2 = Vector2(0, 30)   
@export var follow_deadzone: float = 10.0
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.2
@export var strength: int = 2
@export var max_health: int = 10
@export var damage_frame: int = 4

@onready var death: AudioStreamPlayer2D = $Die
var has_revived: bool = false
@onready var sword: AudioStreamPlayer2D = $Sound
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $Detection
@onready var attack_timer: Timer = $AttackTimer
@onready var health_bar: ProgressBar = $ProgressBar
@onready var name_label: Label = $Name

var player: Node2D = null
var current_health: int
var enemies_in_range: Array[Node2D] = []
var current_target: Node2D = null
var attack_target: Node2D = null
var facing: String = "down"
var can_attack: bool = true
var is_attacking: bool = false
var damage_dealt_this_attack: bool = false
var is_dead: bool = false
@export var possible_names: Array[String] = [
	"Bingus", "lingus", "Pingus", "Bongus", "Wongus",
	"Embaa", "Slongus", "Jongus", "Pongus", "Joey", "Name Pending", "Youngus", "Glongus", "Tung-Tongus", "Amongus", "Rongus"
	, "Wongus" , "Meat Longus", "So Wrongus", "Evil Joey", "{__}", "Waltus","Flongus","Dongus","Crongus","Le Chonkus","Ur Rightus","Mai Anus"
	,"NoGuerius", "Big Raga"
]

var minion_name: String = ""

func _ready() -> void:
	minion_name = possible_names.pick_random() if possible_names.size() > 0 else ""
	print(minion_name, " spawned")
	if name_label:
		name_label.text = minion_name
	if minion_name == "Joey":
		strength = 1
		max_health = 30
		move_speed = 60
		scale *= 1.6
		name_label.add_theme_color_override("font_color", Color.YELLOW)
		

	elif minion_name == "Evil Joey":
		strength = 100
		max_health = 2
		scale *= .5
		name_label.scale *= 2
		move_speed = 300
		name_label.add_theme_color_override("font_color", Color.YELLOW)

	elif minion_name == "Le Chonkus":
		strength = 1
		max_health = 60
		scale *= 2
		move_speed = 10
		name_label.add_theme_color_override("font_color", Color.YELLOW)
		
	elif minion_name == "NoGuerius":
		strength = 5
		max_health = 15
		move_speed = 120
		attack_cooldown = 3
		name_label.add_theme_color_override("font_color", Color.YELLOW)
	elif minion_name == "Embaa":
		strength = 5
		max_health = 15
		move_speed = 120
		attack_cooldown = .3
		name_label.add_theme_color_override("font_color", Color.YELLOW)
	elif minion_name == "Big Raga":
		strength = 4
		max_health = 25
		move_speed = 30
		scale *= 3 
		attack_cooldown = 1
		name_label.add_theme_color_override("font_color", Color.YELLOW)


		
		
	current_health = max_health
	_update_health_bar()

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		push_warning("Minion: no node in 'player' group found")

	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)

	anim.frame_changed.connect(_on_frame_changed)


func add_gold(amount: int) -> void:
	if player and player.has_method("add_gold"):
		player.add_gold(amount)
	else:
		push_warning("Minion couldn't find player to give gold to")

func add_wood(amount: int) -> void:
	if player and player.has_method("add_wood"):
		player.add_wood(amount)
	else:
		push_warning("Minion couldn't find player to give wood to")


func _physics_process(_delta: float) -> void:
	_update_target()

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
			velocity = direction.normalized() * move_speed
			_face_direction(direction)
	else:
		_follow_player()

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


func _follow_player() -> void:
	if player == null:
		velocity = Vector2.ZERO
		return

	var desired_position: Vector2 = player.global_position + follow_offset
	var to_desired: Vector2 = desired_position - global_position

	if to_desired.length() <= follow_deadzone:
		velocity = Vector2.ZERO
	else:
		velocity = to_desired.normalized() * move_speed
		_face_direction(to_desired)


func _try_attack() -> void:
	if not can_attack or current_target == null:
		return
	can_attack = false
	is_attacking = true
	damage_dealt_this_attack = false
	attack_target = current_target
	_play_attack_animation()
	attack_timer.start()


func _on_frame_changed() -> void:
	if not is_attacking or damage_dealt_this_attack:
		return
	if anim.frame == damage_frame:
		damage_dealt_this_attack = true
		if is_instance_valid(attack_target) and attack_target.has_method("take_damage"):
			attack_target.take_damage(strength)


func _on_attack_timer_timeout() -> void:
	can_attack = true
	is_attacking = false
	attack_target = null


func _face_direction(direction: Vector2) -> void:
	if direction.length() < 0.02:
		return
	if abs(direction.x) > abs(direction.y):
		facing = "right" if direction.x > 0 else "left"
	else:
		facing = "down" if direction.y > 0 else "up"


func _play_attack_animation() -> void:
	match facing:
		"right":
			anim.flip_h = false
			anim.play(["Attack_Right_1", "Attack_Right_2"].pick_random())
			sword.play()
		"left":
			anim.flip_h = true
			sword.play()
			anim.play("Attack_Right_1")
		"down":
			anim.flip_h = false
			sword.play()
			anim.play("Attack_Down_1")
		"up":
			anim.flip_h = false
			sword.play()
			anim.play(["Attack_Up_1", "Attack_Up_2"].pick_random())


func _update_animation() -> void:
	if is_attacking:
		return

	anim.flip_h = facing == "left"
	if velocity.length() > 3.0:
		anim.play("Walk")
	else:
		anim.play("Idle")


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
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
		if minion_name == "Big Raga" and not has_revived:
			_revive()
		else:
			is_dead = true
			_death()
			
func _revive() -> void:
	has_revived = true
	current_health = max_health
	_update_health_bar()

	var tween := create_tween()
	tween.set_loops(3)
	tween.tween_property(anim, "modulate", Color(1, 1, 0.4), 0.15)
	tween.tween_property(anim, "modulate", Color.WHITE, 0.15)

func _update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health


func _death() -> void:
	set_physics_process(false)
	detection_area.monitoring = false
	anim.play("die")
	death.play()
	await anim.animation_finished
	queue_free()

func _animate_spawn(minion: Node2D, target_position: Vector2) -> void:
	minion.scale = Vector2.ZERO
	minion.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
