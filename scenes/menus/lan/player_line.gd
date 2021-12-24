extends Control

var cars = [ 5, 1, 2, 3, 4 ]

var driver_name = "Player"
var car_index = 1
var car_color = "Blue"

onready var node_driver = get_node("Driver")
onready var node_car = get_node("Car")

func _ready():
	node_driver.set_text(driver_name)
	node_car.set("texture_normal", load(str("res://Asset/PNG/Cars/car_",car_color.to_lower(),"_small_",cars[car_index],".png")))
