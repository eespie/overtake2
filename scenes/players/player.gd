extends RigidBody2D

export(int) var driver_index = 0
export(String) var driver_name
export(float) var hit = 4
export(float) var car_power = 10
export(String, "Blue", "Red", "Green", "Yellow") var car_color = "Blue"

var network_id = 0
var wp
var lap
var selected = false
var finish_pos = 1000
var skidding = false
var jocker = false

var aim = Vector2(0, 0)
var mouse_state = "idle"
var car_state = "idle"
var pos

var len_max = 180
var car_transform

const reaction_max = 2

onready var outline = get_node("Outline")
onready var node_driver = get_node("Driver")
onready var race = get_node("../..")
onready var skidl_node = get_node("Skid/Left")
onready var skidr_node = get_node("Skid/Right")
onready var arrow_node = get_node("Arrow")

var boost_activated = false
var x2_activated = false
var boost_enabled = false
var x2_enabled = false

func _ready():
	if not driver_name:
		driver_name = get_name()
	if not network.server:
		mode = RigidBody2D.MODE_KINEMATIC
	get_node("Driver/Name").set_text(driver_name)
	set_process_input(true)
	set_process(true)
	car_transform = get_transform()
	events.register("fire", self)
	for c in ["Blue", "Red", "Green", "Yellow"]:
		if c == car_color.capitalize():
			get_node(str("CarBody/", c)).show()
			get_node(str("Arrow/", c)).show()
		else:
			get_node(str("CarBody/", c)).hide()
			get_node(str("Arrow/", c)).hide()

func _exit_tree():
	events.unregister_node(self)
	
func _process(delta):
	var rot = get_rotation()
	node_driver.set_rotation(-rot)
	var vel = self.get_linear_velocity()
	# Trajectory correction
	if network.server:
		if vel.length() > 5:
			var diff_angle = vel.angle() - rot
			while diff_angle > PI:
				diff_angle -= 2 * PI
			while diff_angle < -PI:
				diff_angle += 2 * PI
			if abs(diff_angle) > deg2rad(10):
				set_applied_force(vel.rotated(PI / 2 * -sign(diff_angle))/2)
				if !skidding and vel.length() > 10:
					skidding = true
					if network.activated:
						rpc("emit_skid", true)
					else:
						emit_skid(true)
				elif skidding:
					skidding = false
					if network.activated:
						rpc("emit_skid", false)
					else:
						emit_skid(false)
			else:
				set_applied_force(Vector2(0, 0))
				if skidding:
					skidding = false
					if network.activated:
						rpc("emit_skid", false)
					else:
						emit_skid(false)
	
	if selected:
		outline.show()
	else:
		outline.hide()
		
	if network.server:
		if mouse_state == "drag":
			#set_mode(RigidBody2D.MODE_KINEMATIC)
			set_rotation(aim.angle())
			car_transform = get_transform()
			set_applied_force(Vector2(0, 0))
			update_car(car_transform)
		else:
			if (race.current_selected_car == self) and (sleeping or (vel.length() == 0)) and car_state != "idle" and car_state != "starting":
				car_state = "idle"
				events.trigger("end_move", self)
	update_arrow()
	
# Move the clients
slave func update_car(transf):
	car_transform = transf
	if network.activated:
		if network.server:
			rpc("update_car", transf)
		else:
			set_transform(transf)

sync func emit_skid(emit):
	skidl_node.set("emitting", emit)
	skidr_node.set("emitting", emit)

func _input(event):
	if not selected or (network.get_id() != network_id):
		aim = Vector2(0, 0)
		return
	var ev = race.make_input_local(event)
	var touch = (event is InputEventScreenTouch) || (event is InputEventMouseButton)
	var touch_pressed = touch and event.is_pressed()
	var touch_released = touch and not event.is_pressed()
	var mouse_drag = (event is InputEventScreenDrag) || (event is InputEventMouseMotion)
	if touch or mouse_drag:
		var vec = Vector2(get_position().x - ev.get_position().x, get_position().y - ev.get_position().y)
		if touch_pressed:
			if vec.length() < 30:
				#set_mode(RigidBody2D.MODE_KINEMATIC)
				mouse_state = "aim"
		if touch_released and mouse_state == "drag":
			events.trigger("fire", self, aim)
			mouse_state = "idle"
			aim = Vector2(0, 0)
		if mouse_drag and mouse_state == "aim":
			mouse_state = "drag"
		if mouse_state == "drag":
			vec = 2.0 * vec
		var lm = get_len_max()
		if vec.length() > lm:
			aim = vec.normalized() * lm
		else:
			aim = vec
		update_aim(mouse_state, aim)

func get_len_max():
	var lm = len_max
	if boost_activated:
		lm = lm * 1.5
	return lm

remote func update_aim(ms_state, vec):
	if network.get_id() != network_id:
		mouse_state = ms_state
		aim = vec
	elif network.activated:
		rpc("update_aim", ms_state, vec)

sync func select_player(s):
	selected = s
	if selected and not network.server:
		race.current_selected_car = self
		race.disp_message(driver_name)
	if selected and (network.get_id() == network_id):
		set_process_input(true)
		events.trigger("enable_boost", boost_enabled)
		events.trigger("enable_x2", x2_enabled)
	else:
		set_process_input(false)
		events.trigger("enable_x2", false)

func _integrate_forces(state):
	if state:
		if car_state == "starting":
			state.set_transform(car_transform)
			car_state = "moving"
		if state and network.activated and network.server and mouse_state == 'idle':
			rpc("update_car", state.get_transform())

func update_arrow():
	if mouse_state == "idle":
		arrow_node.hide()
	else:
		arrow_node.show()
		var ratio = aim.length() / len_max
		arrow_node.set("scale", Vector2(ratio, ratio))

func on_fire(node, vec):
	if node == self:
		if boost_activated:
			boost_activated = false
			boost_enabled = false
			events.trigger("enable_boost", false)
		if network.activated:
			rpc("car_fire", vec)
		else:
			car_fire(vec)

master func car_fire(vec):
	mouse_state = "idle"
	if network.server:
		#set_mode(RigidBody2D.MODE_RIGID)
		var reaction_factor = 1
		if race.turn == 1:
			var reaction = race.get_reaction_time()
			if vec.length() > get_len_max() * 0.9:
				if reaction < reaction_max:
					reaction_factor = 1 + (reaction_max - reaction) / 3
		var impulse = vec * car_power * reaction_factor
		apply_impulse(Vector2(0,0), impulse)
		car_state = "starting"


sync func abort_fire():
	aim = Vector2(0, 0)
	#if network.server:
		#set_mode(RigidBody2D.MODE_RIGID)
	update()

func _on_object_collision(body):
	if body != self:
		var hit_points = body.hit
		var vel = get_linear_velocity()
		if body is RigidBody2D:
			vel = vel - body.get_linear_velocity()
		var hit_force = vel.length() * hit_points
		#print(str("Collision: ", get_name(), " into: ",body.get_name()," hit: ", hit_force))
