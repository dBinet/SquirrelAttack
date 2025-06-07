extends Node2D

var card_name: String = ""
var value: int = 1

var sprite: Sprite2D
var size := Vector2(100, 150)
var original_position: Vector2
var is_dragging := false
var drag_offset := Vector2.ZERO

func _ready():
    original_position = position
    sprite = Sprite2D.new()
    sprite.texture = _create_card_texture()
    sprite.centered = true
    add_child(sprite)

func set_original_position():
    original_position = position

func _input(event):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        var mouse_pos = get_global_mouse_position()
        var rect = Rect2(position - size / 2, size)
        if event.pressed and !is_dragging:
            if rect.has_point(mouse_pos):
                is_dragging = true
                drag_offset = position - mouse_pos
                original_position = position
        elif !event.pressed and is_dragging:
            is_dragging = false
            position = original_position

func _process(delta):
    if is_dragging:
        position = get_global_mouse_position() + drag_offset

func _create_card_texture() -> ImageTexture:
    var width := 100
    var height := 150
    var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
    img.fill(Color(1, 1, 1, 1))
    var black := Color(0, 0, 0, 1)

    for y in range(30, height - 20):
        img.set_pixel(width / 2, y, black)

    for x in range(width / 2 - 10, width / 2 + 10):
        img.set_pixel(x, 30, black)

    var tex := ImageTexture.create_from_image(img)
    return tex


