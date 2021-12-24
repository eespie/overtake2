
extends Node

var music_game
var music_win

func _ready():
	music_win = load_music("res://music/LGAS-win-theme.ogg")
	music_game = load_music("res://music/LGAS-game.ogg")

func load_music(res):
	var m = load(res)
	var music = StreamPlayer.new()
	music.set_stream(m)
	music.set_loop(true)
	music.add_to_group("music")
	return music

func stop_music():
	for m in get_tree().get_nodes_in_group("music"):
		m.stop()

func play_music(name):
	stop_music()
	if name == "game":
		get_tree().get_root().add_child(music_game)
		music_game.play()
	elif name == "win":
		get_tree().get_root().add_child(music_win)
		music_win.play()
