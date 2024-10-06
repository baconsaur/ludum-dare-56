class_name Level
extends Control

signal level_timeout
signal set_actions

export var time_limit : float = 90
export(Array, String) var hide_actions

var contaminated
var complete = false

onready var time_label = $LevelTime
onready var end_popup = $LevelEnd
onready var report_text = $LevelEnd/MarginContainer/VBoxContainer/BodyText
onready var level_time = time_limit


func _ready():
	emit_signal("set_actions", hide_actions)
	end_popup.visible = false
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

func display_review(humans_processed):
	var display_format = report_text.text
	report_text.text = display_format % [format_seconds(time_limit - level_time), humans_processed]
	
	time_label.visible = false
	end_popup.visible = true

func next_level():
	queue_free()

func update_time():
	if not time_limit:
		return
	var display_format = "Time: %s"
	time_label.text = display_format % format_seconds(level_time)

func format_seconds(total_seconds):
	var seconds = clamp(fmod(total_seconds , 60.0), 0, 60)
	var minutes = int(total_seconds / 60.0) % 60
	return "%d:%02.f" % [minutes, seconds]
