extends Node
class_name CharacterData

const CHARACTERS_FILE := "res://data/characters.json"

static var _characters: Dictionary = {}
static var _loaded := false

static func _load_data() -> void:
    if _loaded:
        return
    var file := FileAccess.open(CHARACTERS_FILE, FileAccess.READ)
    if file:
        var json_text := file.get_as_text()
        var data = JSON.parse_string(json_text)
        if typeof(data) == TYPE_DICTIONARY:
            _characters = data
    _loaded = true

static func _to_color(arr: Array) -> Color:
    var r: float = 0
    var g: float = 0
    var b: float = 0
    var a: float = 1
    if arr.size() >= 3:
        r = float(arr[0])
        g = float(arr[1])
        b = float(arr[2])
        if arr.size() >= 4:
            a = float(arr[3])
    return Color(r, g, b, a)

static func _draw_circle(img: Image, center: Vector2, radius: int, color: Color) -> void:
    for x in range(img.get_width()):
        for y in range(img.get_height()):
            if center.distance_to(Vector2(x, y)) <= radius:
                img.set_pixel(x, y, color)

static func _draw_rect(img: Image, pos: Vector2i, size: Vector2i, color: Color) -> void:
    for x in range(size.x):
        for y in range(size.y):
            var px := pos.x + x
            var py := pos.y + y
            if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
                img.set_pixel(px, py, color)

static func _generate_texture(desc: Dictionary) -> ImageTexture:
    var size := int(desc.get("size", 64))
    var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
    var base_col := _to_color(desc.get("base_color", [0, 0, 0, 0]))
    img.fill(base_col)
    var shapes: Array = desc.get("shapes", [])
    if shapes is Array:
        for s in shapes:
            if s is Dictionary:
                var col := _to_color(s.get("color", [1, 1, 1, 1]))
                match String(s.get("type", "")):
                    "circle":
                        var c_arr: Array = s.get("center", [size / 2, size / 2])
                        var ctr := Vector2(float(c_arr[0]), float(c_arr[1]))
                        var rad := int(s.get("radius", 0))
                        _draw_circle(img, ctr, rad, col)
                    "rect":
                        var p_arr: Array = s.get("position", [0, 0])
                        var sz_arr: Array = s.get("size", [1, 1])
                        var pos := Vector2i(int(p_arr[0]), int(p_arr[1]))
                        var sz := Vector2i(int(sz_arr[0]), int(sz_arr[1]))
                        _draw_rect(img, pos, sz, col)
    return ImageTexture.create_from_image(img)

static func get_texture(name: String) -> ImageTexture:
    _load_data()
    if _characters.has(name):
        return _generate_texture(_characters[name])
    return ImageTexture.new()
