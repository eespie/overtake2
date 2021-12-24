extends Node2D


var cars = [ 5, 1, 2, 3, 4 ]
var car_colors = [ "Blue", "Red", "Green", "Yellow" ]
var car_color
var car_index
var driver_index
var driver_name
var current_player

onready var node_cars = get_node("Cars")
onready var node_colors = get_node("Colors")

func _ready():
	current_player = race_mgr.current_player
	car_color = current_player.car_color
	driver_name = current_player.driver_name
	driver_index = current_player.driver_index
	car_index = current_player.car_index
	get_node("Driver").set_text(driver_name)
	if network.activated:
		get_node("Back").set_text("Next")
	redraw()
	
func redraw():
	node_cars.clear()
	for i in cars:
		node_cars.add_icon_item(load(str("res://Asset/PNG/Cars/car_",car_color.to_lower(),"_small_",i,".png")))
	node_cars.select(car_index)
	for c in car_colors:
		if c == car_color.capitalize():
			get_node(str("Colors/",c,"/Radio")).set("pressed", true)
		else:
			get_node(str("Colors/",c,"/Radio")).set("pressed", false)

func _on_Car_selected( index ):
	car_index = index

func _on_Blue():
	car_color = "Blue"
	redraw()

func _on_Red():
	car_color = "Red"
	redraw()

func _on_Green():
	car_color = "Green"
	redraw()

func _on_Yellow():
	car_color = "Yellow"
	redraw()

func _on_driver_name_changed( text ):
	driver_name = text

func _on_Back():
	race_mgr.update_player(driver_index, driver_name, car_index, car_color)
	if network.activated:
		if network.server:
			events.trigger("screen_change", "menus/lan/select_circuit_menu")
		else:
			events.trigger("screen_change", "menus/lan/client_config_menu")
	else:
		events.trigger("screen_change", "menus/race_main_menu")
