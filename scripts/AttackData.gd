extends Node
class_name AttackData

const ATTACKS_FILE := "res://data/attacks.json"

static var _attacks: Array = []
static var _loaded := false

static func _load_data() -> void:
    if _loaded:
        return
    var file := FileAccess.open(ATTACKS_FILE, FileAccess.READ)
    if file:
        var json_text := file.get_as_text()
        var data = JSON.parse_string(json_text)
        if typeof(data) == TYPE_DICTIONARY and data.has("attacks"):
            var arr := data["attacks"]
            if arr is Array:
                for attack in arr:
                    if attack is Array:
                        var cells: Array[Vector2i] = []
                        for c in attack:
                            if c is Array and c.size() >= 2:
                                cells.append(Vector2i(int(c[0]), int(c[1])))
                        if cells.size() == 4:
                            _attacks.append(cells)
    _loaded = true

static func get_attacks() -> Array:
    _load_data()
    return _attacks.duplicate()

static func get_random_attack() -> Array[Vector2i]:
    _load_data()
    if _attacks.is_empty():
        return []
    var idx := randi_range(0, _attacks.size() - 1)
    return _attacks[idx].duplicate()
