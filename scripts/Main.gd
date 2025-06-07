extends Node2D

var _cards: Array[Card] = []
var _previous_viewport_size := Vector2.ZERO
var _grids: Array[Grid] = []

const SHAPES := ["I", "L", "O", "T", "S", "Z"]
const CARD_SCENE := preload("res://scenes/Card.tscn")
const BOTTOM_MARGIN := 10.0
const GRID_MARGIN := 20.0

func _ready():
    _previous_viewport_size = get_viewport_rect().size
    _grids = [get_node("LeftGrid"), get_node("RightGrid")]
    _position_grids()

    var available := SHAPES.duplicate()
    available.shuffle()
    var selected := available.slice(0, 5)

    for shape in selected:
        var card := CARD_SCENE.instantiate()
        card.shape_name = shape
        add_child(card)
        _cards.append(card)

    _update_card_positions()

func _process(delta):
    var current_size := get_viewport_rect().size
    if current_size != _previous_viewport_size:
        _previous_viewport_size = current_size
        _update_card_positions()
        _position_grids()

func _update_card_positions():
    var viewport_size := _previous_viewport_size
    var num_cards := _cards.size()
    var spacing := viewport_size.x / (num_cards + 1)
    for i in range(num_cards):
        var card := _cards[i]
        var bottom_y: float = viewport_size.y - card.size.y / 2.0 - BOTTOM_MARGIN
        card.position = Vector2(spacing * (i + 1), bottom_y)
        card.set_original_position()

func _position_grids():
    if _grids.size() < 2:
        return
    var viewport_size := _previous_viewport_size
    var grid_width := Grid.COLS * Grid.CELL_SIZE
    var pair_width := grid_width * 2 + GRID_MARGIN
    var start_x := (viewport_size.x - pair_width) / 2.0
    var top_y := GRID_MARGIN
    _grids[0].position = Vector2(start_x, top_y)
    _grids[1].position = Vector2(start_x + grid_width + GRID_MARGIN, top_y)

func on_card_dropped(card: Card) -> bool:
    for grid in _grids:
        if grid.try_place_piece(card):
            _cards.erase(card)
            card.queue_free()
            _update_card_positions()
            clear_previews()
            return true
    clear_previews()
    return false

func preview_card_drag(card: Card) -> void:
    for grid in _grids:
        grid.preview_piece(card)

func clear_previews() -> void:
    for grid in _grids:
        grid.clear_preview()

