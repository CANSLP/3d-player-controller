class_name Player extends RigidBody3D

var has_focus : bool = false

var kFORWARD : bool = false
var kBACKWARD : bool = false
var kLEFTWARD : bool = false
var kRIGHTWARD : bool = false
var kCROUCH : bool = false
var kRUN : bool = false
var kJUMP : bool = false
var vLOOK : Vector2 = Vector2(0,0)
var front_angle : float

var time : float = 0

@export var can_jump : bool = true
@export var can_run : bool = true
@export var can_crouch : bool = true
@export var walk_speed : float = 1.5
@export var run_speed : float = 2.5
@export var jump_power : float = 12.5
@export var gravity :float = 0.5
@export var friction : Vector3 = Vector3(0.75,1,0.75)
@export var reach = 2
@export var cam_speed : Vector2 = Vector2(1,1)*30
@export var cam_fov : float = 75
@export var cam_run_fov : float = 85
@export var hand_side : bool = true
@export var hand_bob : float = 0.025
@export var head_bob : float = 0.05
@export var bob_speed : float = 15

var target : Interactable

var on_ground : bool = false
var crouch : float = 0
var run : float = 0
var running : bool = false
var bob_amt : float = 0
var last_pos : Vector3
var save_vel : Vector3

@onready var hand : Node3D = $camera/hand

@onready var db_land_1 = $audio/sfx_land_1.volume_db
@onready var db_land_2 = $audio/sfx_land_2.volume_db

func _ready():
	front_angle = $camera.rotation.y
	last_pos = position
	save_vel = linear_velocity
	if hand_side:
		hand.position.x = 0.5
	else:
		hand.position.x = -0.5

func _process(delta):
	time += delta
	
	#camera
	if has_focus:
		$camera.rotation.y += vLOOK.x * delta * cam_speed.x
		$camera.rotation.x += vLOOK.y * delta * cam_speed.y
		$camera.rotation.x = clamp($camera.rotation.x,-PI/2,PI/2)
		front_angle = $camera.rotation.y
	vLOOK = Vector2(0,0)
	
	#run
	if !can_run:
		running = false
	if running:
		run = lerp(run,1.0,delta*10)
	else:
		run = lerp(run,0.0,delta*10)
	$camera.fov = lerp(cam_fov,cam_run_fov,run)
	
	#crouch
	var c = crouch
	if can_crouch && on_ground && kCROUCH:
		crouch += (1-crouch)*delta*10
		running = false
	else:
		crouch += (0-crouch)*delta*10
	if crouch < c:
		var headspace = 2-crouch
		var headcast = clamp(sphere_cast(global_position+Vector3(0,-0.5,0),Vector3(0,1.5,0),0.5).hit_distance+0.5,1,2)
		if headspace > headcast:
			if headcast > 2-crouch:
				crouch = 2-headcast
			else:
				crouch = c
		$camera.position.y = 0.5-crouch
		$collider.shape.set_height(2-crouch)
		$collider.position.y = crouch*-0.5
	else:
		$camera.position.y = 0.5-crouch
		$collider.shape.set_height(2-crouch)
		$collider.position.y = crouch*-0.5
	
	get_target()
	
	#animation
	$camera.position.y += sin(time*bob_speed)*bob_amt*head_bob
	hand.position.y = -0.25+sin(time*bob_speed)*bob_amt*hand_bob
	if hand_side:
		hand.position.x = lerp(hand.position.x,0.5,delta*20)
	else:
		hand.position.x = lerp(hand.position.x,-0.5,delta*20)


#physics
func _integrate_forces(state):
	get_ground(state)
	state.linear_velocity *= friction
	
	
	#locomotion
	var walk_vector = Vector2(0,0)
	if has_focus:
		if can_run && kRUN && on_ground && crouch < 0.5:
			running = true
		#digital walk
		if(kFORWARD):
			walk_vector += Vector2(0,-1)
		if(kBACKWARD):
			walk_vector += Vector2(0,1)
		if(kLEFTWARD):
			walk_vector += Vector2(1,0)
		if(kRIGHTWARD):
			walk_vector += Vector2(-1,0)
		if(walk_vector.x==0&&walk_vector.y==0):
			running = false
			bob_amt = lerp(bob_amt,0.0,0.25)
		else:
			walk(state,atan2(walk_vector.y,walk_vector.x),1)
			if on_ground:
				if running:
					bob_amt = lerp(bob_amt,2.0,0.15)
				else:
					bob_amt = lerp(bob_amt,1.0-crouch*0.5,0.15)
			else:
				bob_amt = lerp(bob_amt,0.0,0.25)
		
		#jump
		if can_jump && kJUMP:
			if(on_ground && crouch < 0.5):
				state.linear_velocity.y = jump_power
				$audio/sfx_jump.play()
	else:
		running = false
	
	if !on_ground:
		state.linear_velocity += Vector3(0,-gravity,0) #gravity
	
	last_pos = position
	save_vel = linear_velocity

