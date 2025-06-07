extends Node2D
class_name Grid

const COLS := 10
const ROWS := 20
# Base cell size used to compute scaling
const BASE_CELL_SIZE := 20

# Actual cell size used for drawing. Updated by `Main.gd` when the
# viewport changes to keep the grids relative to the screen size.
static var CELL_SIZE := BASE_CELL_SIZE

static func set_cell_size(new_size: float) -> void:
    CELL_SIZE = new_size
    # Redraw all existing grid instances when the cell size changes.
    var tree := Engine.get_main_loop()
    if tree is SceneTree:
        for grid in tree.get_nodes_in_group("GridInstances"):
            if grid is Grid:
                grid.queue_redraw()

var cells: Array = []
var preview_cells: Array[Vector2i] = []

func _get_piece_indices(card) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    if not card.has_method("get_global_block_positions"):
        return result
    var positions: Array[Vector2] = card.get_global_block_positions()
    if positions.is_empty():
        return result

    # Use the first block as the alignment reference. The piece must be
    # reasonably close to the grid so that all blocks share the same offset.
    var first_local := to_local(positions[0])
    var cell_x := first_local.x / CELL_SIZE
    var cell_y := first_local.y / CELL_SIZE
    var off_x := cell_x - round(cell_x)
    var off_y := cell_y - round(cell_y)
    if abs(off_x) > 0.25 or abs(off_y) > 0.25:
        return result

    for pos in positions:
        var local := to_local(pos)
        var lx := local.x / CELL_SIZE - off_x
        var ly := local.y / CELL_SIZE - off_y
        if abs(lx - round(lx)) > 0.25 or abs(ly - round(ly)) > 0.25:
            return []
        var ix := int(round(lx))
        var iy := int(round(ly))
        result.append(Vector2i(ix, iy))
    return result

func _ready():
    for x in range(COLS):
        cells.append([])
        for y in range(ROWS):
            cells[x].append(false)
    queue_redraw()

func _draw():
    var width := COLS * CELL_SIZE
    var height := ROWS * CELL_SIZE
    var line_color := Color(0.7, 0.7, 0.7)
    for x in range(COLS + 1):
        draw_line(Vector2(x * CELL_SIZE, 0), Vector2(x * CELL_SIZE, height), line_color)
    for y in range(ROWS + 1):
        draw_line(Vector2(0, y * CELL_SIZE), Vector2(width, y * CELL_SIZE), line_color)
    var fill_color := Color(0, 0, 0)
    for x in range(COLS):
        for y in range(ROWS):
            if cells[x][y]:
                draw_rect(Rect2(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE), fill_color)
    var preview_color := Color(0, 0, 1, 0.5)
    for idx in preview_cells:
        draw_rect(Rect2(idx.x * CELL_SIZE, idx.y * CELL_SIZE, CELL_SIZE, CELL_SIZE), preview_color)

func try_place_piece(card) -> bool:
    var indices := _get_piece_indices(card)
    if indices.is_empty():
        return false
    for idx in indices:
        if idx.x < 0 or idx.x >= COLS or idx.y < 0 or idx.y >= ROWS:
            return false
        if cells[idx.x][idx.y]:
            return false
    for idx in indices:
        cells[idx.x][idx.y] = true
    queue_redraw()
    return true

func preview_piece(card) -> void:
    preview_cells.clear()
    var indices := _get_piece_indices(card)
    if indices.is_empty():
        queue_redraw()
        return
    for idx in indices:
        if idx.x < 0 or idx.x >= COLS or idx.y < 0 or idx.y >= ROWS:
            queue_redraw()
            return
        if cells[idx.x][idx.y]:
            queue_redraw()
            return
    preview_cells = indices.duplicate()
    queue_redraw()

func clear_preview() -> void:
    if preview_cells.is_empty():
        return
    preview_cells.clear()
    queue_redraw()
