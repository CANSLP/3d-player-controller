class_name HandItem extends Interactable


var held : bool = false
var holder : Player
@onready var body = get_parent()
@onready var collision = body.get_node("collision")
@onready var container : Node3D = body.get_parent()

func grab(player : Player):
	body.sleeping = true
	body.freeze = true
	collision.disabled = true
	held = true
	holder = player

func throw():
	body.sleeping = false
	body.freeze = false
	collision.disabled = false
	body.reparent(container)
	holder.item = null
	body.linear_velocity = holder.linear_velocity+(holder.look_direction()+Vector3(0,1,0))*2.5
	held = false
	holder = null

#called when clicked
func _clicked(player: Player):
	if !held:
		if player.set_hand(self,body):
			grab(player)

#called when used in hand
func use():
	throw()
