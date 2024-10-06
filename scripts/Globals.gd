extends Node

const base_values = {
	"contamination_chance": 0.6,
	"max_contamination_chance": 0.9,
	"spread_rate": 0.3,
	"clean_rate": 0.3,
}

const level_data = [
	{
		"hide_actions": ["Reject"],
		"script_name": "Level1",
		"memo_text": "asdf"
	},
	{
		"shift_length": 60,
		"script_name": "Level2",
		"memo_text": "ghjk"
	}
]

const game_over_text = "Game over lol"

func get_contamination_chance(contamination_percent):
	return clamp(contamination_percent + base_values["contamination_chance"], 0, base_values["max_contamination_chance"])
