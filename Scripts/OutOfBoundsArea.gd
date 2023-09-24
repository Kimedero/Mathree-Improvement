tool
extends Area

onready var collision_shape: CollisionShape = $CollisionShape
onready var mesh_instance: MeshInstance = $MeshInstance

export var area_height := 25
export var area_width := 2500
export var area_length := 2500

func _ready():
	connect("body_entered", self, "_on_body_entered")
	global_translation = Vector3.DOWN * area_height
	
	collision_shape.shape.extents = Vector3(area_width, 1, area_length)
	mesh_instance.mesh.size = Vector3(area_width, 1, area_length) * 2


func _on_body_entered(body):
	if body is VehicleBody:
		body.reset_vehicle = true
#		print(body, " fell throught!")
