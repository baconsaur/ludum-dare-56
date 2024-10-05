class_name Level
extends Control

signal level_timeout

export var time_limit : float = 90

var contaminated
var complete = false

onready var time_label = $LevelTime
onready var level_time = time_limit


func _ready():
	if time_limit:
		time_label.visible = true

func _process(delta):
	if complete:
		return
	level_time -= delta
	update_time()
	if time_limit and level_time <= 0:
		complete = true
		emit_signal("level_timeout")

func update_time():
	if not time_limit:
		return
	var display_format = "Time remaining: %s"
	time_label.text = display_format % format_seconds(level_time)

func format_seconds(total_seconds):
	var seconds = clamp(fmod(total_seconds , 60.0), 0, 60)
	var minutes = int(total_seconds / 60.0) % 60
	return "%d:%02.f" % [minutes, seconds]