func walk(state,walk_angle,speed):
	var _s = speed*lerp(walk_speed,run_speed,run)*(1-crouch*0.5)
	state.linear_velocity += Vector3(-cos(front_angle+walk_angle)*_s,0,sin(front_angle+walk_angle)*_s)

func get_ground(state):
	if state.get_contact_count() > 0:
		for contact in range(state.get_contact_count()):
			var cpos = state.get_contact_collider_position(contact)-last_pos
			var clayer = state.get_contact_collider_object(contact).get_collision_layer()
			if cpos.y<-0.6:
				if !on_ground:
					if save_vel.y < -0.5:
						var vol = clamp((-5-save_vel.y)*0.05,0.0,1.0)
						if vol > 0:
							$audio/sfx_land_1.volume_db = lerp(db_land_1-10.0,db_land_1+5.0,vol)
							$audio/sfx_land_1.play()
							if vol > 0.5:
								$audio/sfx_land_2.volume_db = lerp(db_land_2-10.0,db_land_2+5.0,vol)
								$audio/sfx_land_2.play()
				on_ground = true
				return
	on_ground = false

func click():
	$audio/sfx_click_in.play()
	if target:
		target._clicked(self)

func unclick():
	$audio/sfx_click_out.play()

func get_target():
	if target:
		target._untarget(self)
	target = null
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create($camera.global_position,$camera.global_position - $camera.global_transform.basis.z * reach)
	query.collide_with_areas = true
	var collision = space.intersect_ray(query)
	if collision:
		var obj = collision.collider.get_parent()
		if obj is Interactable:
			target = collision.collider.get_parent()
			target._target(self)

#get inputs
func _input(event):
	if event is InputEventMouseMotion:
		vLOOK = Vector2(event.relative.x * -0.0025,event.relative.y * -0.0025)
	if event.is_action_pressed("click"):
		if(has_focus):
			click()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		has_focus = true
	if event.is_action_released("click"):
		if(has_focus):
			unclick()
	if event.is_action_pressed("menu"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		has_focus = false
	if event.is_action_pressed("mv_fwd"):
		kFORWARD = true
	if event.is_action_released("mv_fwd"):
		kFORWARD = false
	if event.is_action_pressed("mv_back"):
		kBACKWARD = true
	if event.is_action_released("mv_back"):
		kBACKWARD = false
	if event.is_action_pressed("mv_left"):
		kLEFTWARD = true
	if event.is_action_released("mv_left"):
		kLEFTWARD = false
	if event.is_action_pressed("mv_right"):
		kRIGHTWARD = true
	if event.is_action_released("mv_right"):
		kRIGHTWARD = false
	if event.is_action_pressed("mv_jump"):
		kJUMP = true
	if event.is_action_released("mv_jump"):
		kJUMP = false
	if event.is_action_pressed("mv_crouch"):
		kCROUCH = true
	if event.is_action_released("mv_crouch"):
		kCROUCH = false
	if event.is_action_pressed("mv_run"):
		kRUN = true
	if event.is_action_released("mv_run"):
		kRUN = false



#spherecast return struct
class SphereCastResult:
	var hit_distance: float
	var hit_position: Vector3
	var hit_normal: Vector3
	var hit_collider

#spherecast
func sphere_cast(origin: Vector3, offset: Vector3, radius: float):
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state as PhysicsDirectSpaceState3D
	
	var shape: = SphereShape3D.new()
	shape.radius = radius
	
	var params: = PhysicsShapeQueryParameters3D.new()
	params.set_shape(shape)
	params.transform = Transform3D.IDENTITY
	params.transform.origin = origin
	params.motion = offset
	
	var castResult = space.cast_motion(params)
	
	var result: = SphereCastResult.new()
	
	result.hit_distance = castResult[0] * offset.length()
	result.hit_position = origin + offset * castResult[0] # needs null check in godot physics
	
	params.transform.origin += offset * castResult[1]

	var collision = space.get_rest_info(params)
	result.hit_normal = collision.get("normal", Vector3.ZERO)

	collision = space.intersect_shape(params, 1)
	#result.hit_collider = collision[0].get("collider")
	
	return result
