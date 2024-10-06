extends BaseLevel


func check_level_complete():
	return get_parent().shift_count > 0
