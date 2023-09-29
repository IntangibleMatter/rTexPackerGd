@tool
extends EditorPlugin

var import_plugin : EditorImportPlugin

func _enter_tree() -> void:
	if not ProjectSettings.has_setting("r_tex_packer/import_xml"):
		ProjectSettings.set("r_tex_packer/import_xml", false)
		var property_info_xml := {
			"name": "r_tex_packer/import_xml",
			"type": TYPE_BOOL,
			"hint_string": "Enables importing XML files. Disabled by default to avoid conflicts."
		}
		ProjectSettings.add_property_info(property_info_xml)
	if not ProjectSettings.has_setting("r_tex_packer/import_json"):
		ProjectSettings.set("r_tex_packer/import_json", false)
		var property_info_json := {
			"name": "r_tex_packer/import_json",
			"type": TYPE_BOOL,
			"hint_string": "Enables importing JSON files. Disabled by default to avoid conflicts."
		}
		ProjectSettings.add_property_info(property_info_json)
	
	import_plugin = preload("res://addons/r_tex_packer_importer/r_tex_import.gd").new()
	add_import_plugin(import_plugin)


func _exit_tree() -> void:
	remove_import_plugin(import_plugin)
	import_plugin = null
