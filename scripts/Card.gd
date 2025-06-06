extends Node2D

var card_name: String = ""
var value: int = 1

func _ready():
    var color_rect := ColorRect.new()
    color_rect.color = Color(1, 1, 1)
    color_rect.custom_minimum_size = Vector2(100, 150)
    add_child(color_rect)

    var label := Label.new()
    label.text = str(value)
    label.anchor_left = 0
    label.anchor_top = 0
    label.anchor_right = 1
    label.anchor_bottom = 1
    label.offset_left = 0
    label.offset_top = 0
    label.offset_right = 0
    label.offset_bottom = 0
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    color_rect.add_child(label)
