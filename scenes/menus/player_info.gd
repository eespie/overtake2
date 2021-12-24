extends Control

var cars = [ 5, 1, 2, 3, 4 ]
var driver_index = 0
var driver_name = "Player"
var car_index = 1
var car_color = "Blue"
var is_new = true

onready var node_add = get_node("Add")
onready var node_remove = get_node("Remove")
onready var node_none = get_node("None")
onready var node_driver = get_node("Driver")
onready var node_car = get_node("Car")

func _ready():
	node_driver.set_text(driver_name)
	node_car.set("texture_normal", load(str("res://Asset/PNG/Cars/car_",car_color.to_lower(),"_small_",cars[car_index],".png")))
	if driver_index == 0:
		node_add.hide()
		node_remove.hide()
		node_driver.show()
		node_car.show()
		node_none.show()
	elif is_new:
		node_add.show()
		node_remove.hide()
		node_driver.hide()
		node_car.hide()
		node_none.hide()
	else:
		node_add.hide()
		node_remove.show()
		node_driver.show()
		node_car.show()
		node_none.hide()

func _on_Add():
	node_add.hide()
	node_remove.show()
	node_driver.show()
	node_car.show()
	events.trigger("menu_player_add", self)

func _on_Remove():
	node_add.show()
	node_remove.hide()
	node_driver.hide()
	node_car.hide()
	events.trigger("menu_player_remove", self)

func _on_Driver_changed( text ):
	driver_name = text
	events.trigger("menu_player_updated", self)

func _on_Car_pressed():
	events.trigger("menu_player_edit", self)
