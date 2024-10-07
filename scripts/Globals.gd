extends Node

const base_values = {
	"contamination_chance": 0.6,
	"growth_rate": 0.15,
	"clean_rate": 0.15,
	"new_worker_interval": 3,
	"worker_batch_size": 3,
	"fluid_capacity": 10, # seconds to empty
	"malfunction_threshold": 0.25,
}

const level_data = [
	{
		"hide_actions": ["Reject"],
		"script_name": "Level1",
		"memo_text": "Yeyland-Wutani wecomes you to Fiorina 616!\n\nDecontaminating the workers when they return from the work site is a very important job.\n\nIf you spot any unwanted critters, spray them down before allowing them to reenter the facility.\n\nGood luck on your first shift!",
	},
	{
		"hide_actions": ["Reject"],
		"shift_length": 75,
		"script_name": "Level2",
		"memo_text": "Congratulations on completing your first shift!\n\nTo help us maximize the efficiency of our operation, a timer has been added to your station.\n\nPlease make sure to complete your work within the time limit.",
	},
	{
		"shift_length": 60,
		"script_name": "Level3",
		"memo_text": "Your station has been upgraded with a new feature!\n\nTo help you succeed at reaching your new time goal, you may reject workers who require excessive use of resources.",
	},
	{
		"shift_length": 60,
		"script_name": "Level4",
		"memo_text": "Due to supply chain issues, decontamination fluid will be rationed until further notice.\n\nPlease monitor the level of fluid carefully and avoid non-essential use.",
		"fluid_meter": true,
	},
	{
		"shift_length": 60,
		"script_name": "Level5",
		"memo_text": "??????",
		"fluid_meter": true,
	},
]

const game_over_text = {
	"complete": "good jorb",
	"humans_dead": "All the workers are dead. Yeyland-Wutani no longer requires your services.",
	"fired": "you suck at this",
}
