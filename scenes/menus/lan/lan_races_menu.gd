extends Node2D

func _ready():
	race_mgr.lan_init()

func _on_client():
	network.client_init()
	events.trigger("screen_change", "menus/car_selection_menu")

func _on_server():
	network.server_init()
	events.trigger("screen_change", "menus/car_selection_menu")

func _on_back():
	events.trigger("screen_change", "menus/main_menu")

