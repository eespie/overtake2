extends Node2D

onready var node_circuit = get_node("Circuit")
onready var node_pos = get_node("Players/Pos")

func _ready():
	network.stop()
	node_circuit.set("texture", load(str("res://scenes/circuits/circuit_",race_mgr.current_circuit,"/circuit_",race_mgr.current_circuit,".png")))
	var i = 1
	for player in race_mgr.race_result:
		var node_pos_label = Label.new()
		var font = load("res://Asset/UI/KenneyBasePack/font_semi_bold_40.tres")
		node_pos_label.set("custom_fonts/font", font)
		node_pos_label.set_name(str("Pos", i))
		node_pos_label.set_text(str(i," - ",player.driver_name))
		node_pos.add_child(node_pos_label)
		i += 1

func _on_Back():
	events.trigger("screen_change", "menus/main_menu")
