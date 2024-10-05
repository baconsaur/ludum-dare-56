extends Node2D

export(Array, PackedScene) var levels = []
export var debug_level : int = 0
export var room_center_pos : Vector2 = Vector2.ZERO
export var contamination_chance = 0.6
export var max_contamination_chance = 0.9
export var growth_rate = 0.333

var contamination_percent : float = 0.0
var population : int = 0

var current_level : Node2D = null
var level_index = 0
var human_queue : Array = []
var human_index = 0

onready var contamination_level = $CanvasLayer/HUD/Stats/ContaminationLevel
onready var population_count = $CanvasLayer/HUD/Stats/PopulationCount
onready var actions = $CanvasLayer/HUD/Actions
onready var humans = $Humans


func _ready():
	init_state()
	enter_human()

#### PLAYER ACTIONS ####
func accept_human():
	print("accepted")
	exit_human()

func reject_human():
	print("rejected")
	exit_human()

func disable_actions():
	for action in actions.get_children():
		(action as Button).disabled = true

func enable_actions():
	for action in actions.get_children():
		(action as Button).disabled = false
########################

#### SETUP ####
func init_state():
	update_contamination()
	update_population()
	for human in humans.get_children():
		human.connect("exited", self, "next_human")
		human.connect("entered", self, "enable_actions")
	
	if OS.is_debug_build():
		level_index = debug_level
	load_level(levels[level_index])

func update_contamination():
	var display_format = "Contamination: %.1f%%"
	contamination_level.text = display_format % contamination_percent

func update_population():
	population = humans.get_child_count()
	var display_format = "Population: %d"
	population_count.text = display_format % population

func load_level(level):
	if current_level:
		current_level.queue_free()
	current_level = level.instance()
	add_child(current_level)
	reset_humans()

func reset_humans():
	human_queue = humans.get_children()
	for human in human_queue:
		human.reset()
	human_index = 0
###############

func next_human():
	recalculate_contamination()
	human_index += 1
	if human_index >= human_queue.size():
		end_level()
		return
	enter_human()

func enter_human():
	var human : Human = human_queue[human_index]
	contaminate_human(human)
	human.enter()

func exit_human():
	disable_actions()
	var human : Human = human_queue[human_index]
	human.exit()

func contaminate_human(human):
	# TODO make this make sense
	human.contaminate(clamp(contamination_percent + contamination_chance, 0, max_contamination_chance), growth_rate)

func recalculate_contamination():
	var total_contam = 0
	var valid_humans = 0
	for human in human_queue:
		if is_instance_valid(human):
			valid_humans += 1
			total_contam += human.contamination_percent
	print(total_contam)
	print(valid_humans)
	print(total_contam / valid_humans)
	contamination_percent = total_contam / valid_humans * 100
	update_contamination()

func end_level():
	if contamination_percent:
		# Spread
		for human in humans.get_children():
			contaminate_human(human)
		recalculate_contamination()
			
	print("Level complete")
	# TODO level report
	next_level()

func next_level():
	level_index += 1
		
	if level_index >= levels.size():
		print("Game over")
		return

	load_level(levels[level_index])
	enter_human()
