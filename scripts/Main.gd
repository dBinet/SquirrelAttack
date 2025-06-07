extends Node2D

func _ready():
    var card_scene := preload("res://scenes/Card.tscn")
    var viewport_size := get_viewport_rect().size
    var num_cards := 5
    var spacing := viewport_size.x / (num_cards + 1)

    for i in range(num_cards):
        var card := card_scene.instantiate()
        add_child(card)
        card.position = Vector2(
            spacing * (i + 1),
            viewport_size.y * 5.0 / 6.0
        )
        card.set_original_position()

