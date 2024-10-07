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
export var max_move_duration : float = 4
export var incinerate_time : float = 0.5
export var max_particles : int = 10

var contamination_percent : float = 0.0

onready var sprite : Sprite = $Sprite
onready var tween : Tween = $Tween
onready var contamination : CPUParticles2D = $Contamination
onready var combustion : CPUParticles2D = $Combustion
onready var burn_sound = $Burn
onready var debug_label = $Debug


func _ready():
	randomize()
	contamination.emitting = false
#	debug_label.visible = OS.is_debug_build()

func reset():
	position = spawn_pos
#	if OS.is_debug_build():
#		update_contamination(Globals.base_values.get("initial_contamination", 0))

func contaminate(probability, growth_rate):
	if contamination_percent <= 0 and rand_range(0.0, 1.0) >= probability:
		return
	update_contamination(growth_rate)

func update_contamination(increment):
	contamination_percent = clamp(contamination_percent + increment, 0, 1)
	contamination.emitting = true
	display_contamination()

func interpolate(a, b, t):
	return a + (b - a) * t

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
	burn_sound.play()
	combustion.emitting = true
	contamination.emitting = false
	tween.interpolate_property(sprite, "modulate", Color.white, Color(0, 0, 0, 0), incinerate_time, Tween.TRANS_QUINT, Tween.EASE_IN)
	tween.interpolate_callback(self, move_duration, "emit_signal", "dead")
	tween.start()

func clean(clean_rate=0.1):
	var full_clean_time = contamination_percent / clean_rate
	tween.interpolate_property(self, "contamination_percent", contamination_percent, 0, full_clean_time)
	tween.connect("tween_step", self, "display_contamination")
	tween.start()

func stop_clean():
	tween.stop(self)
	tween.disconnect("tween_step", self, "display_contamination")

func display_contamination(_x=null, _y=null, _z=null, _w=null):
#	debug_label.text = "%.1f%%" % (contamination_percent * 100)
	update_particles()

func move_pos(start, end, callback_signal):
	var move_speed = interpolate(move_duration, max_move_duration, contamination_percent)
	tween.interpolate_property(self, "position", start, end, move_speed, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.interpolate_callback(self, move_speed, "emit_signal", callback_signal)
	tween.start()
