extends Node2D

var _cards: Array[Card] = []
var _previous_viewport_size := Vector2.ZERO

const SHAPES := ["I", "L", "O", "T", "S", "Z"]
const CARD_SCENE := preload("res://scenes/Card.tscn")
const BOTTOM_MARGIN := 10.0

func _ready():
    _previous_viewport_size = get_viewport_rect().size

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

func _update_card_positions():
    var viewport_size := _previous_viewport_size
    var num_cards := _cards.size()
    var spacing := viewport_size.x / (num_cards + 1)
    for i in range(num_cards):
        var card := _cards[i]
        var bottom_y: float = viewport_size.y - card.size.y / 2.0 - BOTTOM_MARGIN
        card.position = Vector2(spacing * (i + 1), bottom_y)
        card.set_original_position()

