extends Node2D

var _cards: Array[Card] = []
var _previous_viewport_size := Vector2.ZERO

func _ready():
    var card_scene := preload("res://scenes/Card.tscn")
    _previous_viewport_size = get_viewport_rect().size
    var viewport_size := _previous_viewport_size
    var num_cards := 5
    var spacing := viewport_size.x / (num_cards + 1)

    for i in range(num_cards):
        var card := card_scene.instantiate()
        add_child(card)
        _cards.append(card)
        var bottom_y: float = viewport_size.y - card.size.y / 2.0 - 10.0
        card.position = Vector2(
            spacing * (i + 1),
            bottom_y
        )
        card.set_original_position()

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
        var bottom_y: float = viewport_size.y - card.size.y / 2.0 - 10.0
        card.position = Vector2(
            spacing * (i + 1),
            bottom_y
        )
        card.set_original_position()

