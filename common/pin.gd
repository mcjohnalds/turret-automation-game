extends Node3D
class_name Pin

## wires[p] = w where p is a Pin and w is a Wire
var wires: Dictionary = {}
@onready var prong_mesh: MeshInstance3D = $ProngMesh
@onready var focus_mesh: MeshInstance3D = $FocusMesh
