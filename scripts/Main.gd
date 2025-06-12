extends Node2D

var _cards: Array[Card] = []
var _previous_viewport_size := Vector2.ZERO
var _grids: Array[Grid] = []
var _end_button: Button
var _energy_label: Label
var _player_health_label: Label
var _enemy_health_label: Label
var _hover_label: Label
var _attack_label: Label
var _target_label: Label
const ENERGY_PER_TURN := 3
var _energy_available: int = ENERGY_PER_TURN
var _player_health: int = 0
var _enemy_health: int = 0
const HAZARDS_PER_ROUND := 4

# Sprite placeholders for an alien and a mech that appear behind the grids
var _alien_sprite: Sprite2D
var _mech_sprite: Sprite2D
var _alien_grid_idx: int = 1
var _mech_grid_idx: int = 0
var _current_alien_name: String = "alien"
var _current_mech_name: String = "mech"

const ALIEN_NAMES := ["alien", "alien2", "alien3", "alien4"]
const MECH_NAMES := ["mech", "mech2", "mech3", "mech4"]

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
    _current_mech_name = MECH_NAMES[randi_range(0, MECH_NAMES.size() - 1)]
    _current_alien_name = ALIEN_NAMES[randi_range(0, ALIEN_NAMES.size() - 1)]
    CHARACTER_DATA.reset_health()
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

    _player_health = CHARACTER_DATA.get_total_health(_current_mech_name)
    _enemy_health = CHARACTER_DATA.get_total_health(_current_alien_name)

    _player_health_label = Label.new()
    add_child(_player_health_label)
    _enemy_health_label = Label.new()
    add_child(_enemy_health_label)
    _update_health_labels()

    _hover_label = Label.new()
    _hover_label.visible = false
    add_child(_hover_label)

    _attack_label = Label.new()
    _attack_label.custom_minimum_size = Vector2(150, 40)
    _attack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    add_child(_attack_label)
    _update_attack_label_position()

    _target_label = Label.new()
    _target_label.custom_minimum_size = Vector2(150, 20)
    add_child(_target_label)
    _update_target_label_position()

    # Create sprite placeholders for the alien and mech behind the grids
    _alien_sprite = Sprite2D.new()
    _alien_sprite.texture = CHARACTER_DATA.get_texture(_current_alien_name)
    _alien_sprite.z_index = -1
    _alien_sprite.centered = false
    add_child(_alien_sprite)

    _alien_grid_idx = CHARACTER_DATA.get_grid_index(_current_alien_name)
    if _alien_grid_idx < 0:
        _alien_grid_idx = 1

    _mech_sprite = Sprite2D.new()
    _mech_sprite.texture = CHARACTER_DATA.get_texture(_current_mech_name)
    _mech_sprite.z_index = -1
    _mech_sprite.centered = false
    add_child(_mech_sprite)

    _mech_grid_idx = CHARACTER_DATA.get_grid_index(_current_mech_name)
    if _mech_grid_idx < 0:
        _mech_grid_idx = 0

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
        _update_attack_label_position()
        _update_target_label_position()

    _update_hover_label()

func _update_card_positions() -> void:
    var viewport_size := _previous_viewport_size
    var num_cards := _cards.size()
    var spacing := viewport_size.x / (num_cards + 1)
    var bottom_y := viewport_size.y - BOTTOM_MARGIN
    for i in range(num_cards):
        var card := _cards[i]
        if card.is_dragging:
            continue
        card.position = Vector2(spacing * (i + 1), bottom_y - card.size.y / 2.0)
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
    _update_attack_label_position()
    _update_target_label_position()

