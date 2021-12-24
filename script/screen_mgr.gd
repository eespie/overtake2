
extends Node


func _ready():
	bind_events()

func bind_events():
	events.register("screen_change", self)
	
func _exit_tree():
	events.unregister_node(self)
	
func screen_change(screen):
	scene.goto_scene(str("res://scenes/", screen, ".tscn"))
