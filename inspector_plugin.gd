extends EditorInspectorPlugin


func can_handle(object):
	return object is NavmeshSplitter


func parse_category(object: Object, name: String):
	if name == "NavmeshSplitter":
		var bake_btn = Button.new()
		bake_btn.text = "Bake"
		bake_btn.connect("button_down", object, "rebake")
		add_custom_control(bake_btn)

		var clear_btn = Button.new()
		clear_btn.text = "Clear"
		clear_btn.connect("button_down", object, "clear")
		add_custom_control(clear_btn)
