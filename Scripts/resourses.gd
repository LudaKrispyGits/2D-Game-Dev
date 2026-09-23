extends HBoxContainer

@onready var gold_label: Label = $GoldLabel
@onready var wood_label: Label = $WoodLabel

var player: Node = null

func _ready() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		GameManager.resources_changed.connect(_on_resources_changed)
		_on_resources_changed(GameManager.gold, GameManager.wood)
	else:
		push_warning("ResourceDisplay: no player found in 'player' group")

func _on_resources_changed(gold: int, wood: int) -> void:
	gold_label.text = str(gold)
	wood_label.text = str(wood)
