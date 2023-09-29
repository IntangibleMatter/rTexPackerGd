@tool
extends EditorImportPlugin

enum Preset { DEFAULT }

func _get_importer_name() -> String:
	return "r_tex_packer"


func _get_visible_name() -> String:
	return "rTexPacker"


func _get_priority() -> float:
	return 1.0


func _get_import_order() -> int:
	return 10


func _get_recognized_extensions() -> PackedStringArray:
	var valid : PackedStringArray = ["rtpa", "rtpb"]
	if ProjectSettings.get_setting("r_tex_packer/import_xml"):
		valid.append("xml")
	if ProjectSettings.get_setting("r_tex_packer/import_json"):
		valid.append("json")
	return valid

func _get_save_extension() -> String:
	return "tres"


func _get_resource_type() -> String:
	return "Resource"


func _get_preset_count():
	return Preset.size()


func _get_preset_name(preset):
	match preset:
		Preset.DEFAULT: return "Default"


func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	return [
		{"name": "image", "default_value": "", "property_hint": PROPERTY_HINT_FILE},
#		{"name": "output_folder", "default_value": ProjectSettings.get_setting("r_tex_packer/output_path"), "property_hint": PROPERTY_HINT_DIR}
	]


func _get_option_visibility(_path: String, _option_name: StringName, _options: Dictionary) -> bool:
	return true


func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> Error:
	print("OPENGING")
	var file := FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		push_error("Couldn't import file %s" % source_file)
		return FileAccess.get_open_error()
	if options.image == "":
		print(source_file)
#		options.image = source_file.replace(".json", ".png").replace(".xml", ".png").replace(".rtpa", ".png").replace(".rtpb", ".png")
		print("Bepis")
	
	var tex : Dictionary
	print(source_file)
	match source_file.split(".")[-1]:
		"rtpa":
			tex = import_rtpa(file, options, source_file)
		"rtpb":
			tex = import_rtpb(file, options, source_file)
			print("rtpb")
		"json":
			tex = import_json(file, options)
		"xml":
			tex = import_xml(file, options)
	
	if not tex == {}:
		for tx in tex:
			var img_path :="{0}/{1}.{2}".format([source_file.get_base_dir() + source_file.get_base_name(), tx, _get_save_extension()])
			if not DirAccess.dir_exists(source_file.get_base_dir() + source_file.get_base_name()):
				DirAccess.make_dir_recursive(source_file.get_base_dir() + source_file.get_base_name())
			ResourceSaver.save(tex[tx], img_path, 68)
			gen_files.push_back(img_path)
	else:
		push_error("Import failed")
		return FAILED
	
	return OK


func import_rtpa(file: FileAccess, opt: Dictionary, source_file: String) -> Dictionary:
	var data : Dictionary
	var items := file.get_as_text().split("\n")
	var img : Texture2D
	if opt.image:
		img = load(opt.image)
#	else:
#		img = load(source_file.replace(".rtpa", ".png").replace(".rtpb", ".png"))
#		print("jkhasdgjahsgdkj")
	
	for tex in items:
		if tex.begins_with("#"):
			continue
		var atlas := AtlasTexture.new()
		
		var spr := tex.split(" ")
		var spr_f := PackedInt32Array(Array(spr.slice(2)))
		if spr[0] == "a":
			if spr_f[3] == 1:
				push_error("Error: rTexPackerGd can't import font files.")
				return data
			if not opt.image:
				img = load(source_file.get_base_dir() + "/" + spr[1])
				print("loaded " + source_file.get_base_dir() + "/" + spr[1])
		atlas.atlas = img
		# Sprite info:   s <nameId> <originX> <originY> <positionX> <positionY> <sourceWidth> <sourceHeight> <padding> <trimmed> <trimRecX> <trimRecY> <trimRecWidth> <trimRecHeight>
		if spr[0] == "s":
			if spr_f[7] == 1: # trimmed
				atlas.region = Rect2i(spr_f[8], spr_f[9], spr_f[10] + spr_f[6], spr_f[11] + spr_f[6])
			else:
				atlas.region = Rect2i(spr_f[2], spr_f[3], spr_f[4] + spr_f[6], spr_f[5] + spr_f[6])
			
		
			data[spr[1]] = atlas
		
	return data


#  rTexPacker Binary File Structure (.rtpb)
#  ------------------------------------------------------
#  Offset  | Size    | Type       | Description
#  ------------------------------------------------------
#  File header (8 bytes)
#  0       | 4       | char       | Signature: "rTPb"
#  4       | 2       | short      | Version: 200
#  6       | 2       | short      | reserved

