
extends Node

const save_file = "user://overtake.save"

func _ready():
	pass

func save_game(savedict):
	var savegame = File.new()
	savegame.open(save_file, File.WRITE)
	savegame.store_line(JSON.print(savedict))
	savegame.close()

func load_game():
	var savegame = File.new()
	if not savegame.file_exists(save_file):
		return #Error!  We don't have a save to load
	savegame.open(save_file, File.READ)
	var savedict = {}
	var content = savegame.get_line()
	#print(content)
	savedict = JSON.parse(content)
	savegame.close()
	return savedict.result
