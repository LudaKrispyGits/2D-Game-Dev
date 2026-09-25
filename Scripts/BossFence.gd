extends Node

@export var boss_fence_path: NodePath
@export var boss_prompt_label_path: NodePath
@export var boss_prompt_text: String = "Proceed to Boss Fight"
@export var check_interval: float = .3

@onready var boss_fence: Node = get_node(boss_fence_path) if boss_fence_path else null
@onready var boss_prompt_label: Label = get_node(boss_prompt_label_path) if boss_prompt_label_path else null

var fence_removed: bool = false


func _ready() -> void:
	if boss_prompt_label:
		boss_prompt_label.visible = false

	if boss_fence == null:
		push_warning("BossFenceController: boss_fence_path not set or invalid")
		return

	var check_timer := Timer.new()
	check_timer.wait_time = check_interval
	check_timer.one_shot = false
	add_child(check_timer)
	check_timer.timeout.connect(_check_spawners)
	check_timer.start()

	_check_spawners()


func _check_spawners() -> void:
	if fence_removed:
		return

	var spawners := get_tree().get_nodes_in_group("Spawner")
	if spawners.is_empty():
		fence_removed = true
		boss_fence.queue_free()

		if boss_prompt_label:
			boss_prompt_label.text = boss_prompt_text
			boss_prompt_label.visible = true
