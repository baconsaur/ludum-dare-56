class_name Human
extends Node2D

signal entered
signal exited
signal dead

export var spawn_pos : Vector2 = Vector2(376, 0)
export var center_pos : Vector2 = Vector2.ZERO
export var exit_pos : Vector2 = Vector2(-376, 0)
export var move_duration : float = 1
export var max_particles : int = 10

var contamination_percent : float = 0.0

onready var tween : Tween = $Tween
onready var contamination : CPUParticles2D = $Contamination


func _ready():
	randomize()

func reset():
	position = spawn_pos

func decontaminate():
	contamination_percent = 0
	contamination.emitting = false

func contaminate(probability, growth_rate):
	if contamination_percent:
		contamination_percent = clamp(contamination_percent + growth_rate, 0, 1)
	elif rand_range(0.0, 1.0) < probability:
		contamination_percent = growth_rate
		contamination.emitting = true

	if not contamination_percent:
		return

	var particle_count = round(max_particles * contamination_percent)
	contamination.amount = clamp(particle_count, 1, max_particles)

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
