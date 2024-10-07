extends BaseLevel


func check_level_complete():
	var worker_interval = Globals.base_values.get("new_worker_interval")
	return get_parent().shift_count >= worker_interval * 2
