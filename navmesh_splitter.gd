tool
class_name NavmeshSplitter
extends Spatial


var size := Vector3.ZERO
var subdivide_width := 1
var subdivide_height := 1
var subdivide_depth := 1
var edge_connection_margin := 1.0
var navigation: NavigationMesh setget set_navigation


var _navmesh_instances = []
var _navmesh_aabb: AABB
var _last_bake_size: Vector3
var _last_bake_subdiv: Vector3
var _navmeshes_to_rebake := 0
var _navesh_bake_begin_time = {}
var _navesh_bake_duration = {}


func get_class(): return "NavmeshSplitter"
func is_class(name): return name == "NavmeshSplitter" or .is_class(name)

func _ready():
	# Needed for maps begin linked to regions, otherwise all map's RID will be zero below
	NavigationServer.process(0.0)

	for navmesh_instance in get_children():
		var region_rid = navmesh_instance.get_region_rid()
		var map_rid = NavigationServer.region_get_map(region_rid)
		NavigationServer.map_set_edge_connection_margin(map_rid, edge_connection_margin)


func rebake():
	if Engine.editor_hint:
		var warnings = _get_configuration_warning()
		if warnings != "":
			printerr("Cannot bake the navigation meshes because of configuration errors: ", warnings)
			return

	var bake_begin_time := OS.get_ticks_msec()
	clear()

	_navmesh_aabb = AABB(Vector3.ZERO, Vector3(size.x / subdivide_width, size.y / subdivide_height, size.z / subdivide_depth))
	_navmeshes_to_rebake = subdivide_width * subdivide_height * subdivide_depth
	_navmesh_instances = []
	_navesh_bake_begin_time = {}
	_navesh_bake_duration = {}
	for x in range(subdivide_width):
		_navmesh_instances.append([])
		for y in range(subdivide_height):
			_navmesh_instances[x].append([])
			for z in range(subdivide_depth):
				_navmesh_instances[x][y].append([])

				var navmesh_instance = NavigationMeshInstance.new()
				add_child(navmesh_instance)

				if Engine.editor_hint:
					navmesh_instance.owner = get_tree().edited_scene_root

				_navmesh_instances[x][y][z] = navmesh_instance

				var grid_location = Vector3(x, y, z)

				navmesh_instance.navmesh = navigation.duplicate()
				navmesh_instance.navmesh.setup_local_to_scene()
				navmesh_instance.navmesh.filter_baking_aabb = _navmesh_aabb
				navmesh_instance.navmesh.filter_baking_aabb_offset = -size / 2 + grid_location * _navmesh_aabb.size
				navmesh_instance.connect("bake_finished", self, "_on_navmesh_bake_finished", [x, y, z])
				_navesh_bake_begin_time[grid_location] = OS.get_ticks_msec()
				navmesh_instance.bake_navigation_mesh()

	while _navmeshes_to_rebake > 0:
		yield(get_tree().create_timer(0.001), "timeout")

	var bake_end_time := OS.get_ticks_msec()
	print("The complete navmesh took ", bake_end_time - bake_begin_time, "ms to bake")


func clear():
	for child in get_children():
		remove_child(child)
	for x in range(len(_navmesh_instances)):
		for y in range(len(_navmesh_instances[x])):
			for z in range(len(_navmesh_instances[x][y])):
				_navmesh_instances[x][y][z].queue_free()
	_navmesh_instances = []


func set_navigation(nav: NavigationMesh):
	navigation = nav
	update_configuration_warning()


func _on_navmesh_bake_finished(x: int, y: int, z: int):
	var grid_location = Vector3(x, y, z)
	_navesh_bake_duration[grid_location] = OS.get_ticks_msec() - _navesh_bake_begin_time[grid_location]
	print("Navmesh at ", grid_location, " took ", _navesh_bake_duration[grid_location], "ms to bake")
	_navmeshes_to_rebake -= 1


func _get_configuration_warning() -> String:
	if not navigation:
		return "Missing navigation mesh, please set one using the inspector or by setting the 'navigation' property"
	else:
		return ""


func _get_property_list():
	var properties = []
	properties.append({
		name = "NavmeshSplitter",
		type = TYPE_NIL,
		usage = PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_SCRIPT_VARIABLE
	})

	properties.append({
		name = "size",
		type = TYPE_VECTOR3,
	})

	properties.append({
		name = "subdivide_width",
		type = TYPE_INT,
		hint = PROPERTY_HINT_RANGE,
		hint_string = "1,100,1"
	})
	properties.append({
		name = "subdivide_height",
		type = TYPE_INT,
		hint = PROPERTY_HINT_RANGE,
		hint_string = "1,100,1"
	})
	properties.append({
		name = "subdivide_depth",
		type = TYPE_INT,
		hint = PROPERTY_HINT_RANGE,
		hint_string = "1,100,1"
	})
	properties.append({
		name = "edge_connection_margin",
		type = TYPE_REAL
	})

	properties.append({
		name = "navigation",
		type = TYPE_OBJECT,
		hint = PROPERTY_HINT_RESOURCE_TYPE,
		hint_string = "NavigationMesh"
	})
	return properties


func property_can_revert(property: String):
	if property == "size":
		return true

	if property.begins_with("subdivide"):
		return true

	if property == "edge_connection_margin":
		return true

	return false


func property_get_revert(property: String):
	if property == "size":
		return Vector3.ZERO

	if property.begins_with("subdivide"):
		return 1

	if property == "edge_connection_margin":
		return 1.0
