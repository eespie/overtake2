extends RigidBody2D

export(int) var hit = 10

func _ready():
	if network.activated and not network.server:
		set_mode(RigidBody2D.MODE_KINEMATIC)
	else:
		set_mode(RigidBody2D.MODE_RIGID)

func _integrate_forces(state):
	if state and network.activated and network.server:
		rpc("update_pos", state.get_transform())

remote func update_pos(transf):
	set_transform(transf)
