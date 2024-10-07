extends Node2D

export var level_scene : PackedScene
export var human_obj : PackedScene
export var debug_level : int = 0
export var room_center_pos : Vector2 = Vector2.ZERO

var contamination_percent : float = 0.0
var population : int = 0

var current_level : Control = null
var level_index = 0
var human_queue : Array = []
var human_index = 0
var actions : Array = []
var shift_count = 0
var fluid_percent = 100
var malfunction_shift = false

onready var hud = $CanvasLayer/LevelContainer
onready var memo = $CanvasLayer/Memo
onready var memo_body = $CanvasLayer/Memo/MarginContainer/Contents/BodyText
onready var memo_button = $CanvasLayer/Memo/MarginContainer/Contents/Button
onready var queue_size = $CanvasLayer/HUD/Stats/ShiftStats/QueueSize
onready var action_container = $CanvasLayer/HUD/Actions
onready var spray_button = $CanvasLayer/HUD/Actions/Row1/SprayButton
onready var fluid_meter = $CanvasLayer/HUD/FluidMeter
onready var humans = $Humans
onready var shower = $Shower
onready var anim_player = $AnimationPlayer
onready var level_conditions = $LevelConditions
onready var door_in = $DoorIn
onready var door_out = $DoorOut
onready var tween = $Tween
onready var aberration = $CanvasLayer/Aberration
onready var inner_contam = $CanvasLayer/Contaminants

# DEBUG
onready var debug_stats = $CanvasLayer/HUD/Stats/DebugStats
onready var contamination_level = $CanvasLayer/HUD/Stats/DebugStats/ContaminationLevel
onready var population_count = $CanvasLayer/HUD/Stats/DebugStats/PopulationCount
onready var level_count = $CanvasLayer/HUD/Stats/DebugStats/CurrentLevel
onready var shift_counter = $CanvasLayer/HUD/Stats/DebugStats/ShiftCounter


func _ready():
	randomize()
	for child in action_container.get_children():
		actions.append_array(child.get_children())
	init_state()
	load_level()


#### SETUP ####
func init_state():
	add_human_batch()
	debug_update_contamination()
	
	if OS.is_debug_build():
		level_index = debug_level
		debug_stats.visible = true
	else:
		debug_stats.visible = false
###############


#### PLAYER ACTIONS ####
func accept_human():
	disable_actions()
	exit_human()

func reject_human():
	disable_actions()
	incinerate_human()

func spray_human():
	if fluid_meter.visible:
		var time_to_empty = Globals.base_values["fluid_capacity"] * fluid_meter.value / 100
		tween.interpolate_property(fluid_meter, "value", fluid_meter.value, 0, time_to_empty)
		tween.interpolate_callback(self, time_to_empty, "disable_spray")
		tween.start()
	shower.emitting = true
	disable_actions("SprayButton")
	clean_human()

func disable_spray():
	spray_button.disabled = true
	stop_spray()

func stop_spray():
	tween.stop_all()
	shower.emitting = false
	stop_clean()
	enable_actions()
########################


#### WORKER MANAGEMENT ####
func reset_humans():
	human_queue = humans.get_children()
	for human in human_queue:
		human.reset()
	human_index = 0
	update_queue_size(human_queue.size())

func next_human():
	door_out.visible = true
	human_index += 1
	if human_index >= human_queue.size():
		end_shift()
		return
	enter_human()

func enter_human():
	var human : Human = human_queue[human_index]
	contaminate_human(human)
	door_in.visible = false
	human.enter()

func exit_human():
	var human : Human = human_queue[human_index]
	door_out.visible = false
	human.exit()

func incinerate_human():
	var human : Human = human_queue[human_index]
	human.incinerate()

func clean_human():
	var human : Human = human_queue[human_index]
	human.clean()
	
func stop_clean():
	var human : Human = human_queue[human_index]
	human.stop_clean()

func human_entered():
	door_in.visible = true
	update_queue_size()
	enable_actions()

func remove_human(human):
	humans.remove_child(human)
	human.queue_free()
	debug_update_population()
	if humans.get_child_count() > 0:
		next_human()
	else:
		game_over("humans_dead")

func add_human_batch():
	for i in range(Globals.base_values.get("worker_batch_size")):
			add_human()
	human_queue = humans.get_children()
	debug_update_population()

func add_human():
	var human = human_obj.instance()
	human.connect("exited", self, "next_human")
	human.connect("entered", self, "human_entered")
	human.connect("dead", self, "remove_human", [human])
	humans.add_child(human)
###########################


#### ENVIRONMENT ACTIONS ####
func contaminate_human(human, chance=Globals.base_values["contamination_chance"]):
	human.contaminate(
		chance,
		Globals.base_values["growth_rate"]
	)

func spread_contamination():
	if contamination_percent:
		for human in humans.get_children():
			if human.contamination_percent <= 0:
				contaminate_human(human, contamination_percent)
	recalculate_contamination()

