class_name InteractionOrb extends Interactable

var size

@onready var mat_on : Material = load("uid://cdinswe28e5or")
@onready var mat_off : Material = load("uid://b4h4pqix5nn7n")

func _ready():
	size = 1
	$body.material = mat_off

func _process(delta):
	size += (1-size)*0.5
	$body.scale = Vector3(1,1,1)*size
	$body.position.y = sin(Time.get_ticks_msec()*0.0025)*0.1

#called when clicked
func _clicked(player: Player):
	size = 0.75

#called when hovered over
func _target(player: Player):
	$body.material = mat_on

#called when no longer hovered over
func _untarget(player: Player):
	$body.material = mat_off
