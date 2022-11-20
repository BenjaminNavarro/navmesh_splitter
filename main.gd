tool
extends EditorPlugin

var plugin = preload("./inspector_plugin.gd")


func _enter_tree():
	add_custom_type("NavmeshSplitter", "Spatial", preload("./navmesh_splitter.gd"), preload("./icon.png"))
	plugin = plugin.new()
	add_inspector_plugin(plugin)


func _exit_tree():
	remove_inspector_plugin(plugin)