func check_malfunction():
	if not malfunction_shift:
		return
	if rand_range(0, 1.0) < contamination_percent:
		anim_player.play("Flicker")

func display_sanity():
	if contamination_percent <= 0:
		aberration.stop()
		inner_contam.emitting = false
		return
		
	aberration.set_spread(contamination_percent)
	inner_contam.emitting = true
	inner_contam.amount = 30 * contamination_percent
#############################


#### SHIFT MANAGEMENT ####
func shift_timeout():
	disable_actions()
	shower.emitting = false
	for i in range(human_index, human_queue.size()):
		var human : Human = human_queue[i]
		contaminate_human(human)
	end_shift(true)

func end_shift(timeout=false):
	malfunction_shift = false
	anim_player.stop()
	anim_player.set_current_animation("Tick")
	anim_player.seek(0)
	recalculate_contamination()
	
	var workers_processed = human_index
	var review_data = {
		"Time taken": "",
		"Workers processed": workers_processed,
	}
	if timeout:
		review_data["Unprocessed workers"] = human_queue.size() - workers_processed
	if fluid_meter.visible:
		review_data["Fluid used"] = "%d%%" % (100 - fluid_meter.value)
	malfunction_shift = contamination_percent >= Globals.base_values["malfunction_threshold"]

	current_level.display_review(review_data, shift_count + 1, timeout, malfunction_shift)
	current_level.level_complete = level_conditions.check_level_complete()

	spread_contamination()

func start_shift():
	shift_count += 1
	update_shift()
	display_sanity()
	
	if shift_count % Globals.base_values.get("new_worker_interval") == 0:
		add_human_batch()
		recalculate_contamination()
	
	fluid_meter.value = 100
	if malfunction_shift:
		anim_player.play("Tick")
	
	reset_humans()
	enter_human()
##########################


#### LEVEL MANAGEMENT ####
func load_level():
	current_level = level_scene.instance()
	hud.call_deferred("add_child", current_level)
	current_level.connect("shift_timeout", self, "shift_timeout")
	current_level.connect("setup_complete", self, "start_shift")
	current_level.connect("tree_exited", self, "next_level")
	current_level.connect("ready", self, "display_memo")

	var level_data = Globals.level_data[level_index]
	var level_script = level_data.get("script_name", "BaseLevel")
	level_conditions.set_script(load("res://scripts/levels/%s.gd" % level_script))
	if level_data.get("fluid_meter"):
		fluid_meter.visible = true
	else:
		fluid_meter.visible = false

	debug_update_level_count()

func display_memo():
	memo_body.text = Globals.level_data[level_index].get("memo_text", "")
	memo.visible = true

func setup_level():
	memo.visible = false
	var level_data = Globals.level_data[level_index]
	set_level_actions(level_data.get("hide_actions", []))
	current_level.setup(level_data.get("shift_length", 0))

func next_level():
	level_index += 1
	if level_index >= Globals.level_data.size():
		game_over("complete")
		return

	load_level()

func set_level_actions(hide_actions):
	for action in actions:
		action.visible = true
		for hide_action in hide_actions:
			if hide_action in action.name:
				action.visible = false

func game_over(reason):
	var end_report = [
		Globals.game_over_text[reason],
		"\nShifts completed: %d" % shift_count,
	]
	if reason != "humans_dead":
		end_report.append_array([
			"Final population: %d" % population,
			"Contamination: %.1f%%" % (contamination_percent * 100),
		])
	memo_body.text = '\n'.join(end_report)
	memo_button.text = "Replay"
	memo_button.disconnect("pressed", self, "setup_level")
	memo_button.connect("pressed", get_tree(), "reload_current_scene")
	memo.visible = true
##########################


#### UTILS ####
func disable_actions(exclude=null):
	for action in actions:
		if exclude and action.name == exclude:
			continue
		(action as Button).disabled = true

func enable_actions():
	for action in actions:
		if "Spray" in action.name and fluid_meter.value == 0:
			continue
		(action as Button).disabled = false

func recalculate_contamination():
	var total_contam = 0
	var valid_humans = 0
	for human in humans.get_children():
		if is_instance_valid(human):
			valid_humans += 1
			total_contam += human.contamination_percent
	if valid_humans:
		contamination_percent = total_contam / valid_humans
	else:
		contamination_percent = 0

	debug_update_contamination()

func debug_update_contamination():
	var display_format = "Contamination: %.1f%%"
	contamination_level.text = display_format % (contamination_percent * 100)

func debug_update_population():
	population = humans.get_child_count()
	var display_format = "Population: %d"
	population_count.text = display_format % population

func debug_update_level_count():
	var display_format = "Level: %d"
	level_count.text = display_format % level_index

func update_queue_size(set_size=0):
	var display_format = "Worker Queue: %s"
	var current_queue = human_queue.size() - (human_index + 1)
	if set_size:
		current_queue = set_size
	queue_size.text = display_format % (current_queue)
	
func update_shift():
	var display_format = "Shift: %s"
	shift_counter.text = display_format % shift_count
###############
