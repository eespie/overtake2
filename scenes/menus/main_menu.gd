extends Node2D


func _ready():
	pass

func _on_Standalone():
	race_mgr.local_init()
	events.trigger("screen_change", "menus/race_main_menu")

func _on_LAN():
	events.trigger("screen_change", "menus/lan/lan_races_menu")
