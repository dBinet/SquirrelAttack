extends Node2D
class_name Grid

const COLS := 10
const ROWS := 20
const CELL_SIZE := 20

var cells: Array = []

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

func try_place_piece(card) -> bool:
    if not card.has_method("get_global_block_positions"):
        return false
    var positions: Array[Vector2] = card.get_global_block_positions()
    var indices: Array[Vector2i] = []
    for pos in positions:
        var local := to_local(pos)
        var ix := int(floor(local.x / CELL_SIZE))
        var iy := int(floor(local.y / CELL_SIZE))
        if ix < 0 or ix >= COLS or iy < 0 or iy >= ROWS:
            return false
        if cells[ix][iy]:
            return false
        indices.append(Vector2i(ix, iy))
    for idx in indices:
        cells[idx.x][idx.y] = true
    queue_redraw()
    return true
