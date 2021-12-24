extends Node

var activated = false
var broadcast
var timer
var server = true
var state = "advertizing"
var port = 19664
var race_info
var server_addr = "127.0.0.1"
# Player info, associate ID to data
var player_info = {}
var player_done = {}
# Info we send to other players
var my_info
var client_timer


func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

func client_init():
	stop()
	player_info = {}
	server = false
	activated = true
	player_done = {}
	
func server_init():
	stop()
	server = true
	activated = true
	my_info.network_id = 1
	player_info = {}
	player_info[1] = my_info
	player_done = {}
	
func stop():
	var peer = get_tree().get_meta("network_peer")
	if peer:
		peer.close_connection()
	get_tree().set_network_peer(null)
	get_tree().set_meta("network_peer", null)
	activated = false
	
func server_start():
	var peer = NetworkedMultiplayerENet.new()
	peer.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_ZLIB)
	peer.create_server(port, 7)
	get_tree().set_network_peer(peer)
	get_tree().set_meta("network_peer", peer)
	if get_tree().is_network_server():
		print(str("Server initialized on port: ", port))

func client_start():
	var peer = NetworkedMultiplayerENet.new()
	peer.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_ZLIB)
	client_poll_start(peer)

func client_poll_start(peer):
	peer.close_connection()
	peer.create_client(server_addr, port)
	get_tree().set_network_peer(peer)
	get_tree().set_meta("network_peer", peer)
	client_timer = timer_mgr.set_timeout(self, 10, "client_poll_start", peer)

func _connected_ok():
	var id = get_tree().get_network_unique_id()
	print(str("Player ", id, " connected to server"))
	# Only called on clients, not server. Send my ID and info to the server
	rpc_id(1, "register_player", id, my_info)
	timer_mgr.reset_timeout(client_timer)

func _player_connected(id):
	print(str("Player connected ", id))
	# Send race info from the server
	if get_tree().is_network_server():
		var race_info = {"lap_nb":race_mgr.lap_nb, "circuit":race_mgr.current_circuit}
		rpc_id(id, "race_info", id, race_info)

remote func race_info(id, race_info):
	race_mgr.lap_nb = race_info.lap_nb
	race_mgr.current_circuit = race_info.circuit
	race_mgr.save_game()
	events.trigger("lan_race_info_updated", self)

func _player_disconnected(id):
	print(str("Player disconnected ", id))
	player_info.erase(id) # Erase player from info
	events.trigger("player_disconnected", id)
	
func sync_players():
	race_mgr.reset_players()
	for info in player_info.values():
		print(str("Add player: ", info.driver_name))
		race_mgr.add_player(race_mgr.player_nb, info.driver_name, info.car_index, info.car_color, info.network_id)
	events.trigger("lan_race_info_updated", self)

func _server_disconnected():
	print("Server disconnected")
	player_info = {}
	stop()
	events.trigger("lan_race_abort", self)
	events.trigger("screen_change", "menus/main_menu")

func _connected_fail():
	print("Connection failed")

remote func register_player(id, info):
	if not player_info.has(id):
		print(str("Register player: ", info.driver_name))
		var pinfo = race_mgr.add_player(race_mgr.player_nb, info.driver_name, info.car_index, info.car_color, id)
		player_info[id] = pinfo
	
		# If I'm the server, let the new guy know about existing players
		if get_tree().is_network_server():
			# Send my info to new player
			rpc_id(id, "register_player", 1, my_info)
			# Send the info of existing players
			for peer_id in player_info:
				rpc_id(id, "register_player", peer_id, player_info[peer_id])
			rpc("register_player", id, info)
		sync_players()
##
# Called when a player has finished its race init
##
func race_player_init_done(id):
	player_done[id] = true
	if (not activated) or (player_done.size() == player_info.size()):
		return true
	return false

func get_id():
	if activated:
		return get_tree().get_network_unique_id()
	return 0
	
