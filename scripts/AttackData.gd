extends Node
class_name AttackData

const ATTACKS_FILE := "res://data/attacks.json"
const DATA_UTILS := preload("res://scripts/DataUtils.gd")

# Stores attack patterns keyed by character name then body part
# each entry is an array of 4-cell pattern arrays
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
                var patterns: Array = []
                if arr is Array:
                    for attack in arr:
                        if attack is Array:
                            var cells: Array[Vector2i] = []
                            for c in attack:
                                if c is Array:
                                    cells.append(DATA_UTILS.array_to_vector2i(c))
                            if cells.size() == 4:
                                patterns.append(cells)
                char_map[part] = patterns
            _attacks[char_key] = char_map
        elif char_val is Array:
            # Support legacy format storing patterns directly under the part name
            var patterns: Array = []
            for attack in char_val:
                if attack is Array:
                    var cells: Array[Vector2i] = []
                    for c in attack:
                        if c is Array:
                            cells.append(DATA_UTILS.array_to_vector2i(c))
                    if cells.size() == 4:
                        patterns.append(cells)
            if not _attacks.has("default"):
                _attacks["default"] = {}
            _attacks["default"][char_key] = patterns

static func get_attacks() -> Dictionary:
    _load_data()
    return _attacks.duplicate()

static func get_attacks_for_part(part: String, char_name: String = "") -> Array:
    _load_data()
    if char_name != "" and _attacks.has(char_name):
        var char_map: Dictionary = _attacks[char_name]
        if char_map.has(part):
            return char_map[part].duplicate()
    if _attacks.has("default") and _attacks["default"].has(part):
        return _attacks["default"][part].duplicate()
    return []

static func get_random_attack(part: String, char_name: String = "") -> Array[Vector2i]:
    var patterns: Array = get_attacks_for_part(part, char_name)
    if patterns.is_empty():
        return []
    return patterns[randi_range(0, patterns.size() - 1)].duplicate()
