extends Node2D
class_name Card

var card_name: String = ""
var value: int = 1

var sprite: Sprite2D
var size := Vector2(100, 150)
var card_texture: ImageTexture
var piece_texture: ImageTexture
var is_transformed := false
var original_position: Vector2
var is_dragging := false
var drag_offset := Vector2.ZERO

func _ready():
    original_position = position
    sprite = Sprite2D.new()
    card_texture = _create_card_texture()
    piece_texture = _create_piece_texture()
    sprite.texture = card_texture
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
                if _is_in_bottom_third():
                    _transform_to_piece()
        elif !event.pressed and is_dragging:
            is_dragging = false
            position = original_position
            if is_transformed:
                _transform_to_card()

func _process(delta):
    if is_dragging:
        position = get_global_mouse_position() + drag_offset

func _create_card_texture() -> ImageTexture:
    var width := 100
    var height := 150
    var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
    img.fill(Color(1, 1, 1, 1))
    var black := Color(0, 0, 0, 1)

    var block_size := 20
    var start_x := int((width - block_size * 2) / 2)
    var start_y := int((height - block_size * 3) / 2)
    var blocks := [
        Vector2(0, 0),
        Vector2(0, 1),
        Vector2(0, 2),
        Vector2(1, 2)
    ]

    for block in blocks:
        for x in range(block_size):
            for y in range(block_size):
                var px: int = start_x + int(block.x) * block_size + x
                var py: int = start_y + int(block.y) * block_size + y
                img.set_pixel(px, py, black)

    var tex := ImageTexture.create_from_image(img)
    return tex

func _create_piece_texture() -> ImageTexture:
    var block_size := 20
    var width := block_size * 2
    var height := block_size * 3
    var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    var black := Color(0, 0, 0, 1)
    var blocks := [
        Vector2(0, 0),
        Vector2(0, 1),
        Vector2(0, 2),
        Vector2(1, 2)
    ]
    for block in blocks:
        for x in range(block_size):
            for y in range(block_size):
                var px: int = int(block.x) * block_size + x
                var py: int = int(block.y) * block_size + y
                img.set_pixel(px, py, black)
    var tex := ImageTexture.create_from_image(img)
    return tex

func _transform_to_piece():
    sprite.texture = piece_texture
    size = Vector2(40, 60)
    is_transformed = true

func _transform_to_card():
    sprite.texture = card_texture
    size = Vector2(100, 150)
    is_transformed = false

func _is_in_bottom_third() -> bool:
    var viewport_size := get_viewport_rect().size
    return original_position.y > viewport_size.y * 2.0 / 3.0


