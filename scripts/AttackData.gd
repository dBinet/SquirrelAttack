extends Node
class_name AttackData

const ATTACKS_FILE := "res://data/attacks.json"
const DATA_UTILS := preload("res://scripts/DataUtils.gd")

# Stores attack shapes keyed by character name then body part
# each entry is an array of shape name strings
static var _attacks: Dictionary = {}
static var _loaded: bool = false

static func _load_data() -> void:
    if _loaded:
        return
    _loaded = true
    var file := FileAccess.open(ATTACKS_FILE, FileAccess.READ)
    if file == null:
        return

    var json_text := file.get_as_text()
    var data: Variant = JSON.parse_string(json_text)
    if typeof(data) != TYPE_DICTIONARY:
        return

    for char_key in data.keys():
        var char_val = data[char_key]
        if char_val is Dictionary:
            var char_map: Dictionary = {}
            for part in char_val.keys():
                var arr: Array = char_val[part]
                var shapes: Array[String] = []
                if arr is Array:
                    for s in arr:
                        if typeof(s) == TYPE_STRING:
                            shapes.append(String(s))
                char_map[part] = shapes
            _attacks[char_key] = char_map
        elif char_val is Array:
            # Support legacy format storing shapes directly under the part name
            var shapes: Array[String] = []
            for s in char_val:
                if typeof(s) == TYPE_STRING:
                    shapes.append(String(s))
            if not _attacks.has("default"):
                _attacks["default"] = {}
            _attacks["default"][char_key] = shapes

static func get_attacks() -> Dictionary:
    _load_data()
    return _attacks.duplicate()

static func get_shapes_for_part(part: String, char_name: String = "") -> Array:
    _load_data()
    if char_name != "" and _attacks.has(char_name):
        var char_map: Dictionary = _attacks[char_name]
        if char_map.has(part):
            return char_map[part].duplicate()
    if _attacks.has("default") and _attacks["default"].has(part):
        return _attacks["default"][part].duplicate()
    return []

static func get_random_shape(part: String, char_name: String = "") -> String:
    var shapes: Array = get_shapes_for_part(part, char_name)
    if shapes.is_empty():
        return ""
    return shapes[randi_range(0, shapes.size() - 1)]
