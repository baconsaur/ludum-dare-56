extends BaseLevel


func check_level_complete():
	return get_parent().failed_shifts > 0
