# SquirrelAttack

This repository contains a minimal Godot project for a simple 2D card game prototype.

## Project Structure
- `project.godot` – Godot project configuration.
- `scenes/` – Godot scene files including the main scene and a basic card scene.
- `scripts/` – GDScript files for the main scene and card logic.
- `data/shapes.json` – Available piece shapes and their energy costs.
- `data/attacks.json` – Predefined 4-cell attack patterns used each turn.
 - `data/characters.json` – Simple pixel art descriptions for the alien and mech.
  Shapes may be grouped under named keys (for example `"left_arm"`) inside the
  `shapes` dictionary. Each group now stores a `health` value equal to the number
  of grid squares covered by that group and a `shapes` array describing the
  rectangles. Each entry can optionally include an `outline_color` array used
  when drawing the sprite. Shape positions are specified using grid coordinates
  measured from the top-left corner of the sprite canvas and negative values are
  no longer supported.

## Getting Started
1. Open the folder in Godot 4.x.
2. Run the project to see the empty scene. The left grid represents the player
   and the right grid is the enemy. Each side now displays a health counter
   above its grid. The value shown is the sum of the health for every body part
   defined in `data/characters.json`. At the start of each turn, one of the predefined attacks from
   `data/attacks.json` is chosen and those four squares on the player's grid
  light up. Any highlighted square left uncovered when the "End Turn" button is
  pressed only deals damage if that cell overlaps the mech sprite. Likewise,
  placing pieces on the enemy grid only harms the alien for each block that
  overlaps the alien sprite. Placing pieces outside the alien causes no damage.
Damage from the player side only comes from these uncovered hazard squares
that touch the mech.

Body parts visibly change color based on remaining health. When a part drops
below 50% of its maximum health it turns yellow, below 25% it turns red and
at 0 health it becomes black and can no longer be targeted.

The project is intentionally minimal and can be extended with gameplay and assets.
Each grid now spans 20 columns, so both the player and enemy grids adjust their
cell size to fit side by side without overlapping.
