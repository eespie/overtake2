extends Node

func _ready():
	pass

func set_timeout(node, duration, callback, arg1 = null, arg2 =null, arg3 = null, arg4 = null, arg5 = null):
	var tw = Tween.new()
	print(str("Set timeout ", tw, " for: ", callback, " duration: ", duration, "s"))
	node.add_child(tw)
	tw.interpolate_callback(node, duration, callback, arg1, arg2, arg3, arg4, arg5)
	tw.start()
	return tw

func reset_timeout(tw):
	print(str("Reset timeout ", tw))
	tw.stop_all()
	tw.reset_all()
