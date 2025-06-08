extends Node
class_name CharacterData

const CHARACTERS_FILE := "res://data/characters.json"

static var _characters: Dictionary = {}
static var _loaded := false
static var _bounds: Dictionary = {}
static var _offsets: Dictionary = {}

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

static func get_bounds(name: String) -> Vector2:
    _load_data()
    if _bounds.has(name):
        return _bounds[name]
    if not _characters.has(name):
        return Vector2.ZERO
    var desc: Dictionary = _characters[name]
    var min_x := desc.get("size", 0)
    var min_y := desc.get("size", 0)
    var max_x := 0
    var max_y := 0
    var shapes: Array = desc.get("shapes", [])
    if shapes is Array:
        for s in shapes:
            if s is Dictionary:
                match String(s.get("type", "")):
                    "rect":
                        var p: Array = s.get("position", [0, 0])
                        var sz: Array = s.get("size", [0, 0])
                        var x0: float = float(p[0])
                        var y0: float = float(p[1])
                        var x1: float = x0 + float(sz[0])
                        var y1: float = y0 + float(sz[1])
                        min_x = min(min_x, x0)
                        min_y = min(min_y, y0)
                        max_x = max(max_x, x1)
                        max_y = max(max_y, y1)
                    "circle":
                        var ctr: Array = s.get("center", [0, 0])
                        var rad: float = float(s.get("radius", 0))
                        var x0 := float(ctr[0]) - rad
                        var y0 := float(ctr[1]) - rad
                        var x1 := float(ctr[0]) + rad
                        var y1 := float(ctr[1]) + rad
                        min_x = min(min_x, x0)
                        min_y = min(min_y, y0)
                        max_x = max(max_x, x1)
                        max_y = max(max_y, y1)
    var size := Vector2(max_x - min_x, max_y - min_y)
    _bounds[name] = size

    var img_size: float = float(desc.get("size", 0))
    var center := Vector2((min_x + max_x) / 2.0, (min_y + max_y) / 2.0)
    var offset := Vector2(img_size / 2.0 - center.x, img_size / 2.0 - center.y)
    _offsets[name] = offset
    return size

static func get_center_offset(name: String) -> Vector2:
    _load_data()
    if _offsets.has(name):
        return _offsets[name]
    get_bounds(name)
    return _offsets.get(name, Vector2.ZERO)
