extends Node

signal resources_changed(gold: int, wood: int)

var gold: int = 50
var wood: int = 50


func add_gold(amount: int) -> void:
	gold += amount
	resources_changed.emit(gold, wood)


func add_wood(amount: int) -> void:
	wood += amount
	resources_changed.emit(gold, wood)


func spend_resources(gold_cost: int, wood_cost: int) -> bool:
	if gold < gold_cost or wood < wood_cost:
		print("Not enough gold or wood")
		return false
	gold -= gold_cost
	wood -= wood_cost
	resources_changed.emit(gold, wood)
	return true

func reset() -> void:
	gold = gold
	wood = wood
	resources_changed.emit(gold, wood)
