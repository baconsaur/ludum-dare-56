extends ColorRect

var max_spread = 2.5
var variance_percent = 0.5
var min_variance = 0.1
var spread : float = 0
var period = 0.25

onready var tween = $Tween


func _ready():
	randomize()

func _process(delta):
	if tween.is_active():
		material.set_shader_param("spread", spread)

func set_spread(spread_percent):
	stop()
	var new_spread = clamp(max_spread * spread_percent, 0, 1)
	tween_effect(new_spread, spread, new_spread, 2)

func start_effect(base_spread):
	if base_spread == 0:
		stop()
		return
	var variance_mod = base_spread / max_spread
	var variance_range = variance_percent * variance_mod
	var start_value = spread
	var end_value = base_spread + rand_range(-variance_range, variance_range)
	tween_effect(base_spread, start_value, end_value, period)

func tween_effect(base, start, end, t):
	tween.interpolate_property(self, "spread", start, end, t)
	tween.interpolate_callback(self, t, "start_effect", base)
	tween.start()

func stop():
	tween.remove_all()
	material.set_shader_param("spread", 0)
