extends BaseLevel


func check_level_complete():
	return get_parent().contamination_percent >= 0.25
