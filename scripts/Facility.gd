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

onready var hud = $CanvasLayer
onready var memo = $CanvasLayer/Memo
onready var memo_body = $CanvasLayer/Memo/MarginContainer/Contents/BodyText
onready var memo_button = $CanvasLayer/Memo/MarginContainer/Contents/Button
onready var queue_size = $CanvasLayer/HUD/Stats/ShiftStats/QueueSize
onready var shift_counter = $CanvasLayer/HUD/Stats/ShiftStats/ShiftCounter
onready var action_container = $CanvasLayer/HUD/Actions
onready var humans = $Humans
onready var shower = $Shower
onready var anim_player = $AnimationPlayer
onready var level_conditions = $LevelConditions
onready var door_in = $DoorIn
onready var door_out = $DoorOut

# DEBUG
onready var debug_stats = $CanvasLayer/HUD/Stats/DebugStats
onready var contamination_level = $CanvasLayer/HUD/Stats/DebugStats/ContaminationLevel
onready var population_count = $CanvasLayer/HUD/Stats/DebugStats/PopulationCount
onready var level_count = $CanvasLayer/HUD/Stats/DebugStats/CurrentLevel


func _ready():
	randomize()
	for child in action_container.get_children():
		actions.append_array(child.get_children())
	init_state()
	load_level()

#### SETUP ####
func init_state():
	debug_update_contamination()
	debug_update_population()
	for human in humans.get_children():
		human.connect("exited", self, "next_human")
		human.connect("entered", self, "human_entered")
		human.connect("dead", self, "remove_human", [human])
	
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
	shower.emitting = true
	disable_actions("SprayButton")
	clean_human()

func stop_spray():
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
		game_over()
###########################


#### ENVIRONMENT ACTIONS ####
func contaminate_human(human):
	# TODO make this make sense
	human.contaminate(
		Globals.get_contamination_chance(contamination_percent),
		Globals.base_values["spread_rate"]
	)

func spread_contamination():
	if contamination_percent:
		for human in humans.get_children():
			contaminate_human(human)
	recalculate_contamination()
	debug_update_contamination()

func check_malfunction():
	if rand_range(0.4, 1.0) < contamination_percent:
		anim_player.play("Flicker")
#############################


#### SHIFT MANAGEMENT ####
func shift_timeout():
	disable_actions()
	shower.emitting = false
	for i in range(human_index, human_queue.size()):
		var human : Human = human_queue[i]
		print(human.name)
		contaminate_human(human)
	end_shift()

func end_shift():
	anim_player.stop()
	
	var review_data = {
		"Shift": shift_count,
		"Shift time": "",
		"Workers processed": min(human_index + 1, human_queue.size()),
	}
	# TODO replace with memo system
	current_level.display_review(review_data)
	current_level.level_complete = level_conditions.check_level_complete()

	spread_contamination()

func start_shift():
	shift_count += 1
	update_shift()
	
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

	var level_script = Globals.level_data[level_index].get("script_name", "BaseLevel")
	level_conditions.set_script(load("res://scripts/levels/%s.gd" % level_script))

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
		game_over()
		return

	load_level()

func set_level_actions(hide_actions):
	for action in actions:
		action.visible = true
		for hide_action in hide_actions:
			if hide_action in action.name:
				action.visible = false

func game_over():
	memo_body.text = Globals.game_over_text
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