#  General info data (16 bytes)
#  8       | 4       | int        | Sprites packed
#  12      | 4       | int        | Flags: 0-Default, 1-Atlas image included
#  16      | 2       | short      | Font type: 0-No font, 1-Normal, 2-SDF
#  18      | 2       | short      | Font size
#  20      | 2       | short      | Font SDF padding
#  22      | 2       | short      | reserved

#  Sprites properties data
#   - Size (only sprites): 128 + 48 bytes
#   - Size (font sprites): 128 + 64 bytes
#  foreach (sprite.packed)
#  {
		#  Default sprites data (128 + 48 bytes)
#    ...   | 128     | char       | Sprite Name identifier
#    ...   | 4       | int        | Sprite Origin X
#    ...   | 4       | int        | Sprite Origin Y
#    ...   | 4       | int        | Sprite Position X
#    ...   | 4       | int        | Sprite Position Y
#    ...   | 4       | int        | Sprite Source Width
#    ...   | 4       | int        | Sprite Source Height
#    ...   | 4       | int        | Sprite Padding
#    ...   | 4       | int        | Sprite is trimmed?
#    ...   | 4       | int        | Sprite Trimmed Rectangle X
#    ...   | 4       | int        | Sprite Trimmed Rectangle Y
#    ...   | 4       | int        | Sprite Trimmed Rectangle Width
#    ...   | 4       | int        | Sprite Trimmed Rectangle Height
#       if (atlas.isFont)
#       {
		#  Additional font data (16 bytes)
#    ...   | 4       | int        | Character unicode value
#    ...   | 4       | int        | Character offset x
#    ...   | 4       | int        | Character offset y
#    ...   | 4       | int        | Character advance x
#       }
#  }
func import_rtpb(file: FileAccess, opt: Dictionary, source_file: String) -> Dictionary:
#	print(file)
	var data : Dictionary
	var bytes : PackedByteArray = file.get_buffer(file.get_length())
#	print(bytes)
	if opt.image == "":
		push_error("ERROR: You may need to set the image in the options, then reimport!")
	var img : Texture2D# = load(opt.image)
	if opt.image:
		img = load(opt.image)
	else:
		img = load(source_file.replace(".rtpb", ".png"))

	if not bytes.slice(0, 4).get_string_from_ascii() == "rTPb":
		prints("signature gotten as \"", bytes.slice(0,4).get_string_from_ascii(), "\", aborting.")
		return data
	if not bytes.decode_s32(12) == 0:
		prints("hmm", bytes.decode_s32(12))
		return data
	if bytes.decode_s32(16) == 1:
		push_error("Error: rTexPackerGd can't import font files.")
		return data
	
	var spr_count := bytes.decode_s32(8)
	var imgs : Array[PackedByteArray]

	for spr in spr_count:
		imgs.append(bytes.slice(24 + spr * 176, 24 + spr * 176 + 176))
	for im in imgs:
		var atlas := AtlasTexture.new()
		atlas.atlas = img

		var name := im.slice(0, 129).get_string_from_utf8()
		
		var ints : PackedInt32Array
		
		for j in 12:
			ints.append(im.decode_u32(128 + j * 4))
		
		
		if ints[7] == 1:
			atlas.region = Rect2i(ints[8], ints[9], ints[10] + ints[6], ints[11] + ints[6])
		else:
			atlas.region = Rect2i(ints[2], ints[3], ints[4] + ints[6], ints[5] + ints[6])
		
		data[name] = atlas
	
	return data

func import_json(file: FileAccess, opt: Dictionary) -> Dictionary:
	var data : Dictionary
	var img : Texture2D #= load(opt.image)
	
	var json := JSON.new()
	var j_data : Dictionary
	if json.parse(file.get_as_text()) == OK:
		j_data = json.data
	print(j_data)
	if j_data.has("software"):
		if j_data.software.has("name"):
			if not j_data.software.name.begins_with("rTexPacker"):
				return data
	if not j_data.has("sprites"):
		return data
	if j_data.atlas.isFont:
		push_error("Error: rTexPackerGd can't import font files.")
		return data
	
	for spr in j_data.sprites:
		var atlas := AtlasTexture.new()
		atlas.atlas = img
		if spr.trimmed:
			atlas.region = Rect2i(spr.trimRec.x, spr.trimRec.y, spr.trimRec.width + spr.padding, spr.trimRec.height + spr.padding)
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
