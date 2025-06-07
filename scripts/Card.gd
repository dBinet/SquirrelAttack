extends Node2D
class_name Card

var card_name: String = ""
var value: int = 1

# Name of the tetris shape for this card
var shape_name: String = "L"

var sprite: Sprite2D
var size := Vector2(100, 150)
var card_texture: ImageTexture
var piece_texture: ImageTexture
var piece_size: Vector2
var is_transformed := false
var original_position: Vector2
var is_dragging := false
var drag_offset := Vector2.ZERO

const BLOCK_SIZE := 20
const SHAPE_DATA := {
    "I": [Vector2(0,0), Vector2(1,0), Vector2(2,0), Vector2(3,0)],
    "L": [Vector2(0,0), Vector2(0,1), Vector2(0,2), Vector2(1,2)],
    "O": [Vector2(0,0), Vector2(1,0), Vector2(0,1), Vector2(1,1)],
    "T": [Vector2(1,0), Vector2(0,1), Vector2(1,1), Vector2(2,1)],
    "S": [Vector2(1,0), Vector2(2,0), Vector2(0,1), Vector2(1,1)],
    "Z": [Vector2(0,0), Vector2(1,0), Vector2(1,1), Vector2(2,1)]
}

func _ready():
    original_position = position
    sprite = Sprite2D.new()
    add_child(sprite)
    _update_textures()
    sprite.texture = card_texture
    sprite.centered = true

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

func _update_textures():
    var blocks: Array[Vector2] = SHAPE_DATA.get(shape_name, SHAPE_DATA["L"])
    card_texture = _create_card_texture(blocks)
    piece_texture = _create_piece_texture(blocks)

func _create_card_texture(blocks: Array[Vector2]) -> ImageTexture:
    var width := 100
    var height := 150
    var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
    img.fill(Color(1, 1, 1, 1))
    var black := Color(0, 0, 0, 1)

    var bounds := _get_shape_bounds(blocks)
    var shape_w := int(bounds.size.x) * BLOCK_SIZE
    var shape_h := int(bounds.size.y) * BLOCK_SIZE
    var start_x := int((width - shape_w) / 2) - int(bounds.position.x) * BLOCK_SIZE
    var start_y := int((height - shape_h) / 2) - int(bounds.position.y) * BLOCK_SIZE

    for block in blocks:
        for x in range(BLOCK_SIZE):
            for y in range(BLOCK_SIZE):
                var px: int = start_x + int(block.x) * BLOCK_SIZE + x
                var py: int = start_y + int(block.y) * BLOCK_SIZE + y
                img.set_pixel(px, py, black)

    return ImageTexture.create_from_image(img)

func _create_piece_texture(blocks: Array[Vector2]) -> ImageTexture:
    var bounds := _get_shape_bounds(blocks)
    var width := int(bounds.size.x) * BLOCK_SIZE
    var height := int(bounds.size.y) * BLOCK_SIZE
    var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    var black := Color(0, 0, 0, 1)
    for block in blocks:
        for x in range(BLOCK_SIZE):
            for y in range(BLOCK_SIZE):
                var px: int = (int(block.x) - int(bounds.position.x)) * BLOCK_SIZE + x
                var py: int = (int(block.y) - int(bounds.position.y)) * BLOCK_SIZE + y
                img.set_pixel(px, py, black)
    piece_size = Vector2(width, height)
    return ImageTexture.create_from_image(img)

func _get_shape_bounds(blocks: Array[Vector2]) -> Rect2:
    var min_x: float = blocks[0].x
    var max_x: float = blocks[0].x
    var min_y: float = blocks[0].y
    var max_y: float = blocks[0].y
    for b in blocks:
        min_x = min(min_x, b.x)
        max_x = max(max_x, b.x)
        min_y = min(min_y, b.y)
        max_y = max(max_y, b.y)
    return Rect2(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func _transform_to_piece():
    sprite.texture = piece_texture
    size = piece_size
    is_transformed = true

func _transform_to_card():
    sprite.texture = card_texture
    size = Vector2(100, 150)
    is_transformed = false

func _is_in_bottom_third() -> bool:
    var viewport_size := get_viewport_rect().size
    return original_position.y > viewport_size.y * 2.0 / 3.0

