class_name Human
extends Node2D

signal entered
signal cleaned
signal exited
signal dead

export var spawn_pos : Vector2 = Vector2(180, 0)
export var center_pos : Vector2 = Vector2.ZERO
export var exit_pos : Vector2 = Vector2(-180, 0)
export var move_duration : float = 1
export var max_move_duration : float = 3
export var incinerate_time : float = 0.5
export var max_particles : int = 10

var contamination_percent : float = 0.0

onready var sprite : Sprite = $Sprite
onready var tween : Tween = $Tween
onready var contamination : CPUParticles2D = $Contamination
onready var combustion : CPUParticles2D = $Combustion


func _ready():
	randomize()
	contamination.emitting = false

func reset():
	position = spawn_pos

func decontaminate(value):
	if contamination_percent <= 0:
		return
	contamination_percent = value
	update_particles()

func contaminate(probability, growth_rate):
	if contamination_percent > 0:
		contamination_percent += growth_rate * (1 + contamination_percent)
	elif rand_range(0.0, 1.0) >= probability:
		contamination_percent = growth_rate
		contamination.emitting = true
	else:
		return

	update_particles()

func interpolate(a, b, t):
	return a + (b - a) * t

func easeInQuart(x):
	return x * x

func enter():
	call_deferred("move_pos", spawn_pos, center_pos, "entered")

func exit():
	move_pos(center_pos, exit_pos, "exited")

func update_particles():
	if contamination_percent <= 0:
		contamination.emitting = false
		return

	var particle_count = int(round(max_particles * contamination_percent))
	contamination.amount = clamp(particle_count, 1, max_particles)

func incinerate():
	combustion.emitting = true
	contamination.emitting = false
	tween.interpolate_property(sprite, "modulate", Color.white, Color(0, 0, 0, 0), incinerate_time, Tween.TRANS_QUINT, Tween.EASE_IN)
	tween.interpolate_callback(self, move_duration, "emit_signal", "dead")
	tween.start()

func clean(clean_rate=0.1):
	var full_clean_time = contamination_percent / clean_rate
	tween.interpolate_method(self, "decontaminate", contamination_percent, 0, full_clean_time)
	tween.start()

func stop_clean():
	tween.stop(self)

func move_pos(start, end, callback_signal):
	var move_speed = interpolate(move_duration, max_move_duration, contamination_percent)
	tween.interpolate_property(self, "position", start, end, move_speed, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.interpolate_callback(self, move_speed, "emit_signal", callback_signal)
	tween.start()
