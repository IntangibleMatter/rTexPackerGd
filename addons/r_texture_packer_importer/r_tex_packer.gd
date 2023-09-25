@tool
extends EditorPlugin

var import_plugin : EditorImportPlugin

func _enter_tree() -> void:
	var settings := get_editor_interface().get_editor_settings()
	settings.set("r_tex_packer/output_path", "res://assets/graphics/")
	var property_info := {
		"name": "r_tex_packer/output_path",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_DIR,
		"hint_string": "The location that all the texture atlases will be exported to."
	}
	settings.add_property_info(property_info)
	
	import_plugin = preload("res://addons/r_texture_packer_importer/r_tex_import.gd").new()
	add_import_plugin(import_plugin)


func _exit_tree() -> void:
	remove_import_plugin(import_plugin)
	import_plugin = null
