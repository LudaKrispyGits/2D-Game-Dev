extends CharacterBody2D

@export var move_speed: float = 110.0
@export var follow_offset: Vector2 = Vector2(0, 30)
@export var follow_deadzone: float = 10.0
@export var attack_range: float = 190.0
@export var attack_cooldown: float = 1.6
@export var strength: int = 2
@export var max_health: int = 10
@export var shoot_frame: int = 5
@export var arrow_scene: PackedScene
@export var arrow_spawn_offset: Vector2 = Vector2(0, -10)

@onready var death: AudioStreamPlayer2D = $Die
@onready var loose_arrow: AudioStreamPlayer2D = $"Loose Arrow"

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
var arrow_fired_this_attack: bool = false
var is_dead: bool = false
@export var possible_names: Array[String] = [
	"Darrelt", "WidowWaker", "Karrelt", "Parrelt", "Tarrelt", "Hawkeye", "Warrelt", "Zarrelt", 
	"Farrelt", "Garrelt", "Larvalt", "Jarvalt", "Harvalt", "Barvalt", "Tharrelt", "Warrelt", 
	"Sir Waltrus the 4th", "Sir Wallelt the 5th", "Charrelt", "Darrelt", "Merrelt", "Sarrelt", "Rarrelius", "Barrelius", "Harrelius", "Gerrelius", "Wherrelius", "Sir Waltimus the 6th", "Sir Waldus the 7th", "Sir Warlert the 8th", "Tiberrelt", 
	"Grarrelt", "Flarrelt", "Quarrelt", "Vorrelt", "Sorrelt", "Jarrelius", "Tharrelius", "Chorrelt", "Warrelius", "Marrelius", "Sir Walthazar the 9th", 
	"Sir Waltherelt the 10th","Rarrelt","Barrelt","Larrelt","Jarrelt","Wherelt", "Therrelt", "Sir Waltus the 3rd", "Harrelt", "Chairelt", "Gerrelt", "Evil Walter", "Dr.Walter"
	
]

var minion_name: String = ""



func _ready() -> void:
	minion_name = possible_names.pick_random() if possible_names.size() > 0 else ""
	if name_label:
		name_label.text = minion_name
	if minion_name == "WidowWaker":
		strength = 10
		max_health = 5
		move_speed = 100
		attack_cooldown = 3
		attack_range = 400
		detection_area.scale *= 1.7
		name_label.add_theme_color_override("font_color", Color.YELLOW)
	elif minion_name == "Evil Walter":
		strength = 5
		max_health = 2
		scale *= .7
		move_speed = 300
		detection_area.scale *= .7
		name_label.add_theme_color_override("font_color", Color.YELLOW)
		
	elif minion_name == "Hawkeye":
		strength = 7
		max_health = 33
		scale *= 1.3
		move_speed = 200
		detection_area.scale *= 10
		name_label.add_theme_color_override("font_color", Color.YELLOW)

	elif minion_name == "Sir Waltus the 3rd":
		strength = 1
		max_health = 30
		scale *= 2
		move_speed = 10
		detection_area.scale *= 1.5

		name_label.add_theme_color_override("font_color", Color.YELLOW)

	elif minion_name == "Dr.Walter":
		strength = 2
		max_health = 10
		move_speed = 110
		attack_cooldown = .7
		attack_range = 420
		detection_area.scale *= 2
		name_label.add_theme_color_override("font_color", Color.YELLOW)

	current_health = max_health
	
	_update_health_bar()

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		push_warning("Archer: no node in 'player' group found")

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
		push_warning("Archer couldn't find player to give gold to")


func add_wood(amount: int) -> void:
	if player and player.has_method("add_wood"):
		player.add_wood(amount)
	else:
		push_warning("Archer couldn't find player to give wood to")


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
	arrow_fired_this_attack = false
	attack_target = current_target
	_play_attack_animation()
	attack_timer.start()


func _on_frame_changed() -> void:
	if not is_attacking or arrow_fired_this_attack:
		return
	if anim.frame == shoot_frame:
		arrow_fired_this_attack = true
		_fire_arrow()


func _fire_arrow() -> void:
	if arrow_scene == null:
		push_warning("Archer: no arrow_scene assigned")
		return
	if not is_instance_valid(attack_target):
		return

	var arrow = arrow_scene.instantiate()
	get_parent().add_child(arrow)
	var spawn_pos: Vector2 = global_position + arrow_spawn_offset
	loose_arrow.play()
	arrow.launch(spawn_pos, attack_target.global_position, strength)


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
	anim.flip_h = facing == "left"
	anim.play("Attack")


func _update_animation() -> void:
	if is_attacking:
		return

	anim.flip_h = facing == "left"
	if velocity.length() > 2.0:
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
		is_dead = true
		_death()


func _update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health


func _death() -> void:
	set_physics_process(false)
	detection_area.monitoring = false
	anim.play("Die")
	death.play()

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	queue_free()
