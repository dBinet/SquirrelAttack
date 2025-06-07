extends Node2D
class_name Card

var card_name: String = ""
var value: int = 1

# Name of the tetris shape for this card
var shape_name: String = "L"

var sprite: Sprite2D
const CARD_WIDTH := 100
const CARD_HEIGHT := 150
const CARD_SIZE := Vector2(CARD_WIDTH, CARD_HEIGHT)
var size := CARD_SIZE
var card_texture: ImageTexture
var piece_texture: ImageTexture
var piece_size: Vector2
var is_transformed := false
var original_position: Vector2
var is_dragging := false
var drag_offset := Vector2.ZERO
var shape_bounds := Rect2()

const BLOCK_SIZE := 20
## Dictionary containing the coordinates for each tetromino.
# Using `var` instead of `const` avoids the constant-expression error when
# running on versions of Godot that do not treat `Vector2` constructors as
# compile-time constants.
var SHAPE_DATA := {
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
            if is_transformed:
                var parent = get_parent()
                if parent and parent.has_method("on_card_dropped"):
                    if parent.on_card_dropped(self):
                        return
                _transform_to_card()
            position = original_position

func _process(delta):
    if is_dragging:
        position = get_global_mouse_position() + drag_offset
        var parent = get_parent()
        if parent and parent.has_method("preview_card_drag"):
            parent.preview_card_drag(self)
    else:
        var parent = get_parent()
        if parent and parent.has_method("clear_previews"):
            parent.clear_previews()

func _update_textures():
    var shape_blocks: Array = SHAPE_DATA.get(shape_name, SHAPE_DATA["L"])
    var blocks: Array[Vector2] = []
    blocks.assign(shape_blocks)
    shape_bounds = _get_shape_bounds(blocks)
    card_texture = _create_card_texture(blocks)
    piece_texture = _create_piece_texture(blocks)

func _create_card_texture(blocks: Array[Vector2]) -> ImageTexture:
    var width := CARD_WIDTH
    var height := CARD_HEIGHT
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
    sprite.modulate = Color(1, 1, 1, 0.5)

func _transform_to_card():
    sprite.texture = card_texture
    size = CARD_SIZE
    is_transformed = false
    sprite.modulate = Color(1, 1, 1, 1)

func _is_in_bottom_third() -> bool:
    var viewport_size := get_viewport_rect().size
    return original_position.y > viewport_size.y * 2.0 / 3.0

func get_global_block_positions() -> Array[Vector2]:
    var blocks: Array = SHAPE_DATA.get(shape_name, SHAPE_DATA["L"])
    var top_left := position - size / 2.0
    var positions: Array[Vector2] = []
    for b in blocks:
        var px: float = top_left.x + (b.x - shape_bounds.position.x) * BLOCK_SIZE
        var py: float = top_left.y + (b.y - shape_bounds.position.y) * BLOCK_SIZE
        positions.append(Vector2(px, py))
    return positions

