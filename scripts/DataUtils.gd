extends Node
class_name DataUtils

static func to_color(arr: Array) -> Color:
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

static func array_to_vector2i(arr: Array) -> Vector2i:
    if arr.size() >= 2:
        return Vector2i(int(arr[0]), int(arr[1]))
    return Vector2i.ZERO
