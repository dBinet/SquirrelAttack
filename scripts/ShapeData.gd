extends Node
class_name ShapeData

const SHAPES_FILE := "res://data/shapes.json"

static var _shapes: Dictionary = {}
static var _loaded := false

static func _load_data() -> void:
    if _loaded:
        return
    var file := FileAccess.open(SHAPES_FILE, FileAccess.READ)
    if file:
        var json_text := file.get_as_text()
        var data = JSON.parse_string(json_text)
        if typeof(data) == TYPE_DICTIONARY:
            _shapes = data
    _loaded = true

static func get_shapes() -> Dictionary:
    _load_data()
    return _shapes

static func get_shape_names() -> Array:
    _load_data()
    return _shapes.keys()

static func get_blocks(name: String) -> Array[Vector2]:
    _load_data()
    if _shapes.has(name) and _shapes[name].has("blocks"):
        var arr: Array = _shapes[name]["blocks"]
        var blocks: Array[Vector2] = []
        for b in arr:
            if b is Array and b.size() >= 2:
                blocks.append(Vector2(b[0], b[1]))
        return blocks
    return []

static func get_energy_cost(name: String) -> int:
    _load_data()
    if _shapes.has(name) and _shapes[name].has("energy_cost"):
        return int(_shapes[name]["energy_cost"])
    return 1
