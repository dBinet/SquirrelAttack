extends Node
class_name CharacterData

# Provides scaled textures for the alien and mech sprites. Textures are
# regenerated whenever the grid cell size changes so that each pixel in the
# texture corresponds to a grid square.

const CHARACTERS_FILE := "res://data/characters.json"
const GRID := preload("res://scripts/Grid.gd")
const DEFAULT_OUTLINE_COLOR := Color.BLACK

static var _last_cell_size: int = -1

static var _characters: Dictionary = {}
static var _loaded := false
static var _bounds: Dictionary = {}
static var _offsets: Dictionary = {}
static var _top_left_offsets: Dictionary = {}

static func _check_cell_size() -> void:
    if _last_cell_size != GRID.CELL_SIZE:
        _bounds.clear()
        _offsets.clear()
        _top_left_offsets.clear()
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

static func _get_outline_color(desc: Dictionary) -> Color:
    var arr = desc.get("outline_color")
    if arr is Array:
        return _to_color(arr)
    return DEFAULT_OUTLINE_COLOR

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

static func _draw_circle_outline(img: Image, center: Vector2, radius: int, color: Color) -> void:
    if radius <= 0:
        return
    var r2_outer := float(radius * radius)
    var r2_inner := float((radius - 1) * (radius - 1))
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
            var d2 := dx * dx + dy * dy
            if d2 <= r2_outer and d2 >= r2_inner:
                img.set_pixel(x, y, color)

static func _draw_rect(img: Image, pos: Vector2i, size: Vector2i, color: Color) -> void:
    var rect := Rect2i(pos, size)
    var img_rect := Rect2i(Vector2i.ZERO, img.get_size())
    rect = rect.intersection(img_rect)
    if rect.size.x <= 0 or rect.size.y <= 0:
        return
    img.fill_rect(rect, color)

static func _draw_rect_outline(img: Image, pos: Vector2i, size: Vector2i, color: Color) -> void:
    if size.x <= 0 or size.y <= 0:
        return
    var x0 := pos.x
    var y0 := pos.y
    var x1 := pos.x + size.x - 1
    var y1 := pos.y + size.y - 1
    for x in range(x0, x1 + 1):
        if x >= 0 and x < img.get_width():
            if y0 >= 0 and y0 < img.get_height():
                img.set_pixel(x, y0, color)
            if y1 >= 0 and y1 < img.get_height():
                img.set_pixel(x, y1, color)
    for y in range(y0, y1 + 1):
        if y >= 0 and y < img.get_height():
            if x0 >= 0 and x0 < img.get_width():
                img.set_pixel(x0, y, color)
            if x1 >= 0 and x1 < img.get_width():
                img.set_pixel(x1, y, color)

static func _extract_all_shapes(data: Variant) -> Array:
    var result: Array = []
    if data is Array:
        for s in data:
            if s is Dictionary:
                result.append(s)
    elif data is Dictionary:
        for v in data.values():
            if v is Array:
                for s in v:
                    if s is Dictionary:
                        result.append(s)
    return result

