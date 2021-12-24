extends Node2D

func _ready():
	get_node("Port").set_text(str(network.port))


func _on_back():
	events.trigger("screen_change", "menus/lan/lan_races_menu")

func _on_start():
	events.trigger("screen_change", "menus/lan/server_lobby")

func _on_port_changed( text ):
	if text.is_valid_integer():
		var port = text.to_int()
		if port > 1024 and port < 65536:
			network.port = port
