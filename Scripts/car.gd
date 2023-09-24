extends VehicleBody

export (int, "Automatic", "Manual") var drive_type = 0

export var horsepower := 450
export var acceleration_speed := 80

export var steer_angle := 36
export var steer_speed: float = 40

export var brake_power := 40
export var brake_speed := 40

var drive_input: float
var steer_input: float
var brake_input: float

var target_path := []
var target_pos: Vector3
var target_dir: Vector3
var target_angle # : float
var closest_point: Vector3

onready var start = owner.get_node("Track").get_child(0).get_node("Objects/start").global_translation
onready var finish = owner.get_node("Track").get_child(0).get_node("Objects/finish").global_translation

onready var nav_map: RID = get_world().get_navigation_map()

var reset_vehicle := false

var start_time: float
var stoppage_testing := false
var stop_time: float = 3000
var stopped := false
var last_pos: Vector3

func _ready():
	$MESHES.set_as_toplevel(true)


func _physics_process(delta):
	if Input.is_action_just_pressed("reload"):
		get_tree().reload_current_scene()
	
	navigation()
	if drive_type == 0:
		stop_test()
		
		drive_input = 1
		steer_input = target_angle
		brake_input = 0
	else:
		drive_input = Input.get_action_strength("accelerate") - Input.get_action_strength("reverse")
		steer_input = Input.get_action_strength("turn_left") - Input.get_action_strength("turn_right")
		brake_input = 0
	
	engine_force = lerp(engine_force, drive_input * horsepower, acceleration_speed * delta)
	steering = lerp_angle(steering, steer_input * deg2rad(steer_angle), steer_speed * delta)
	brake = lerp(brake, brake_input * brake_power, brake_speed * delta)


func _integrate_forces(state):
	if reset_vehicle:
		reset_vehicle = false
		var chosen_basis = global_transform.looking_at(target_pos, Vector3.UP).rotated(Vector3.UP, PI).basis
		state.set_transform(Transform(chosen_basis, target_pos))


func navigation():
	if target_path == []:
		target_path = Array(NavigationServer.map_get_path(nav_map, start, finish, true))
	else:
		closest_point = NavigationServer.map_get_closest_point(nav_map, global_translation)
		target_pos = target_path[0]
		
		if closest_point.distance_to(target_pos) < 10:
			target_path.erase(target_path[0])
	
	$MESHES/target_pos.global_translation = target_pos
	
	target_dir = global_translation.direction_to(target_pos)
	target_angle = target_direction_angle(target_dir.normalized())


func target_direction_angle(t_dir):
	# here we first determine the up vector of the target direction. NB: order of vectors matter here
	var target_dir_up_angle = global_transform.basis.z.cross(t_dir)
	# then we determine the angle to it from the up vector of the car
	var dot = global_transform.basis.y.dot(target_dir_up_angle)
	return dot


func stop_test():
	stopped = true if (linear_velocity.length_squared() < 1.0 and global_translation.distance_to(last_pos) < 1.0) else false
	
	if stopped:
		if not stoppage_testing:
			stoppage_testing = true
			start_time = Time.get_ticks_msec()
	else:
		stoppage_testing = false
	
	if stoppage_testing:
		if Time.get_ticks_msec() - start_time >= stop_time:
			stoppage_testing = false
			reset_vehicle = true
#			print("Stopped for ", stop_time ," seconds!")
	
	last_pos = global_translation
		
	