static func _generate_texture(desc: Dictionary) -> ImageTexture:
    var base_size := float(desc.get("size", 64))
    var size := int(GRID.CELL_SIZE * GRID.COLS)
    var ratio := float(size) / base_size

    var shapes: Array = _extract_all_shapes(desc.get("shapes", []))
    var offset_x: float = 0.0
    var offset_y: float = 0.0

    var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
    var base_col := _to_color(desc.get("base_color", [0, 0, 0, 0]))
    var outline_col := _get_outline_color(desc)
    img.fill(base_col)
    for s in shapes:
        var col := _to_color(s.get("color", [1, 1, 1, 1]))
        match String(s.get("type", "")):
            "circle":
                var c_arr: Array = s.get("center", [size / 2, size / 2])
                var ctr := Vector2((float(c_arr[0]) + offset_x) * ratio, (float(c_arr[1]) + offset_y) * ratio)
                var rad := int(float(s.get("radius", 0)) * ratio)
                _draw_circle(img, ctr, rad, col)
                _draw_circle_outline(img, ctr, rad, outline_col)
            "rect":
                var p_arr: Array = s.get("position", [0, 0])
                var sz_arr: Array = s.get("size", [1, 1])
                var pos := Vector2i(int(round((float(p_arr[0]) + offset_x) * ratio)), int(round((float(p_arr[1]) + offset_y) * ratio)))
                var sz := Vector2i(int(round(float(sz_arr[0]) * ratio)), int(round(float(sz_arr[1]) * ratio)))
                _draw_rect(img, pos, sz, col)
                _draw_rect_outline(img, pos, sz, outline_col)
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
    var max_x := 0.0
    var max_y := 0.0
    var shapes: Array = _extract_all_shapes(desc.get("shapes", []))
    if shapes.size() > 0:
        for s in shapes:
            match String(s.get("type", "")):
                "rect":
                    var p: Array = s.get("position", [0, 0])
                    var sz: Array = s.get("size", [0, 0])
                    var x_end: float = (float(p[0]) + float(sz[0])) * scale
                    var y_end: float = (float(p[1]) + float(sz[1])) * scale
                    max_x = max(max_x, x_end)
                    max_y = max(max_y, y_end)
                "circle":
                    var ctr: Array = s.get("center", [0, 0])
                    var rad: float = float(s.get("radius", 0)) * scale
                    var x_end: float = float(ctr[0]) * scale + rad
                    var y_end: float = float(ctr[1]) * scale + rad
                    max_x = max(max_x, x_end)
                    max_y = max(max_y, y_end)

    var size := Vector2(max_x, max_y)
    _bounds[name] = size

    var img_size: float = float(GRID.CELL_SIZE * GRID.COLS)
    var center := Vector2(max_x / 2.0, max_y / 2.0)
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

static func get_top_left_offset(name: String) -> Vector2:
    _load_data()
    _check_cell_size()
    if _top_left_offsets.has(name):
        return _top_left_offsets[name]
    if not _characters.has(name):
        _top_left_offsets[name] = Vector2.ZERO
        return Vector2.ZERO
    var desc: Dictionary = _characters[name]
    var scale := float(GRID.CELL_SIZE * GRID.COLS) / float(desc.get("size", 1))
    var min_x := 0.0
    var min_y := 0.0
    var shapes: Array = _extract_all_shapes(desc.get("shapes", []))
    if shapes.size() > 0:
        min_x = INF
        min_y = INF
        for s in shapes:
            match String(s.get("type", "")):
                "rect":
                    var p: Array = s.get("position", [0, 0])
                    min_x = min(min_x, float(p[0]) * scale)
                    min_y = min(min_y, float(p[1]) * scale)
                "circle":
                    var c: Array = s.get("center", [0, 0])
                    var r: float = float(s.get("radius", 0)) * scale
                    min_x = min(min_x, float(c[0]) * scale - r)
                    min_y = min(min_y, float(c[1]) * scale - r)
    var cell := float(GRID.CELL_SIZE)
    var offset := Vector2(-min_x, -min_y)
    offset.x = round(offset.x / cell) * cell
    offset.y = round(offset.y / cell) * cell
    _top_left_offsets[name] = offset
    return offset

static func get_description(name: String) -> Dictionary:
    _load_data()
    if _characters.has(name):
        return _characters[name]
    return {}

# Returns the grid index for a character. Recognizes string values "left" and
# "right" or an integer index. Returns -1 if unspecified.
static func get_grid_index(name: String) -> int:
    _load_data()
    if not _characters.has(name):
        return -1
    var grid_val = _characters[name].get("grid", -1)
    if typeof(grid_val) == TYPE_STRING:
        var lower := String(grid_val).to_lower()
        if lower == "left":
            return 0
        elif lower == "right":
            return 1
    elif typeof(grid_val) == TYPE_INT:
        return int(grid_val)
    return -1

# Returns a dictionary mapping group names to arrays of shape dictionaries for
# the given character. If the shapes are not organized by group, the returned
# dictionary contains a single entry with an empty string as the key.
static func get_shape_groups(name: String) -> Dictionary:
    _load_data()
    if not _characters.has(name):
        return {}
    var shapes = _characters[name].get("shapes")
    if typeof(shapes) == TYPE_DICTIONARY:
        return shapes
    elif shapes is Array:
        return {"": shapes}
    return {}
