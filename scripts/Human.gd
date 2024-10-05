class_name Human
extends Node2D

signal entered
signal exited
signal dead

export var spawn_pos : Vector2 = Vector2(376, 0)
export var center_pos : Vector2 = Vector2.ZERO
export var exit_pos : Vector2 = Vector2(-376, 0)
export var move_duration : float = 1

onready var tween : Tween = $Tween


func reset():
	position = spawn_pos

func enter():
	move_pos(spawn_pos, center_pos, "entered")

func exit():
	move_pos(center_pos, exit_pos, "exited")

func die():
	pass
	# TODO

func move_pos(start, end, callback_signal):
	var tween = get_node("Tween")
	tween.interpolate_property(self, "position", start, end, move_duration)
	tween.interpolate_callback(self, move_duration, "emit_signal", callback_signal)
	tween.start()
