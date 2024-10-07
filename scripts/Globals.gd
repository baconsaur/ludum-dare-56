extends Node

var base_values = {
	"contamination_chance": 0.6,
	"growth_rate": 0.15,
	"clean_rate": 0.2,
	"new_worker_interval": 3,
	"worker_batch_size": 5,
	"fluid_capacity": 30, # seconds to empty
	"malfunction_threshold": 0.25,
	"minimum_efficiency": 0.6,
	"worker_revenue": 10,
	"worker_upkeep": 7,
	"max_failed_shifts": 5,
}

var level_data = [
	{
		"hide_actions": ["Reject"],
		"script_name": "Level1",
		"memo_text": "Yeyland-Wutani wecomes you to Fiorina 616!\n\nDecontaminating the workers when they return from the work site is a very important job.\n\nIf you spot any unwanted critters, spray them down before allowing them to reenter the facility.\n\nGood luck on your first shift!",
	},
	{
		"hide_actions": ["Reject"],
		"shift_length": 50,
		"script_name": "Level2",
		"memo_text": "Congratulations on completing your first shift!\n\nTo help us maximize the efficiency of our operation, a timer has been added to your station.\n\nPlease make sure to complete your work within the time limit.",
	},
	{
		"shift_length": 75,
		"script_name": "Level3",
		"memo_text": "Your station has been upgraded with a new feature!\n\nTo help you succeed, you may reject workers who will be a burden on the system. Please make sure to meet your new revenue goal of 2000 credits per shift.",
		"revenue_goal": 2000,
	},
	{
		"shift_length": 80,
		"script_name": "Level4",
		"memo_text": "Due to budget cuts, decontamination fluid will be rationed until further notice.\n\nPlease monitor the level of fluid carefully and avoid non-essential use.",
		"fluid_meter": true,
		"revenue_goal": 2400,
	},
]

var game_over_text = {
	"complete": "Congratulations, you earned a promotion to a much nicer facility! Say goodbye to Fiorina 616.",
	"humans_dead": "All the workers are dead. Yeyland-Wutani no longer requires your services.",
	"fired": "Due to poor performance, Yeyland-Wutani no longer requires your services.",
}
