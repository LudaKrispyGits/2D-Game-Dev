extends Node

@export var win_screen_scene: PackedScene
@export var check_interval: float = 1.0

var win_triggered: bool = false


func _ready() -> void:
	var check_timer := Timer.new()
	check_timer.wait_time = check_interval
	check_timer.one_shot = false
	add_child(check_timer)
	check_timer.timeout.connect(_check_win_condition)
	check_timer.start()


func _check_win_condition() -> void:
	if win_triggered:
		return

	var enemies := get_tree().get_nodes_in_group("enemy")
	var spawners := get_tree().get_nodes_in_group("Spawner")

	if enemies.is_empty() and spawners.is_empty():
		win_triggered = true
		_show_win_screen()


func _show_win_screen() -> void:
	if win_screen_scene == null:
		push_warning("WinChecker: win_screen_scene not assigned")
		return

	var win_screen = win_screen_scene.instantiate()
	get_tree().root.add_child(win_screen)
