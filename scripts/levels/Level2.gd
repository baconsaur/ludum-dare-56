extends BaseLevel


func check_level_complete():
	return get_parent().shift_count >= Globals.base_values.get("new_worker_interval")
