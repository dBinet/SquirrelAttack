extends Node2D

func _ready():
    var card_scene := preload("res://scenes/Card.tscn")
    var card := card_scene.instantiate()
    add_child(card)
