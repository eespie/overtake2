extends MarginContainer

export(Color, RGB) var text_color = Color(1,1,1)
export(Color, RGB) var highlight_color = Color(1,0,0)

onready var tweenHighlight = get_node("HighlightTween")
onready var highlight_node = get_node("Inner/Row/Col3/Margin/Highlight")
onready var boost_node = get_node("Inner/Row/Col3/MarginBoost/Boost")
onready var x2_node = get_node("Inner/Row/Col3/Marginx2/x2")
onready var race = get_node("../../..")

var msg = {}

func _ready():
	init_nodes()
	for i in range(8):
		msg[str("Pos", i)].set("custom_colors/font_color", text_color)
		msg[str("Pos", i)].hide()
	for node in ["Laps", "Message", "Countdown"]:
		msg[node].set("custom_colors/font_color", text_color)
		msg[node].hide()
	if race.has_boost:
		boost_node.show()
	if race.has_x2:
		x2_node.show()
	bind_events()

func bind_events():
	events.register("show_msg", self)
	events.register("hide_msg", self)
	events.register("enable_boost", self)
	events.register("enable_x2", self)

func _exit_tree():
	events.unregister_node(self)

func init_nodes():
	msg["Message"] = get_node("Inner/Row/Col2/MMessage/Message")
	msg["Laps"] = get_node("Inner/Row/Col1/Laps")
	msg["Countdown"] = get_node("Inner/Row/Col3/Margin/Margin/Countdown")
	msg["MainTitle"] = get_node("Inner/Row/Col2/MMain/Main/MainTiTle")
	msg["MainCountdown"] = get_node("Inner/Row/Col2/MMain/Main/MainCountdown")
	for i in range(8):
		msg[str("Pos", i)] = get_node(str("Inner/Row/Col1/Pos", i)) 

func on_show_msg(msg_name, text, highlight):
	if msg.has(msg_name):
		msg[msg_name].show()
		msg[msg_name].set_text(text)
		if highlight:
			msg[msg_name].set("custom_colors/font_color", highlight_color)
			if msg_name == "Countdown":
				highlight_node.show()
				tweenHighlight.interpolate_property(highlight_node, "modulate", Color(1,0,0,0.5), Color(1,0,0,0), 1, Tween.TRANS_LINEAR, Tween.EASE_IN, 0)
				tweenHighlight.start()
		else:
			msg[msg_name].set("custom_colors/font_color", text_color)
			if msg_name == "Countdown":
				highlight_node.hide()
	
func on_hide_msg(msg_name):
	if msg.has(msg_name):
		msg[msg_name].hide()

func on_enable_boost(enable):
	boost_node.set("disabled", not enable)
	boost_node.set("pressed", false)

func on_enable_x2(enable):
	x2_node.set("disabled", not enable)
	x2_node.set("pressed", false)

func _on_Boost_toggled(button_pressed):
	race.activate_boost(button_pressed);

func _on_x2_toggled(button_pressed):
	race.activate_x2(button_pressed)
