class_name LevelTrigger
extends Node


func _process(delta):
	if check_conditions():
		owner.level_complete = true
		queue_free()

func check_conditions():
	return true
