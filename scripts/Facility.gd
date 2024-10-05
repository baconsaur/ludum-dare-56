extends Node2D

export(Array, PackedScene) var levels = []
export var debug_level : int = 0
export var room_center_pos : Vector2 = Vector2.ZERO

var contamination_percent : float = 0.0
var population : int = 0

var current_level : Node2D = null
var current_level_scene : PackedScene = null
var human_queue : Array = []
var human_index = 0

onready var contamination_level = $CanvasLayer/HUD/Stats/ContaminationLevel
onready var population_count = $CanvasLayer/HUD/Stats/PopulationCount
onready var actions = $CanvasLayer/HUD/Actions
onready var humans = $Humans


func _ready():
	update_population()
	if OS.is_debug_build() and debug_level:
		load_level(levels[debug_level])
	else:
		next_level()

func next_human():
	human_index += 1
	if human_index >= human_queue.size():
		next_level()
		return
	enter_human()

func exit_human():
	disable_actions()
	var human : Human = human_queue[human_index]
	human.connect("exited", self, "next_human")
	human.exit()

func enter_human():
	var human : Human = human_queue[human_index]
	human.connect("entered", self, "enable_actions")
	human.enter()

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

func contamination_percent():
	var display_format = "Contamination: %.1f%%"
	contamination_level.text = display_format % contamination_percent

func update_population():
	population = humans.get_child_count()
	var display_format = "Population: %d"
	population_count.text = display_format % population

func next_level():
	if levels.empty():
		return

	var level_scene = levels.pop_front()
	load_level(level_scene)

func restart_level():
	load_level(current_level_scene)

func load_level(level):
	current_level_scene = level
	if current_level:
		current_level.queue_free()
	current_level = current_level_scene.instance()
	add_child(current_level)
	reset_humans()

func reset_humans():
	human_queue = humans.get_children()
	for human in human_queue:
		human.reset()
	human_index = 0
	enter_human()
