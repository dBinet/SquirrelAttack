extends Node
class_name AttackData

const ATTACKS_FILE := "res://data/attacks.json"
const DATA_UTILS := preload("res://scripts/DataUtils.gd")

# Stores attack patterns keyed by body part name
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

    for part in data.keys():
        var arr: Array = data[part]
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
        _attacks[part] = patterns

static func get_attacks() -> Dictionary:
    _load_data()
    return _attacks.duplicate()

static func get_attacks_for_part(part: String) -> Array:
    _load_data()
    if _attacks.has(part):
        return _attacks[part].duplicate()
    return []

static func get_random_attack(part: String) -> Array[Vector2i]:
    var patterns: Array = get_attacks_for_part(part)
    if patterns.is_empty():
        return []
    return patterns[randi_range(0, patterns.size() - 1)].duplicate()
