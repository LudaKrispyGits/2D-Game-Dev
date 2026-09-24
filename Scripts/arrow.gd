extends Area2D

@export var arc_height: float = 10.0
@export var flight_time: float = 0.3

var damage: int = 2
var start_position: Vector2
var target_position: Vector2
var elapsed: float = 0.0
var has_hit: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)




func _process(delta: float) -> void:
	if has_hit:
		return

	elapsed += delta
	var t: float = clamp(elapsed / flight_time, 0.0, 1.0)

	var flat_position: Vector2 = start_position.lerp(target_position, t)
	var arc_offset: float = sin(t * PI) * arc_height
	var new_position: Vector2 = flat_position - Vector2(0, arc_offset)

	var direction: Vector2 = new_position - global_position
	if direction.length() > 0.01:
		rotation = direction.angle()

	global_position = new_position

	if t >= 1.0:
		_on_reached_target()


func launch(from: Vector2, to: Vector2, dmg: int) -> void:
	print("Arrow launched from ", from, " to ", to, " dmg: ", dmg)
	start_position = from
	target_position = to
	damage = dmg
	global_position = from


func _on_body_entered(body: Node2D) -> void:
	print("Arrow hit something: ", body.name, " groups: ", body.get_groups())
	if has_hit:
		return
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		has_hit = true
		body.take_damage(damage)
		queue_free()
	else:
		print("Body not valid target — in enemy group: ", body.is_in_group("enemy"), " has take_damage: ", body.has_method("take_damage"))


func _on_reached_target() -> void:
	print("Arrow reached target without hitting anything")
	if has_hit:
		return
	has_hit = true
	queue_free()