func _update_scale() -> void:
    var viewport_size := _previous_viewport_size
    var horiz := (viewport_size.x - GRID_MARGIN) / (Grid.COLS * 2)
    var base_ratio := Card.BASE_CARD_HEIGHT / Card.BASE_BLOCK_SIZE
    var vert := (viewport_size.y - GRID_VERTICAL_OFFSET * 2 - BOTTOM_MARGIN) / (Grid.ROWS * GRID_VERTICAL_SCALE + base_ratio)
    var new_size: int = max(1, int(floor(min(horiz, vert))))
    Grid.set_cell_size(new_size)
    Card.update_scale(new_size)
    _update_character_scale()
    _update_attack_label_position()
    _update_target_label_position()

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
    var groups := CHARACTER_DATA.get_shape_groups(_current_alien_name)
    var living: Array[String] = []
    for g in groups.keys():
        if CHARACTER_DATA.get_group_health(_current_alien_name, String(g)) > 0:
            living.append(String(g))
    if living.is_empty():
        _grids[_mech_grid_idx].highlight_random_cells(HAZARDS_PER_ROUND)
        if _attack_label:
            _attack_label.text = ""
        if _target_label:
            _target_label.text = ""
        return

    var text_lines: Array[String] = []
    var attack_cells: Array[Vector2i] = []

    var part := living[randi_range(0, living.size() - 1)]
    living.erase(part)
    var atk1 := _compute_attack(part)
    if atk1.shape != "":
        text_lines.append("%s - %s" % [part, atk1.shape])
        attack_cells.append_array(atk1.cells)
        if _target_label:
            _target_label.text = atk1.target
    else:
        text_lines.append(part)
        if _target_label:
            _target_label.text = ""

    if not living.is_empty():
        var part2 := living[randi_range(0, living.size() - 1)]
        var atk2 := _compute_attack(part2)
        if atk2.shape != "":
            text_lines.append("%s - %s" % [part2, atk2.shape])
            attack_cells.append_array(atk2.cells)
        else:
            text_lines.append(part2)

    if attack_cells.is_empty():
        _grids[_mech_grid_idx].highlight_random_cells(HAZARDS_PER_ROUND)
    else:
        _grids[_mech_grid_idx].highlight_attack(attack_cells)
    if _attack_label:
        _attack_label.text = "\n".join(text_lines)

func _apply_danger_damage() -> void:
    if _grids.size() < 2:
        return
    if _mech_sprite == null or _mech_sprite.texture == null:
        return
    var grid := _grids[_mech_grid_idx]
    var dmg := 0
    for c in grid.danger_cells:
        if grid.cells[c.x][c.y]:
            continue
        var center := grid.to_global(Vector2((c.x + 0.5) * Grid.CELL_SIZE, (c.y + 0.5) * Grid.CELL_SIZE))
        var group_name := CHARACTER_DATA.group_at_point(_current_mech_name, _mech_sprite, center)
        if group_name != "":
            CHARACTER_DATA.damage_group(_current_mech_name, group_name, 1)
            dmg += 1
    _player_health = CHARACTER_DATA.get_total_health(_current_mech_name)
    _update_health_labels()
    grid.clear_highlights()
    _update_character_scale()

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
    for g in _grids:
        g.clear_cells()
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
    _player_health_label.position = _grids[_mech_grid_idx].position + Vector2(grid_width / 2, -20)
    _enemy_health_label.position = _grids[_alien_grid_idx].position + Vector2(grid_width / 2, -20)

func _update_attack_label_position() -> void:
    if _attack_label == null:
        return
    var viewport_size := _previous_viewport_size
    _attack_label.position = Vector2(viewport_size.x - 160, 10)

func _update_target_label_position() -> void:
    if _target_label == null:
        return
    var viewport_size := _previous_viewport_size
    _target_label.position = Vector2(10, viewport_size.y / 2)

func _apply_damage(grid_idx: int, card: Card) -> void:
    if grid_idx == _alien_grid_idx and _alien_sprite and _alien_sprite.texture:
        var blocks: Array[Vector2] = card.get_global_block_positions()
        for b in blocks:
            var center := b + Vector2(Grid.CELL_SIZE / 2.0, Grid.CELL_SIZE / 2.0)
            var group_name := CHARACTER_DATA.group_at_point(_current_alien_name, _alien_sprite, center)
            if group_name != "":
                CHARACTER_DATA.damage_group(_current_alien_name, group_name, 1)
        _enemy_health = CHARACTER_DATA.get_total_health(_current_alien_name)
    _update_health_labels()
    _update_character_scale()


func _update_character_scale() -> void:
    var grid_width: float = Grid.COLS * Grid.CELL_SIZE
    var grid_height: float = Grid.ROWS * Grid.CELL_SIZE * GRID_VERTICAL_SCALE
    _update_sprite(_alien_sprite, _current_alien_name, grid_width, grid_height)
    _update_sprite(_mech_sprite, _current_mech_name, grid_width, grid_height)

func _update_sprite(sprite: Sprite2D, name: String, width: float, height: float) -> void:
    if sprite == null:
        return
    sprite.texture = CHARACTER_DATA.get_texture(name)
    sprite.centered = false
    sprite.offset = CHARACTER_DATA.get_top_left_offset(name)
    if sprite.texture:
        var tex_size: Vector2 = sprite.texture.get_size()
        var scale_x := width / tex_size.x if tex_size.x > 0 else 1.0
        var scale_y := height / tex_size.y if tex_size.y > 0 else 1.0
        sprite.scale = Vector2(scale_x, scale_y)

