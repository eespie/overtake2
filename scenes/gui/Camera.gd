extends Camera2D

var length = []
var progress = []
var nodes = []
var total_length
var current_turn_time = 0
var scr

onready var tween = get_node("Tween")
onready var race = get_node("..")

func _ready():
	scr = get_viewport_rect().size
	var node
	node = get_node("Progress1")
	node.set_position(-scr * 0.5)
	node.scale = Vector2(0, 1)
	node.modulate = Color(1,1,1,1)
	node.show()
	nodes.append(node)
	length.append(scr.x/node.texture.get_width())
	
	node = get_node("Progress2")
	node.set_position(Vector2(scr.x * 0.5, -scr.y * 0.5))
	node.scale = Vector2(0, 1)
	node.modulate = Color(1,1,1,1)
	node.show()
	nodes.append(node)
	length.append(scr.y/node.texture.get_height())
	
	node = get_node("Progress3")
	node.set_position(scr * 0.5)
	node.scale = Vector2(0, 1)
	node.modulate = Color(1,1,1,1)
	node.show()
	nodes.append(node)
	length.append(scr.x/node.texture.get_width())
	
	node = get_node("Progress4")
	node.set_position(Vector2(-scr.x * 0.5, scr.y * 0.5))
	node.scale = Vector2(0, 1)
	node.modulate = Color(1,1,1,1)
	node.show()
	nodes.append(node)
	length.append(scr.y/node.texture.get_height())

	total_length = (scr.x / node.texture.get_width() + scr.y / node.texture.get_height()) * 2
	bind_events()
	set_process(true)
	
func bind_events():
	events.register("show_msg", self)
	events.register("hide_msg", self)

func _exit_tree():
	events.unregister_node(self)
	
func _process(delta):
	if race.is_local_player():
		var progress = (current_turn_time / (race.player_time - 1)) * total_length
		for i in range(4):
			if progress > 0:
				if progress >= length[i]:
					nodes[i].scale = Vector2(length[i], 1)
					progress -= length[i]
				else:
					nodes[i].scale = Vector2(progress, 1)
					progress = 0
	else:
		for i in range(4):
			nodes[i].scale = Vector2(0, 1)

func on_show_msg(msg_name, text, highlight):
	if race.is_local_player() and msg_name == "Countdown":
		if highlight:
			for node in nodes:
				node.modulate = Color(1,0,0,1)
		if current_turn_time == 0:
			tween.interpolate_property(self, "current_turn_time", 0, race.player_time, race.player_time, Tween.TRANS_LINEAR, Tween.EASE_IN, 0)
			tween.start()

func on_hide_msg(msg_name):
	if race.is_local_player() and msg_name == "Countdown":
		tween.stop_all()
		tween.reset_all()
		current_turn_time = 0
		for node in nodes:
			node.modulate = Color(1,1,1,1)
			node.scale = Vector2(0,1)
