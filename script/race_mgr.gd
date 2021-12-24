extends Node

const circuit_nb = 7

var current_circuit
var player_nb = 1
var lap_nb
var player_info_list = []
var current_player
var race_result

func _ready():
	randomize()

func local_init():
	player_info_list = []
	network.activated = false
	var savedict = file.load_game()
	if typeof(savedict) == TYPE_DICTIONARY:
		current_circuit = savedict["current_circuit"]
		player_nb = savedict["player_nb"]
		lap_nb = savedict["lap_nb"]
		check_race_info()
		for i in range(player_nb):
			var player_info = {}
			player_info.driver_index = i
			player_info.driver_name = savedict[str("player_info_",i,"_driver")]
			player_info.car_index = savedict[str("player_info_",i,"_car")]
			if typeof(player_info.car_index) == TYPE_STRING:
				player_info.car_index = player_info.car_index.to_int()
			player_info.car_color = savedict[str("player_info_",i,"_color")]
			player_info.network_id = 0
			player_info_list.append(player_info)
	else:
		current_circuit = 1
		player_nb = 1
		lap_nb = 3
		var player_info = {}
		player_info.driver_index = 0
		player_info.driver_name = "Player 0"
		player_info.car_index = 1
		player_info.car_color = "Blue"
		player_info.network_id = 0
		player_info_list.append(player_info)
	flush_players()

func lan_init():
	player_info_list = []
	current_circuit = 1
	player_nb = 1
	lap_nb = 3
	var savedict = file.load_game()
	if typeof(savedict) == TYPE_DICTIONARY:
		current_circuit = savedict["current_circuit"]
		lap_nb = savedict["lap_nb"]
		if savedict.has("server_addr"):
			network.server_addr = savedict["server_addr"]
			var player_info = {}
			player_info.driver_index = 0
			player_info.driver_name = savedict["lan_player_info_driver"]
			player_info.car_index = savedict["lan_player_info_car"]
			if typeof(player_info.car_index) == TYPE_STRING:
				player_info.car_index = player_info.car_index.to_int()
			player_info.car_color = savedict["lan_player_info_color"]
			player_info.network_id = 0
			current_player = player_info
			player_info_list.append(player_info)
			network.my_info = current_player
			network.activated = true
			check_race_info()
			return
	var player_info = {}
	player_info.driver_index = 0
	player_info.driver_name = "Player 0"
	player_info.car_index = 1
	player_info.car_color = "Blue"
	player_info.network_id = 0
	player_info_list.append(player_info)
	current_player = player_info
	network.my_info = current_player
	network.activated = true

func check_race_info():
	if not current_circuit:
		current_circuit = 1
	if not player_nb:
		player_nb = 1
	if not lap_nb:
		lap_nb = 3

func save_game():
	var savedict = file.load_game()
	if not savedict or typeof(savedict) != TYPE_DICTIONARY:
		savedict = {}
	savedict["current_circuit"] = current_circuit
	savedict["lap_nb"] = lap_nb
	if network.activated:
		savedict["server_addr"] = network.server_addr
		savedict["lan_player_info_driver"] = network.my_info.driver_name
		savedict["lan_player_info_car"] = network.my_info.car_index
		savedict["lan_player_info_color"] = network.my_info.car_color
	else:
		savedict["player_nb"] = player_nb
		for i in range(player_nb):
			var player_info = player_info_list[i]
			savedict[str("player_info_",i,"_driver")] = player_info.driver_name
			savedict[str("player_info_",i,"_car")] = player_info.car_index
			savedict[str("player_info_",i,"_color")] = player_info.car_color
	file.save_game(savedict)

remote func reset_players():
	player_nb = 0
	player_info_list = []

remote func add_player(index, driver, car, color, network_id = 0):
	player_nb += 1
	var player_info = {}
	player_info.driver_index = index
	player_info.driver_name = driver
	player_info.car_index = car
	player_info.car_color = color
	player_info.network_id = network_id
	player_info_list.append(player_info)
	save_game()
	return player_info

sync func remove_player(index):
	for i in range(player_nb):
		var player = player_info_list[i]
		if player.driver_index == index:
			player_info_list.remove(i)
			player_nb -= 1
			break
	for i in range(player_nb):
		player_info_list[i].driver_index = i
	save_game()

func update_player(index, driver, car, color):
	if network.activated:
		var player_info = {}
		player_info.driver_index = 0
		player_info.driver_name = driver
		player_info.car_index = car
		player_info.car_color = color
		current_player = player_info
		network.my_info = current_player
		
	if index < player_nb:
		player_info_list[index].driver_index = index
		player_info_list[index].driver_name = driver
		player_info_list[index].car_index = car
		player_info_list[index].car_color = color
		save_game()

##
# Load (local and remote) the scene of the race
##
remote func mgr_load_race():
	network.player_done = {}
	if network.server:
		get_tree().set_refuse_new_network_connections(true)
		flush_players()
		rpc("reset_players")
		for i in range(player_nb):
			var player = player_info_list[i]
			rpc("add_player", player.driver_index, player.driver_name, player.car_index, player.car_color, player.network_id)
		rpc("inform_players_init")
	events.trigger("screen_change", str("circuits/circuit_",current_circuit,"/circuit_",current_circuit))

# clients
remote func inform_players_init():
	rpc_id(1, "players_confirm_init", network.get_id(), player_nb)

# server
remote func players_confirm_init(id, nb):
	if nb == player_nb:
		rpc_id(id, "mgr_load_race")
	else:
		rpc_id(id, "reset_players")
		for i in range(player_nb):
			var player = player_info_list[i]
			rpc_id(id, "add_player", player.driver_index, player.driver_name, player.car_index, player.car_color, player.network_id)
		rpc_id(id, "inform_players_init")
##
# When the race scene is finally loaded
##
func end_prerace():
	if network.activated:
		rpc_id(1, "mgr_done_prerace", network.get_id())
	else:
		mgr_start_race()

##
# On the server register all the players to synchronize the race begin
##
sync func mgr_done_prerace(id):
	if network.race_player_init_done(id):
		rpc("mgr_start_race")

##
# Real beginning of the race
##
sync func mgr_start_race():
	events.trigger("race_begin")

func flush_players():
	for i in range(player_nb):
		player_info_list[i].driver_index = randi()
	player_info_list.sort_custom(CarFlusher, "flush")
	for i in range(player_nb):
		player_info_list[i].driver_index = i
	save_game()

class CarFlusher:
	static func flush(a, b):
		if a.driver_index < b.driver_index:
			return true
		return false
