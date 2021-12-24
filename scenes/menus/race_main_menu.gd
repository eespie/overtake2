extends Node2D

var player_info_list = []
var player_line_scene

onready var node_player_list = get_node("PlayerPanel/Players")
onready var node_laps = get_node("Laps")
onready var node_circuit = get_node("Circuit")

func _ready():
	bind_events()
	race_mgr.local_init()
	player_line_scene = load("res://scenes/menus/Player_line.tscn")
	reinit()
	
func reinit():
	node_laps.set_text(str(race_mgr.lap_nb))
	for node in node_player_list.get_children():
		node_player_list.remove_child(node)
		node.queue_free()
	for i in range(race_mgr.player_nb):
		var node_player_line = player_line_scene.instance()
		node_player_line.driver_index = i
		node_player_line.is_new = false
		node_player_line.driver_name = race_mgr.player_info_list[i].driver_name
		node_player_line.car_index = race_mgr.player_info_list[i].car_index
		node_player_line.car_color = race_mgr.player_info_list[i].car_color
		node_player_list.add_child(node_player_line)
	add_empty_player(race_mgr.player_nb)
	node_circuit.set("texture", load(str("res://scenes/circuits/circuit_",race_mgr.current_circuit,"/circuit_",race_mgr.current_circuit,".png")))

func add_empty_player(index):
	if index < 8 and index == race_mgr.player_nb:
		var node_player_line = player_line_scene.instance()
		node_player_line.driver_index = index
		node_player_list.add_child(node_player_line)

func bind_events():
	events.register("menu_player_add", self)
	events.register("menu_player_remove", self)
	events.register("menu_player_updated", self)
	events.register("menu_player_edit", self)
	
func _exit_tree():
	events.unregister_node(self)

func on_menu_player_add(node):
	race_mgr.add_player(node.driver_index, node.driver_name, node.car_index, node.car_color)
	add_empty_player(node.driver_index + 1)

func on_menu_player_remove(node):
	race_mgr.remove_player(node.driver_index)
	reinit()

func on_menu_player_updated(node):
	race_mgr.update_player(node.driver_index, node.driver_name, node.car_index, node.car_color)

func on_menu_player_edit(node):
	race_mgr.current_player = node
	events.trigger("screen_change", "menus/car_selection_menu")


func _on_next_circuit():
	race_mgr.current_circuit += 1
	if race_mgr.current_circuit > race_mgr.circuit_nb:
		race_mgr.current_circuit = 1
	race_mgr.save_game()
	reinit()

func _on_previous_circuit():
	race_mgr.current_circuit -= 1
	if race_mgr.current_circuit == 0:
		race_mgr.current_circuit = race_mgr.circuit_nb
	race_mgr.save_game()
	reinit()

func _on_Race():
	events.trigger("screen_change", str("circuits/circuit_",race_mgr.current_circuit,"/circuit_",race_mgr.current_circuit))

func _on_laps_changed( text ):
	if text.is_valid_integer():
		race_mgr.lap_nb = text.to_int()
		race_mgr.save_game()
