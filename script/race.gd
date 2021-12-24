extends Node2D

export(int) var wp_nb
export(bool) var jocker_lap = false
const player_time = 10

export(Vector2) var P1 = Vector2(604, 560)
export(Vector2) var P2 = Vector2(541, 608)
export(String, "H", "HL", "V", "VB") var start_align = "H"
export(bool) var has_boost = false
export(bool) var start_boost = false
export(bool) var has_x2 = false
export(bool) var start_x2 = false

var car_pos = []
var car_turn = []
remote var current_turn_time = 0
var current_selected_car
var start_countdown = 3
var turn = 0
var finish_idx =0
var players_scene = []
var current_reaction_time = 0

onready var tweenPlayer = get_node("TweenPlayer")
onready var tweenStart = get_node("TweenStart")
onready var node_players = get_node("Players")

func _ready():
	message.reset()
	message.display("MainTitle", "Loading Race...", true)
	message.remove("MainCountdown")
	get_tree().set_pause(true)
	bind_events()
	for i in range(5):
		players_scene.append(load(str("res://scenes/players/Player",i,".tscn")))
	for i in range(race_mgr.player_nb):
		var player_info = race_mgr.player_info_list[i]
		add_player(i, player_info)
	end_prerace()
	set_process(true)
	
func bind_events():
	events.register("race_begin", self)
	events.register("end_move", self)
	events.register("fire", self)
	events.register("player_disconnected", self)
	events.register("WP", self)
	events.register("WP_jocker", self)
	
func _exit_tree():
	events.unregister_node(self)

sync func add_player(i, player_info):
	print(str("Race player ", player_info.driver_name, " (", player_info.network_id, ")"))
	var player = players_scene[player_info.car_index].instance()
	player.set_name(player_info.driver_name)
	player.driver_index = i
	player.driver_name = player_info.driver_name
	player.car_color = player_info.car_color
	player.network_id = player_info.network_id
	player.wp = wp_nb - 1
	player.lap = 0
	player.boost_enabled = has_boost and start_boost
	player.set_position(calc_init_pos(i))
	if start_align == "V":
		player.set_rotation(-PI/2)
	elif start_align == "VB":
		player.set_rotation(PI/2)
	elif start_align == "HL":
		player.set_rotation(PI)
	car_pos.append(player)
	node_players.add_child(player)
	message.display(str("Pos", i), str((i+1), " - ", player_info.driver_name))

sync func end_prerace():
	print("End Pre Race")
	race_mgr.end_prerace()

func on_race_begin():
	current_selected_car = car_pos[0]
	get_tree().set_pause(false)	
	if network.server:
		tweenStart.stop_all()
		tweenStart.reset_all()
		tweenStart.interpolate_method(self, "start_procedure", 4, 0.8, 3.2,Tween.TRANS_LINEAR, 0, 0)
		tweenStart.start()

func calc_init_pos(index):
	if index == 0:
		return P1
	if index == 1:
		return P2
	var pos = P2
	var delta = P2 - P1
	var i = 1
	while i < index:
		i += 1
		if start_align == "H" or start_align == "HL":
			pos.x += delta.x
			if i % 2 == 0:
				pos.y -= delta.y
			else:
				pos.y += delta.y
		else:
			if i % 2 == 0:
				pos.x -= delta.x
			else:
				pos.x += delta.x
			pos.y += delta.y
	return pos

func _process(delta):
	if network.activated and network.server:
		rset("current_turn_time", current_turn_time)
	var laps = ""
	if car_pos[0].lap > race_mgr.lap_nb:
		laps = str("Winner ",car_pos[0].driver_name)
	else:
		var lap = car_pos[0].lap
		if lap == 0:
			lap = 1
		laps = str("Lap ", lap, "/", race_mgr.lap_nb)
	message.display("Laps", laps)
	if current_turn_time == 0:
		message.remove("Countdown")
	else:
		var countdown = floor(player_time - current_turn_time)
		var highlight = false
		if countdown < 6:
			highlight = true
		message.display("Countdown", str(countdown), highlight)

func on_WP(index, car):
	if index == 0:
		var idx = car.driver_index
		if car.wp == (wp_nb - 1):
			car.wp = 0
			car.lap += 1
			if start_boost:
				car.boost_enabled = true
			if start_x2:
				car.x2_enabled = true
			if car.lap == (race_mgr.lap_nb + 1):
				car.finish_pos = finish_idx
				finish_idx += 1
				if jocker_lap and not car.jocker:
					car.finish_pos = car.finish_pos + 10
			events.trigger("lapped" , idx, car.lap)
	else:
		check_wp(car, index)

func on_WP_jocker(car):
	car.jocker = true

func check_wp(car, wp):
	var idx = car.driver_index
	if car.wp == wp - 1:
		car.wp = wp
		events.trigger(str("WP", wp) , idx)

func on_player_disconnected(network_id):
	for i in range(race_mgr.player_nb):
		var c = car_pos[i]
		if c.network_id == network_id:
			car_pos.remove(i)
			race_mgr.player_nb = race_mgr.player_nb - 1
			return

