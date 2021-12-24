
extends Node

var callbacks = {}

func _ready():
	randomize()

func register(event, node):
	var list = null
	if (!callbacks.has(event)):
		list = {}
	else:
		list = callbacks[event]
	list[node] = true
	callbacks[event] = list
	
func unregister(event, node):
	if (callbacks.has(event)):
		var list = callbacks[event]
		list.erase(node)
		
func unregister_node(node):
	for event in callbacks:
		if callbacks[event].has(node):
			callbacks[event].erase(node)

func trigger(event, data1=null, data2=null, data3=null):
	#print(str("Trigger: ", event, " Data: ", data1, ", ", data2, ", ", data3))
	if (callbacks.has(event)):
		for node in callbacks[event]:
			if (node.has_method(str("on_", event))):
				event = str("on_", event)
			if (node.has_method(event)):
				if data3 != null:
					node.call(event, data1, data2, data3)
				elif data2 != null:
					node.call(event, data1, data2)
				elif data1 != null:
					node.call(event, data1)
				else:
					node.call(event)

