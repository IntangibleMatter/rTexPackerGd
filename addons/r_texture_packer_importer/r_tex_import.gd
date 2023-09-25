@tool
extends EditorImportPlugin

func _get_importer_name() -> String:
	return "r_tex_packer"


func _get_visible_name() -> String:
	return "rTexPacker"


func _get_recognized_extensions() -> PackedStringArray:
	return ["rtpa", "json", "xml"]


func _get_save_extension() -> String:
	return "tres"


func _get_resource_type() -> String:
	return "AtlasTexture"


func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	return [
		{"name": "image", "default_value": "", "property_hint": PROPERTY_HINT_FILE},
		{"name": "output_folder", "default_value": ProjectSettings.get_setting("r_tex_packer/output_path"), "property_hint": PROPERTY_HINT_DIR}
	]


func _get_option_visibility(_path: String, _option_name: StringName, _options: Dictionary) -> bool:
	return true


func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> Error:
	var file := FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	if options.image == "":
		return ERR_CANT_OPEN
	
	var tex : Dictionary
	
	match source_file.split(".")[-1]:
		"rtpa":
			tex = import_rtpa(file, options)
		"json":
			tex = import_json(file, options)
		"xml":
			tex = import_xml(file, options)
	
	if not tex == {}:
		for tx in tex:
			var img_path :="{0}{1}.{2}".format([options.output_folder, tx, _get_save_extension()])
			ResourceSaver.save(tex[tx], img_path, 68)
			gen_files.push_back(img_path)
	
	return OK


func import_rtpa(file: FileAccess, opt: Dictionary) -> Dictionary:
	var data : Dictionary
	var items := file.get_as_text().split("\n")
	var img : Texture2D = load(opt.image)
	
	for tex in items:
		if tex.begins_with("#"):
			continue
		var atlas := AtlasTexture.new()
		atlas.atlas = img
		var spr := tex.split(" ")
		var spr_f := PackedInt32Array(spr.slice(2))
		# Sprite info:   s <nameId> <originX> <originY> <positionX> <positionY> <sourceWidth> <sourceHeight> <padding> <trimmed> <trimRecX> <trimRecY> <trimRecWidth> <trimRecHeight>
		if spr[0] == "s":
			if spr_f[7] == 1: # trimmed
				atlas.region = Rect2i(spr_f[8], spr_f[9], spr_f[10] + spr_f[6], spr_f[11] + spr_f[6])
			else:
				atlas.region = Rect2i(spr_f[2], spr_f[3], spr_f[4] + spr_f[6], spr_f[5] + spr_f[6])
			
		
			data[spr[1]] = AtlasTexture.new()
	
	return data


func import_json(file: FileAccess, opt: Dictionary) -> Dictionary:
	var data : Dictionary
	var img : Texture2D = load(opt.image)
	
	var json := JSON.new()
	var j_data : Dictionary
	if json.parse(file.get_as_text()) == OK:
		j_data = json.data
	
	if j_data.has("software"):
		if j_data.software.has("name"):
			if not j_data.software.name.begins_with("rTexPacker"):
				return data
	if not j_data.has("sprites"):
		return data
	
	for spr in j_data.sprites:
		var atlas := AtlasTexture.new()
		atlas.atlas = img
		if spr.trimmed:
			atlas.region = Rect2i(spr.trimRec.x, spr.trimRec.y, spr.trimRec.width + spr.padding, spr.trimRex.height + spr.padding)
		else:
			atlas.region = Rect2i(spr.position.x, spr.position.y, spr.sourceSize.width + spr.padding, spr.sourceSize.height + spr.padding)
		
		data[spr.nameId] = atlas
	
	return data


func import_xml(file: FileAccess, opt: Dictionary) -> Dictionary:
	var data : Dictionary
	var xml := XMLParser.new()
	var img : Texture2D = load(opt.image)
	if xml.open_buffer(file.get_as_text().to_utf8_buffer()) != OK:
		return data
	while not xml.get_node_name() == "AtlasTexture":
		xml.read()
	
	while not xml.get_node_type() == XMLParser.NODE_ELEMENT_END:
		xml.read()
		if xml.get_node_name() == "Sprite":
			var atlas := AtlasTexture.new()
			atlas.atlas = img
			
			if xml.get_named_attribute_value("trimmed") == "1":
				atlas.region = Rect2i(
					int(xml.get_named_attribute_value("trimRecX")), int(xml.get_named_attribute_value("trimRecY")),
					int(xml.get_named_attribute_value("trimRecWidth")) + int(xml.get_named_attribute_value("padding")),
					int(xml.get_named_attribute_value("trimRecHeight")) + int(xml.get_named_attribute_value("padding"))
				)
			else:
				atlas.region = Rect2i(
					int(xml.get_named_attribute_value("positionX")), int(xml.get_named_attribute_value("positionY")),
					int(xml.get_named_attribute_value("sourceWidth")) + int(xml.get_named_attribute_value("padding")),
					int(xml.get_named_attribute_value("sourceHeight")) + int(xml.get_named_attribute_value("padding"))
				)
			
			
			data[xml.get_named_attribute_value("nameId")] = atlas
#		data[tex] = AtlasTexture.new()
	
	return data
