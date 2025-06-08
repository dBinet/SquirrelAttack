extends Node2D

var _cards: Array[Card] = []
var _previous_viewport_size := Vector2.ZERO
var _grids: Array[Grid] = []
var _end_button: Button
var _energy_label: Label
var _player_health_label: Label
var _enemy_health_label: Label
const ENERGY_PER_TURN := 3
var _energy_available: int = ENERGY_PER_TURN
const STARTING_HEALTH := 10
var _player_health: int = STARTING_HEALTH
var _enemy_health: int = STARTING_HEALTH
const HAZARDS_PER_ROUND := 4

# Sprite placeholders for an alien and a mech that appear behind the grids
var _alien_sprite: Sprite2D
var _mech_sprite: Sprite2D

const CHARACTER_DATA = preload("res://scripts/CharacterData.gd")

const ATTACK_DATA = preload("res://scripts/AttackData.gd")

const CARD_SCENE := preload("res://scenes/Card.tscn")
const BOTTOM_MARGIN := 10.0
const GRID_MARGIN := 20.0
const GRID_VERTICAL_OFFSET := 50.0
const GRID_VERTICAL_SCALE := 0.9

var _shape_names: Array[String] = []

func _ready() -> void:
    randomize()
    _shape_names = ShapeData.get_shape_names()
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

    _player_health_label = Label.new()
    add_child(_player_health_label)
    _enemy_health_label = Label.new()
    add_child(_enemy_health_label)
    _update_health_labels()

    # Create sprite placeholders for the alien and mech behind the grids
    _alien_sprite = Sprite2D.new()
    _alien_sprite.texture = CHARACTER_DATA.get_texture("alien")
    _alien_sprite.z_index = -1
    add_child(_alien_sprite)

    _mech_sprite = Sprite2D.new()
    _mech_sprite.texture = CHARACTER_DATA.get_texture("mech")
    _mech_sprite.z_index = -1
    add_child(_mech_sprite)

    _add_random_cards()

    _update_scale()
    _update_card_positions()
    _position_grids()
    _highlight_new_round()

func _process(delta: float) -> void:
    var current_size := get_viewport_rect().size
    if current_size != _previous_viewport_size:
        _previous_viewport_size = current_size
        _update_scale()
        _update_card_positions()
        _position_grids()

func _update_card_positions() -> void:
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

func _position_grids() -> void:
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
    _update_health_label_positions()
    _update_creature_positions()

func _update_scale() -> void:
    var viewport_size := _previous_viewport_size
    var horiz := (viewport_size.x - GRID_MARGIN) / (Grid.COLS * 2)
    var base_ratio := Card.BASE_CARD_HEIGHT / Card.BASE_BLOCK_SIZE
    var vert := (viewport_size.y - GRID_VERTICAL_OFFSET * 2 - BOTTOM_MARGIN) / (Grid.ROWS * GRID_VERTICAL_SCALE + base_ratio)
    var new_size: int = max(1, int(floor(min(horiz, vert))))
    Grid.set_cell_size(new_size)
    Card.update_scale(new_size)
    _update_character_scale()

func on_card_dropped(card: Card) -> bool:
    if _energy_available < card.energy_cost:
        return false
    for idx in range(_grids.size()):
        var grid = _grids[idx]
        if grid.try_place_piece(card):
            _cards.erase(card)
            card.queue_free()
            _energy_available -= card.energy_cost
            _update_energy_label()
            _update_card_positions()
            clear_previews()
            _apply_damage(idx, card)
            return true
    clear_previews()
    return false

func preview_card_drag(card: Card) -> void:
    for grid in _grids:
        grid.preview_piece(card)

func clear_previews() -> void:
    for grid in _grids:
        grid.clear_preview()

func _highlight_new_round() -> void:
    if _grids.size() < 2:
        return
    var attack: Array[Vector2i] = ATTACK_DATA.get_random_attack()
    if attack.is_empty():
        _grids[1].highlight_random_cells(HAZARDS_PER_ROUND)
    else:
        _grids[1].highlight_attack(attack)

