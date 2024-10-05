extends Node2D

export(Array, PackedScene) var levels = []
export var debug_level : int = 0
export var room_center_pos : Vector2 = Vector2.ZERO
export var contamination_chance = 0.6
export var max_contamination_chance = 0.9
export var growth_rate = 0.333
export var clean_rate = 0.333

var contamination_percent : float = 0.0
var population : int = 0

var current_level : Control = null
var level_index = 0
var human_queue : Array = []
var human_index = 0

onready var hud = $CanvasLayer/HUD
onready var contamination_level = $CanvasLayer/HUD/Stats/ContaminationLevel
onready var population_count = $CanvasLayer/HUD/Stats/PopulationCount
onready var actions = $CanvasLayer/HUD/Actions
onready var humans = $Humans
onready var shower = $Shower


func _ready():
	init_state()
	enter_human()

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

func disable_actions(exclude=null):
	for action in actions.get_children():
		if exclude and action.name == exclude:
			continue
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
		human.connect("dead", self, "remove_human", [human])
	
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
		hud.remove_child(current_level)
		current_level.queue_free()
	current_level = level.instance()
	hud.add_child(current_level)
	current_level.connect("level_timeout", self, "level_timeout")
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
	var human : Human = human_queue[human_index]
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

func remove_human(human):
	humans.remove_child(human)
	human.queue_free()
	update_population()
	if humans.get_child_count() > 0:
		next_human()
	else:
		game_over()

func contaminate_human(human):
	# TODO make this make sense
	human.contaminate(clamp(contamination_percent + contamination_chance, 0, max_contamination_chance), growth_rate)

func recalculate_contamination():
	var total_contam = 0
	var valid_humans = 0
	for human in humans.get_children():
		if is_instance_valid(human):
			valid_humans += 1
			total_contam += human.contamination_percent
	if valid_humans:
		contamination_percent = total_contam / valid_humans * 100
	else:
		contamination_percent = 0
	update_contamination()

func level_timeout():
	disable_actions()
	for i in range(human_index, human_queue.size()):
		var human : Human = human_queue[i]
		print(human.name)
		contaminate_human(human)
	recalculate_contamination()
	end_level()

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
		game_over()
		return

	load_level(levels[level_index])
	enter_human()

func game_over():
	print("Game over")
