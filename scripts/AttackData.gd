extends Node
class_name AttackData

const ATTACKS_FILE := "res://data/attacks.json"
const DATA_UTILS := preload("res://scripts/DataUtils.gd")

static var _attacks: Array = []
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
    if typeof(data) != TYPE_DICTIONARY or not data.has("attacks"):
        return

    var arr: Array = data["attacks"]
    if arr is Array:
        for attack in arr:
            if attack is Array:
                var cells: Array[Vector2i] = []
                for c in attack:
                    if c is Array:
                        cells.append(DATA_UTILS.array_to_vector2i(c))
                if cells.size() == 4:
                    _attacks.append(cells)

static func get_attacks() -> Array:
    _load_data()
    return _attacks.duplicate()

static func get_random_attack() -> Array[Vector2i]:
    _load_data()
    if _attacks.is_empty():
        return []
    return _attacks[randi_range(0, _attacks.size() - 1)].duplicate()