func _apply_danger_damage() -> void:
    if _grids.size() < 2:
        return
    var rect := Rect2()
    if _mech_sprite and _mech_sprite.texture:
        var tex_size := _mech_sprite.texture.get_size() * _mech_sprite.scale
        rect = Rect2(_mech_sprite.global_position - tex_size / 2.0, tex_size)
    var dmg := _grids[1].count_uncovered_highlights_in_rect(rect)
    _player_health -= dmg
    _update_health_labels()
    _grids[1].clear_highlights()

func _discard_remaining_cards() -> void:
    for card in _cards:
        card.queue_free()
    _cards.clear()

func _add_random_cards(num: int = 5) -> void:
    if _shape_names.is_empty():
        _shape_names = ShapeData.get_shape_names()
    for i in range(num):
        var shape_idx := randi_range(0, _shape_names.size() - 1)
        var card := CARD_SCENE.instantiate()
        card.shape_name = _shape_names[shape_idx]
        card.energy_cost = ShapeData.get_energy_cost(card.shape_name)
        add_child(card)
        _cards.append(card)

func _on_EndTurnButton_pressed() -> void:
    _apply_danger_damage()
    _discard_remaining_cards()
    _add_random_cards()
    _update_card_positions()
    clear_previews()
    _energy_available = ENERGY_PER_TURN
    _update_energy_label()
    _highlight_new_round()

func _update_energy_label() -> void:
    if _energy_label:
        _energy_label.text = "Energy: %d/%d" % [_energy_available, ENERGY_PER_TURN]

func _update_health_labels() -> void:
    if _player_health_label:
        _player_health_label.text = "HP: %d" % _player_health
    if _enemy_health_label:
        _enemy_health_label.text = "HP: %d" % _enemy_health

func _update_health_label_positions() -> void:
    if _grids.size() < 2:
        return
    var grid_width := Grid.COLS * Grid.CELL_SIZE
    _enemy_health_label.position = _grids[0].position + Vector2(grid_width / 2, -20)
    _player_health_label.position = _grids[1].position + Vector2(grid_width / 2, -20)

func _apply_damage(grid_idx: int, card: Card) -> void:
    var blocks: Array[Vector2] = ShapeData.get_blocks(card.shape_name)
    var dmg: int = blocks.size()
    if grid_idx == 0:
        _enemy_health -= dmg
    _update_health_labels()


func _update_character_scale() -> void:
    var grid_width: float = Grid.COLS * Grid.CELL_SIZE
    var grid_height: float = Grid.ROWS * Grid.CELL_SIZE * GRID_VERTICAL_SCALE

    if _alien_sprite and _alien_sprite.texture:
        var tex_size: Vector2 = _alien_sprite.texture.get_size()
        var factor_x: float = grid_width / tex_size.x if tex_size.x > 0 else 1.0
        var factor_y: float = grid_height / tex_size.y if tex_size.y > 0 else 1.0
        var factor: float = min(factor_x, factor_y)
        _alien_sprite.scale = Vector2(factor, factor)

    if _mech_sprite and _mech_sprite.texture:
        var tex_size: Vector2 = _mech_sprite.texture.get_size()
        var factor_x: float = grid_width / tex_size.x if tex_size.x > 0 else 1.0
        var factor_y: float = grid_height / tex_size.y if tex_size.y > 0 else 1.0
        var factor: float = min(factor_x, factor_y)
        _mech_sprite.scale = Vector2(factor, factor)

func _update_creature_positions() -> void:
    if _grids.size() < 2:
        return
    var grid_width := Grid.COLS * Grid.CELL_SIZE
    var grid_height := Grid.ROWS * Grid.CELL_SIZE * GRID_VERTICAL_SCALE
    var alien_off: Vector2 = CHARACTER_DATA.get_center_offset("alien") * _alien_sprite.scale.x
    var mech_off: Vector2 = CHARACTER_DATA.get_center_offset("mech") * _mech_sprite.scale.x
    _alien_sprite.position = _grids[0].position + Vector2(grid_width / 2, grid_height / 2) + alien_off
    _mech_sprite.position = _grids[1].position + Vector2(grid_width / 2, grid_height / 2) + mech_off

