extends Label


func visibility_changed():
	var tween = create_tween()
	percent_visible = 0
	tween.tween_property(self, "percent_visible", 1.0, 0.6)