func _update_creature_positions() -> void:
    if _grids.size() < 2:
        return
    var positions: Array[Vector2] = []
    for g in _grids:
        positions.append(g.position)
    if _mech_sprite:
        var idx: int = clamp(_mech_grid_idx, 0, _grids.size() - 1)
        _mech_sprite.position = positions[idx]
    if _alien_sprite:
        var idx: int = clamp(_alien_grid_idx, 0, _grids.size() - 1)
        _alien_sprite.position = positions[idx]


func _update_hover_label() -> void:
    if _hover_label == null:
        return
    var mouse_pos := get_global_mouse_position()
    var group_name := CHARACTER_DATA.group_at_point(_current_alien_name, _alien_sprite, mouse_pos)
    var char_name := ""
    if group_name != "":
        char_name = _current_alien_name
    else:
        group_name = CHARACTER_DATA.group_at_point(_current_mech_name, _mech_sprite, mouse_pos)
        if group_name != "":
            char_name = _current_mech_name
    if group_name == "" or char_name == "":
        _hover_label.visible = false
        return
    var health := CHARACTER_DATA.get_group_health(char_name, group_name)
    _hover_label.text = group_name + " (" + str(health) + ")"
    _hover_label.position = mouse_pos + Vector2(10, 10)
    _hover_label.visible = true

# Helper used when positioning enemy attack shapes. Returns the bounding
# rectangle of the given block coordinates.
func _get_shape_bounds(blocks: Array[Vector2]) -> Rect2:
    if blocks.is_empty():
        return Rect2()
    var min_x := blocks[0].x
    var max_x := blocks[0].x
    var min_y := blocks[0].y
    var max_y := blocks[0].y
    for b in blocks:
        min_x = min(min_x, b.x)
        max_x = max(max_x, b.x)
        min_y = min(min_y, b.y)
        max_y = max(max_y, b.y)
    return Rect2(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

# Calculates the best attack for the given alien body part. Returns a
# dictionary with keys:
#   "cells"  -> Array of Vector2i positions to highlight on the mech grid
#   "shape"  -> Name of the attack shape
#   "target" -> Name of the mech body part being targeted
func _compute_attack(part: String) -> Dictionary:
    var result := {"cells": [], "shape": "", "target": ""}
    var shapes: Array = ATTACK_DATA.get_shapes_for_part(part, _current_alien_name)
    if shapes.is_empty():
        return result
    var shape_name := String(shapes[randi_range(0, shapes.size() - 1)])
    var blocks: Array[Vector2] = ShapeData.get_blocks(shape_name)
    if blocks.is_empty():
        return result
    var bounds := _get_shape_bounds(blocks)

    var mech_groups := CHARACTER_DATA.get_shape_groups(_current_mech_name)
    var mech_living: Array[String] = []
    for g in mech_groups.keys():
        if CHARACTER_DATA.get_group_health(_current_mech_name, String(g)) > 0:
            mech_living.append(String(g))
    if mech_living.is_empty():
        return result

    var best_cells: Array[Vector2i] = []
    var best_score := -1
    var best_part := ""
    for target in mech_living:
        var local_best_cells: Array[Vector2i] = []
        var local_best := -1
        for x in range(Grid.COLS - int(bounds.size.x) + 1):
            for y in range(Grid.ROWS - int(bounds.size.y) + 1):
                var cells: Array[Vector2i] = []
                for b in blocks:
                    var cx := int(b.x - int(bounds.position.x) + x)
                    var cy := int(b.y - int(bounds.position.y) + y)
                    cells.append(Vector2i(cx, cy))
                var score := 0
                for c in cells:
                    var center := _grids[_mech_grid_idx].to_global(Vector2((c.x + 0.5) * Grid.CELL_SIZE, (c.y + 0.5) * Grid.CELL_SIZE))
                    var gname := CHARACTER_DATA.group_at_point(_current_mech_name, _mech_sprite, center)
                    if gname == target and CHARACTER_DATA.get_group_health(_current_mech_name, gname) > 0:
                        score += 1
                if score > local_best:
                    local_best = score
                    local_best_cells = cells
        if local_best > best_score:
            best_score = local_best
            best_cells = local_best_cells
            best_part = target

    result["cells"] = best_cells
    result["shape"] = shape_name
    result["target"] = best_part
    return result

