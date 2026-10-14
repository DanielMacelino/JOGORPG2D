extends RefCounted
## Positional field lists avoid serializing thousands of repeated property names.
static func encode(packet: Dictionary, schema: Dictionary) -> PackedByteArray:
	var packed := packet.duplicate()
	var rows: Array = []
	for row in packet.rows:
		var values: Array = []
		for field in schema[str(row.type)]:
			values.append(row.v[field])
		var metadata: Dictionary = row.duplicate()
		for key in ["id", "type", "p", "v"]:
			metadata.erase(key)
		rows.append([row.id, row.type, row.p, values, metadata])
	packed.rows = rows
	return var_to_bytes(packed).compress(FileAccess.COMPRESSION_DEFLATE)

static func decode(bytes: PackedByteArray, schema: Dictionary) -> Dictionary:
	var decoded: Variant = bytes_to_var(bytes.decompress_dynamic(1048576, FileAccess.COMPRESSION_DEFLATE))
	if not decoded is Dictionary or not decoded.get("rows") is Array:
		return {}
	var rows: Array = []
	for data in decoded.rows:
		if not data is Array or data.size() != 5 or not schema.has(str(data[1])) or not data[3] is Array or data[3].size() != schema[str(data[1])].size() or not data[4] is Dictionary:
			return {}
		var values := {}
		var fields: Array = schema[str(data[1])]
		for index in fields.size():
			values[fields[index]] = data[3][index]
		var row: Dictionary = data[4].duplicate()
		row.merge({"id": data[0], "type": data[1], "p": data[2], "v": values})
		rows.append(row)
	decoded.rows = rows
	return decoded
