extends Node2D
class_name Card

var card_name: String = ""
var value: int = 1

# Amount of energy required to play this card
const energy_cost: int = 1

# Name of the tetris shape for this card
var shape_name: String = "L"

var sprite: Sprite2D
var cost_label: Label

# Base sizes used prior to scaling
const BASE_CARD_WIDTH := 100
const BASE_CARD_HEIGHT := 150
const BASE_BLOCK_SIZE := 20

# Actual sizes updated when the viewport changes
static var card_width := BASE_CARD_WIDTH
static var card_height := BASE_CARD_HEIGHT
static var block_size := BASE_BLOCK_SIZE

static func update_scale(new_cell_size: float) -> void:
    block_size = new_cell_size
    var scale := new_cell_size / BASE_BLOCK_SIZE
    card_width = int(BASE_CARD_WIDTH * scale)
    card_height = int(BASE_CARD_HEIGHT * scale)
    var tree := Engine.get_main_loop()
    if tree is SceneTree:
        for c in tree.get_nodes_in_group("Cards"):
            if c is Card:
                c._update_textures()

var size := Vector2(card_width, card_height)
var card_texture: ImageTexture
var piece_texture: ImageTexture
var piece_size: Vector2
var is_transformed := false
var original_position: Vector2
var is_dragging := false
var drag_offset := Vector2.ZERO
var shape_bounds := Rect2()
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
    cost_label = get_node_or_null("CostLabel")
    if cost_label == null:
        cost_label = Label.new()
        add_child(cost_label)
    cost_label.text = str(energy_cost)
    cost_label.z_index = 1
    cost_label.add_theme_color_override("font_color", Color.BLACK)
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
            var parent = get_parent()
            if parent and parent.has_method("clear_previews"):
                parent.clear_previews()

func _process(delta):
    if is_dragging:
        position = get_global_mouse_position() + drag_offset
        var parent = get_parent()
        if parent and parent.has_method("preview_card_drag"):
            parent.preview_card_drag(self)

func _update_textures():
    var shape_blocks: Array = SHAPE_DATA.get(shape_name, SHAPE_DATA["L"])
    var blocks: Array[Vector2] = []
    blocks.assign(shape_blocks)
    shape_bounds = _get_shape_bounds(blocks)
    card_texture = _create_card_texture(blocks)
    piece_texture = _create_piece_texture(blocks)
    size = Vector2(card_width, card_height)
    if cost_label:
        cost_label.position = Vector2(-size.x / 2 + 5, -size.y / 2 + 5)
        cost_label.add_theme_font_size_override("font_size", int(block_size))

func _create_card_texture(blocks: Array[Vector2]) -> ImageTexture:
    var width := card_width
    var height := card_height
    var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
    img.fill(Color(1, 1, 1, 1))
    var black := Color(0, 0, 0, 1)

    var bounds := _get_shape_bounds(blocks)
    var shape_w := int(bounds.size.x) * block_size
    var shape_h := int(bounds.size.y) * block_size
    var start_x := int((width - shape_w) / 2) - int(bounds.position.x) * block_size
    var start_y := int((height - shape_h) / 2) - int(bounds.position.y) * block_size

    for block in blocks:
        for x in range(block_size):
            for y in range(block_size):
                var px: int = start_x + int(block.x) * block_size + x
                var py: int = start_y + int(block.y) * block_size + y
                img.set_pixel(px, py, black)

    return ImageTexture.create_from_image(img)

func _create_piece_texture(blocks: Array[Vector2]) -> ImageTexture:
    var bounds := _get_shape_bounds(blocks)
    var width := int(bounds.size.x) * block_size
    var height := int(bounds.size.y) * block_size
    var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
    img.fill(Color(0, 0, 0, 0))
    var black := Color(0, 0, 0, 1)
    for block in blocks:
        for x in range(block_size):
            for y in range(block_size):
                var px: int = (int(block.x) - int(bounds.position.x)) * block_size + x
                var py: int = (int(block.y) - int(bounds.position.y)) * block_size + y
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
    size = Vector2(card_width, card_height)
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
        var px: float = top_left.x + (b.x - shape_bounds.position.x) * block_size
        var py: float = top_left.y + (b.y - shape_bounds.position.y) * block_size
        positions.append(Vector2(px, py))
    return positions

