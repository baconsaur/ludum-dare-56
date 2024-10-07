class_name Level
extends Control

signal shift_timeout
signal setup_complete

var level_complete = false
var shift_length = 0
var elapsed_time = 0
var alert_time = 10
var alarm_played = false

onready var time_label = $MarginContainer/LevelTime
onready var time_alarm = $TimeAlarm
onready var anim_player = $AnimationPlayer
onready var shift_review = $LevelEnd
onready var report_text = $LevelEnd/MarginContainer/Contents/BodyText
onready var shift_time = shift_length


func _ready():
	time_label.visible = false
	shift_review.visible = false

func setup(shift_length_value):
	shift_length = shift_length_value
	reset_shift()

func _process(delta):
	elapsed_time += delta
	if shift_time <= 0:
		return

	shift_time -= delta
	update_time()
	if not alarm_played and shift_time <= alert_time:
		anim_player.play("TimeAlert")
		alarm_played = true
	if shift_length and shift_time <= 0:
		emit_signal("shift_timeout")

func reset_shift():
	if level_complete:
		queue_free()
		return

	if shift_length:
		shift_time = shift_length
		update_time()
		time_label.visible = true
	
	elapsed_time = 0
	alarm_played = false
	shift_review.visible = false
	emit_signal("setup_complete")

func display_review(review_data, next_shift, timeout, malfunction):
	alarm_played = true
	anim_player.play("RESET")
	review_data["Time taken"] = format_seconds(elapsed_time)
	var review_lines = ["Performance Review:"]

	for key in review_data:
		review_lines.append("%s: %s" % [key, review_data[key]])

	var alerts = ["\nAlerts:"]
	if next_shift % Globals.base_values.get("new_worker_interval") == 0:
		alerts.append("%s new workers have arrived" % Globals.base_values.get("worker_batch_size"))
	
	if malfunction:
		alerts.append("reports of system malfunctions due to high contaminant levels")
	
	if alerts.size() > 1:
		review_lines.append("\n".join(alerts))
	
	report_text.text = "\n".join(review_lines)
	
	time_label.visible = false
	shift_review.visible = true

func update_time():
	if not shift_length:
		return
	var display_format = "Shift time: %s"
	time_label.text = display_format % format_seconds(shift_time)

func format_seconds(total_seconds):
	var seconds = clamp(fmod(total_seconds , 60.0), 0, 60)
	var minutes = int(total_seconds / 60.0) % 60
	return "%d:%02.f" % [minutes, seconds]
