extends Node

var displayed_msg = {}

func reset():
	displayed_msg = {}

func display(msg_name, text, highlight = false):
	if text:
		if displayed_msg.has(msg_name):
			if displayed_msg[msg_name] == text:
				return
		displayed_msg[msg_name] = text
		events.trigger("show_msg", msg_name, text, highlight)
	else:
		remove(msg_name)

func remove(msg_name):
	if not displayed_msg.has(msg_name):
		return
	displayed_msg.erase(msg_name)
	events.trigger("hide_msg", msg_name)
