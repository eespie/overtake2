extends Node2D

onready var node_laps = get_node("Laps")
onready var node_circuit = get_node("Circuit")

func _ready():
	reinit()
	
func reinit():
	node_laps.set_text(str(race_mgr.lap_nb))
	node_circuit.set("texture", load(str("res://scenes/circuits/circuit_",race_mgr.current_circuit,"/circuit_",race_mgr.current_circuit,".png")))

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

func _on_laps_changed( text ):
	if text.is_valid_integer():
		race_mgr.lap_nb = text.to_int()
		race_mgr.save_game()

func _on_next_screen():
	events.trigger("screen_change", "menus/lan/server_config_menu")
