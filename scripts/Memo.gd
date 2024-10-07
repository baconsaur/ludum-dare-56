extends Panel

onready var beep = $Beep


func play_beep():
	if visible:
		beep.play()
