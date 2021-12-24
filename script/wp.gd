extends Area2D

export(int) var index = 0

func _on_WP_body_entered( car ):
	events.trigger("WP", index, car)


func _on_WPJocker_body_entered( car ):
	events.trigger("WP_jocker", car)
