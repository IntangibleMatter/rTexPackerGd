@tool
extends EditorPlugin

var import_plugin : EditorImportPlugin

func _enter_tree() -> void:
	var settings := get_editor_interface().get_editor_settings()
	settings.set("r_tex_packer/import_xml", false)
	var property_info_xml := {
		"name": "r_tex_packer/import_xml",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "Enables importing XML files. Disabled by default to avoid conflicts."
	}
	settings.set("r_tex_packer/import_json", false)
	var property_info_json := {
		"name": "r_tex_packer/import_json",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": "Enables importing JSON files. Disabled by default to avoid conflicts."
	}
	settings.add_property_info(property_info_xml)
	settings.add_property_info(property_info_json)
	
	add_import_plugin(import_plugin)


func _exit_tree() -> void:
	remove_import_plugin(import_plugin)
	import_plugin = null