# only the server get the event
func on_end_move(car):
	car_pos.sort_custom(CarSorter, "sort")
	if network.activated:
		var pos = {}
		for i in range(race_mgr.player_nb):
			var c = car_pos[i]
			pos[c.network_id] = i
		rpc("update_pos", pos)
	next_player()

remote func update_pos(pos):
	for i in range(race_mgr.player_nb):
		var c = car_pos[i]
		c.pos = pos[c.network_id]
	car_pos.sort_custom(PosSorter, "sort")
	show_ranking()

func show_ranking():
	for i in range(8):
		if i < race_mgr.player_nb:
			var car = car_pos[i]
			var label = str(i+1," - ",car.driver_name)
			if car.jocker:
				label = str(label, " (*)")
			message.display(str("Pos", i), label)
		else:
			message.remove(str("Pos", i))

func next_player():
	show_ranking()
	if current_selected_car.x2_activated:
		current_selected_car.x2_activated = false
		enable_x2(false)
		player_turn(current_selected_car)
	else:
		if car_turn.size() == 0:
			turn += 1
			car_turn = car_pos.duplicate()
		var i = 0
		while car_turn.size() > 0:
			var car = car_turn.pop_front()
			if car.lap <= race_mgr.lap_nb:
				player_turn(car)
				return
			i += 1
		if network.activated:
			rpc("end_race")
		else:
			end_race()

func player_turn(car):
	current_selected_car = car
	disp_message(current_selected_car.driver_name)
	if network.activated:
		current_selected_car.rpc("select_player", true)
	else:
		current_selected_car.select_player(true)
	tweenPlayer.interpolate_property(self, "current_turn_time", 0, player_time, player_time, Tween.TRANS_LINEAR, Tween.EASE_IN, 0)
	tweenPlayer.start()
	print(str("PLayer turn: ", car.driver_name))

sync func end_race():
	# Race finished
	disp_message()
	race_mgr.race_result = car_pos
	events.trigger("screen_change", "menus/end_race_menu")

func start_procedure(value):
	if network.activated:
		rpc("display_start_countdown", value)
	else:
		display_start_countdown(value)
	if not current_selected_car.selected and floor(start_countdown) == 0:
		next_player()

sync func display_start_countdown(value):
	start_countdown = value
	message.display("MainTitle", current_selected_car.driver_name, true)
	message.display("MainCountdown", str(floor(start_countdown)), true)

func _on_TweenStart_completed( object, key ):
	if network.activated:
		rpc("hide_start_countdown")
	else:
		hide_start_countdown()

sync func hide_start_countdown():
	message.remove("MainTitle")
	message.remove("MainCountdown")

func get_reaction_time():
	return current_reaction_time

func on_fire(car, dummy):
	current_reaction_time = tweenPlayer.tell()
	if network.activated:
		car.rpc("select_player", false)
	else:
		car.select_player(false)
	if network.server:
		srv_car_start()
	elif network.activated:
		rpc_id(1, "srv_car_start")
	
remote func srv_car_start():
	var reaction = floor(current_reaction_time * 1000)/1000
	if turn == 1:
		disp_message(str("Reaction time ",reaction,"s"))
	print(str("Fire: ", current_selected_car.driver_name))
	tweenPlayer.stop_all()
	tweenPlayer.reset_all()
	current_turn_time = 0

func disp_message(msg = null):
	if network.activated:
		rpc("message", msg)
	else:
		message(msg)

sync func message(msg = null):
	message.display("Message", msg)

func is_local_player():
	return current_selected_car and current_selected_car.network_id == network.get_id()

func activate_boost(activated):
	current_selected_car.boost_activated = activated

master func activate_x2(activated):
	current_selected_car.x2_activated = activated
	if not network.server:
		rpc_id(1, "activate_x2", activated)

remote func enable_x2(enabled):
	current_selected_car.x2_enabled = enabled
	rpc_id(current_selected_car.network_id, "enable_x2", enabled)
	
remote func enable_boost(enabled):
	current_selected_car.boost_enabled = enabled
	rpc_id(current_selected_car.network_id, "enable_boost", enabled)

func _on_x2_body_entered( body ):
	enable_x2(true)

func _on_boost_body_entered( body ):
	enable_boost(true)

# server
func _on_TweenPlayer_completed( object, key ):
	tweenPlayer.stop_all()
	tweenPlayer.reset_all()
	current_turn_time = 0
	if network.activated:
		current_selected_car.rpc("select_player", false)
		current_selected_car.rpc("abort_fire")
	else:
		current_selected_car.select_player(false)
		current_selected_car.abort_fire()
	next_player()

class PosSorter:
	static func sort(a, b):
		if a.pos < b.pos:
			return true
		return false

class CarSorter:
	static func sort(a, b):
		if a.finish_pos < b.finish_pos:
			return true
		if a.finish_pos > b.finish_pos:
			return false
		if a.lap < b.lap:
			return false
		if a.lap > b.lap:
			return true
		if a.wp < b.wp:
			return false
		if a.wp > b.wp:
			return true
		var next_wp = (a.wp + 1) % a.get_node("../..").wp_nb
		var wp_pos = a.get_node(str("../../WP/WP", next_wp)).get_position()
		var da = wp_pos.distance_squared_to(a.get_position())
		var db = wp_pos.distance_squared_to(b.get_position())
		if da < db:
			return true
		return false

