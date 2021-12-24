extends Node2D

const circuit_nb = 2

var player_info_list = []
var player_line_scene

onready var node_player_list = get_node("PlayerPanel/Players")
onready var node_laps = get_node("Laps")
onready var node_circuit = get_node("Circuit")

func _ready():
	bind_events()
	network.client_start()
	player_line_scene = preload("res://scenes/menus/lan/player_line.tscn")
	reinit()
	
func reinit():
	node_laps.set_text(str(race_mgr.lap_nb))
	for node in node_player_list.get_children():
		node_player_list.remove_child(node)
		node.queue_free()
	for i in range(race_mgr.player_nb):
		var node_player_line = player_line_scene.instance()
		node_player_line.driver_name = race_mgr.player_info_list[i].driver_name
		node_player_line.car_index = race_mgr.player_info_list[i].car_index
		node_player_line.car_color = race_mgr.player_info_list[i].car_color
		node_player_list.add_child(node_player_line)
	node_circuit.set("texture", load(str("res://scenes/circuits/circuit_",race_mgr.current_circuit,"/circuit_",race_mgr.current_circuit,".png")))

func bind_events():
	events.register("lan_race_start", self)
	events.register("lan_race_abort", self)
	events.register("lan_race_info_updated", self)
	
func _exit_tree():
	events.unregister_node(self)

func on_lan_race_info_updated(dummy):
	reinit()

func on_lan_race_start(dummy):
	events.trigger("screen_change", str("circuits/circuit_",race_mgr.current_circuit,"/circuit_",race_mgr.current_circuit))

func on_lan_race_abort(dummy):
	events.trigger("screen_change", "menus/main_menu")

func _on_back():
	events.trigger("screen_change", "menus/main_menu")

