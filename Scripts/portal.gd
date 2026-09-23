extends Area2D

@export var next_level_path: String = "res://Scenes/lvl_1.tscn"
@export var check_interval: float = 1.0
@export var cleared_text: String = "Next Level"

@onready var label: Label = $Label
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var level_cleared: bool = false



func _ready() -> void:
	label.visible = true
	collision_shape.disabled = true
	monitoring = false

	body_entered.connect(_on_body_entered)

	var check_timer := Timer.new()
	check_timer.wait_time = check_interval
	check_timer.one_shot = false
	add_child(check_timer)
	check_timer.timeout.connect(_check_level_cleared)
	check_timer.start()

	_check_level_cleared()


func _check_level_cleared() -> void:
	if level_cleared:
		return

	var enemies := get_tree().get_nodes_in_group("enemy")
	var remaining: int = enemies.size() - 1
	print("Checking level cleared — enemies remaining: ", remaining)

	if remaining <= 0:
		level_cleared = true
		label.text = cleared_text
		collision_shape.disabled = false
		monitoring = true
		print("Level cleared! Portal activated.")
	else:
		label.text = "Enemies remaining: %d" % remaining


func _on_body_entered(body: Node2D) -> void:
	print("Body entered portal: ", body.name, " | level_cleared: ", level_cleared, " | in player group: ", body.is_in_group("player"))
	if not level_cleared:
		return
	if body.is_in_group("player"):
		print("Changing scene to: ", next_level_path)
		get_tree().change_scene_to_file(next_level_path)
