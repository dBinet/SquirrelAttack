extends Node2D

var _cards: Array[Card] = []
var _previous_viewport_size := Vector2.ZERO
var _grids: Array[Grid] = []
var _end_button: Button
var _energy_label: Label
const ENERGY_PER_TURN := 3
var _energy_available: int = ENERGY_PER_TURN

const SHAPES := ["I", "L", "O", "T", "S", "Z"]
const CARD_SCENE := preload("res://scenes/Card.tscn")
const BOTTOM_MARGIN := 10.0
const GRID_MARGIN := 20.0
const GRID_VERTICAL_OFFSET := 50.0
const GRID_VERTICAL_SCALE := 0.9

func _ready():
    randomize()
    _previous_viewport_size = get_viewport_rect().size
    _grids = [get_node("LeftGrid"), get_node("RightGrid")]
    for g in _grids:
        g.scale = Vector2(1.0, GRID_VERTICAL_SCALE)

    _end_button = get_node_or_null("EndTurnButton")
    if _end_button:
        _end_button.text = "End Turn"
        _end_button.custom_minimum_size = Vector2(100, 30)
        _end_button.position = Vector2(10, 10)
        _end_button.pressed.connect(_on_EndTurnButton_pressed)

    _energy_label = Label.new()
    _energy_label.position = Vector2(120, 10)
    add_child(_energy_label)
    _update_energy_label()

    _add_random_cards()

    _update_scale()
    _update_card_positions()
    _position_grids()

func _process(delta):
    var current_size := get_viewport_rect().size
    if current_size != _previous_viewport_size:
        _previous_viewport_size = current_size
        _update_scale()
        _update_card_positions()
        _position_grids()

func _update_card_positions():
    var viewport_size := _previous_viewport_size
    var num_cards := _cards.size()
    var spacing := viewport_size.x / (num_cards + 1)
    for i in range(num_cards):
        var card := _cards[i]
        if card.is_dragging:
            continue
        var bottom_y: float = viewport_size.y - card.size.y / 2.0 - BOTTOM_MARGIN
        card.position = Vector2(spacing * (i + 1), bottom_y)
        card.set_original_position()

func _position_grids():
    if _grids.size() < 2:
        return
    var viewport_size := _previous_viewport_size
    var grid_width := Grid.COLS * Grid.CELL_SIZE
    var grid_height := Grid.ROWS * Grid.CELL_SIZE * GRID_VERTICAL_SCALE
    var pair_width := grid_width * 2 + GRID_MARGIN
    var start_x := (viewport_size.x - pair_width) / 2.0
    var top_y := (viewport_size.y - grid_height) / 2.0 - GRID_VERTICAL_OFFSET
    _grids[0].position = Vector2(start_x, top_y)
    _grids[1].position = Vector2(start_x + grid_width + GRID_MARGIN, top_y)

func _update_scale():
    var viewport_size := _previous_viewport_size
    var horiz := (viewport_size.x - GRID_MARGIN) / (Grid.COLS * 2)
    var base_ratio := Card.BASE_CARD_HEIGHT / Card.BASE_BLOCK_SIZE
    var vert := (viewport_size.y - GRID_VERTICAL_OFFSET * 2 - BOTTOM_MARGIN) / (Grid.ROWS * GRID_VERTICAL_SCALE + base_ratio)
    var new_size: int = int(floor(min(horiz, vert)))
    if new_size <= 0:
        new_size = 1
    Grid.set_cell_size(new_size)
    Card.update_scale(new_size)

func on_card_dropped(card: Card) -> bool:
    if _energy_available < card.energy_cost:
        return false
    for grid in _grids:
        if grid.try_place_piece(card):
            _cards.erase(card)
            card.queue_free()
            _energy_available -= card.energy_cost
            _update_energy_label()
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

func _discard_remaining_cards() -> void:
    for card in _cards:
        card.queue_free()
    _cards.clear()

func _add_random_cards(num: int = 5) -> void:
    for i in range(num):
        var shape_idx := randi_range(0, SHAPES.size() - 1)
        var card := CARD_SCENE.instantiate()
        card.shape_name = SHAPES[shape_idx]
        add_child(card)
        _cards.append(card)

func _on_EndTurnButton_pressed() -> void:
    _discard_remaining_cards()
    _add_random_cards()
    _update_card_positions()
    clear_previews()
    _energy_available = ENERGY_PER_TURN
    _update_energy_label()

func _update_energy_label() -> void:
    if _energy_label:
        _energy_label.text = "Energy: %d/%d" % [_energy_available, ENERGY_PER_TURN]

