extends Node
class_name CharacterData

# Provides scaled textures for the alien and mech sprites. Textures are
# regenerated whenever the grid cell size changes so that each pixel in the
# texture corresponds to a grid square.

const CHARACTERS_FILE := "res://data/characters.json"
const GRID := preload("res://scripts/Grid.gd")

static var _last_cell_size: int = -1

static var _characters: Dictionary = {}
static var _loaded := false
static var _bounds: Dictionary = {}
static var _offsets: Dictionary = {}

static func _check_cell_size() -> void:
    if _last_cell_size != GRID.CELL_SIZE:
        _bounds.clear()
        _offsets.clear()
        _last_cell_size = GRID.CELL_SIZE

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
    var r2 := float(radius * radius)
    var min_x := int(center.x - radius)
    var max_x := int(center.x + radius)
    var min_y := int(center.y - radius)
    var max_y := int(center.y + radius)
    for x in range(min_x, max_x + 1):
        if x < 0 or x >= img.get_width():
            continue
        for y in range(min_y, max_y + 1):
            if y < 0 or y >= img.get_height():
                continue
            var dx := float(x) - center.x
            var dy := float(y) - center.y
            if dx * dx + dy * dy <= r2:
                img.set_pixel(x, y, color)

static func _draw_rect(img: Image, pos: Vector2i, size: Vector2i, color: Color) -> void:
    var rect := Rect2i(pos, size)
    rect.position.x = clamp(rect.position.x, 0, img.get_width())
    rect.position.y = clamp(rect.position.y, 0, img.get_height())
    rect.size.x = clamp(rect.size.x, 0, img.get_width() - rect.position.x)
    rect.size.y = clamp(rect.size.y, 0, img.get_height() - rect.position.y)
    img.fill_rect(rect, color)

static func _generate_texture(desc: Dictionary) -> ImageTexture:
    var base_size := float(desc.get("size", 64))
    var size := int(GRID.CELL_SIZE * GRID.COLS)
    var ratio := float(size) / base_size
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
                        var ctr := Vector2(float(c_arr[0]) * ratio, float(c_arr[1]) * ratio)
                        var rad := int(float(s.get("radius", 0)) * ratio)
                        _draw_circle(img, ctr, rad, col)
                    "rect":
                        var p_arr: Array = s.get("position", [0, 0])
                        var sz_arr: Array = s.get("size", [1, 1])
                        var pos := Vector2i(int(round(float(p_arr[0]) * ratio)), int(round(float(p_arr[1]) * ratio)))
                        var sz := Vector2i(int(round(float(sz_arr[0]) * ratio)), int(round(float(sz_arr[1]) * ratio)))
                        _draw_rect(img, pos, sz, col)
    return ImageTexture.create_from_image(img)

static func get_texture(name: String) -> ImageTexture:
    _load_data()
    _check_cell_size()
    if _characters.has(name):
        return _generate_texture(_characters[name])
    return ImageTexture.new()

static func get_bounds(name: String) -> Vector2:
    _load_data()
    _check_cell_size()
    if _bounds.has(name):
        return _bounds[name]
    if not _characters.has(name):
        return Vector2.ZERO
    var desc: Dictionary = _characters[name]
    var scale := float(GRID.CELL_SIZE * GRID.COLS) / float(desc.get("size", 1))
    var size_px := float(GRID.CELL_SIZE * GRID.COLS)
    var min_x := size_px
    var min_y := size_px
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
                        var x0: float = float(p[0]) * scale
                        var y0: float = float(p[1]) * scale
                        var x1: float = x0 + float(sz[0]) * scale
                        var y1: float = y0 + float(sz[1]) * scale
                        min_x = min(min_x, x0)
                        min_y = min(min_y, y0)
                        max_x = max(max_x, x1)
                        max_y = max(max_y, y1)
                    "circle":
                        var ctr: Array = s.get("center", [0, 0])
                        var rad: float = float(s.get("radius", 0)) * scale
                        var x0 := float(ctr[0]) * scale - rad
                        var y0 := float(ctr[1]) * scale - rad
                        var x1 := float(ctr[0]) * scale + rad
                        var y1 := float(ctr[1]) * scale + rad
                        min_x = min(min_x, x0)
                        min_y = min(min_y, y0)
                        max_x = max(max_x, x1)
                        max_y = max(max_y, y1)
    var size := Vector2(max_x - min_x, max_y - min_y)
    _bounds[name] = size

    var img_size: float = float(GRID.CELL_SIZE * GRID.COLS)
    var center := Vector2((min_x + max_x) / 2.0, (min_y + max_y) / 2.0)
    var raw_offset := Vector2(img_size / 2.0 - center.x, img_size / 2.0 - center.y)
    var cell := float(GRID.CELL_SIZE)
    var offset := Vector2(round(raw_offset.x / cell) * cell,
        round(raw_offset.y / cell) * cell)
    _offsets[name] = offset
    return size

static func get_center_offset(name: String) -> Vector2:
    _load_data()
    _check_cell_size()
    if _offsets.has(name):
        return _offsets[name]
    get_bounds(name)
    return _offsets.get(name, Vector2.ZERO)

static func get_description(name: String) -> Dictionary:
    _load_data()
    if _characters.has(name):
        return _characters[name]
    return {}
