extends Node2D

var card_name: String = ""
var value: int = 1

func _ready():
    var sprite := Sprite2D.new()
    sprite.texture = _create_card_texture()
    sprite.centered = true
    add_child(sprite)

func _create_card_texture() -> ImageTexture:
    var width := 100
    var height := 150
    var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
    img.fill(Color(1, 1, 1, 1))
    img.lock()
    var black := Color(0, 0, 0, 1)

    for y in range(30, height - 20):
        img.set_pixel(width / 2, y, black)

    for x in range(width / 2 - 10, width / 2 + 10):
        img.set_pixel(x, 30, black)

    img.unlock()
    var tex := ImageTexture.create_from_image(img)
    return tex

