extends CanvasLayer 

@onready var health_bar: ProgressBar = $HealthBar
@onready var darken_overlay: ColorRect = $HealthBar/Darken

@export var max_darken_alpha: float = 0.7

var player: Node = null


func _ready() -> void:
	darken_overlay.color = Color.DARK_RED
	darken_overlay.modulate.a = 0.0

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		player.health_changed.connect(_on_health_changed)
		_on_health_changed(player.current_health, player.max_health)


func _on_health_changed(current: float, max_health: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = current

	var health_ratio: float = current / max_health
	darken_overlay.modulate.a = (1.0 - health_ratio) * max_darken_alpha
