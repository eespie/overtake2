extends Node2D

var next_scene = "menus/main_menu"

var elapsed = 0

func _ready():
	set_process(true)

func _process(delta):
	elapsed += delta
	if elapsed > 3:
		events.trigger("screen_change", next_scene)

func _on_pressed():
	events.trigger("screen_change", next_scene)
