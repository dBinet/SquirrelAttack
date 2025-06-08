# SquirrelAttack

This repository contains a minimal Godot project for a simple 2D card game prototype.

## Project Structure
- `project.godot` – Godot project configuration.
- `scenes/` – Godot scene files including the main scene and a basic card scene.
- `scripts/` – GDScript files for the main scene and card logic.
- `data/shapes.json` – Available piece shapes and their energy costs.
- `data/attacks.json` – Predefined 4-cell attack patterns used each turn.
- `data/characters.json` – Simple pixel art descriptions for the alien and mech.

## Getting Started
1. Open the folder in Godot 4.x.
2. Run the project to see the empty scene. The left grid represents the enemy
   and the right grid is the player. Each side now displays a health counter
   above its grid. At the start of each turn, one of the predefined attacks from
   `data/attacks.json` is chosen and those four squares on the player's grid
  light up. Any highlighted square left uncovered when the "End Turn" button is
  pressed only deals damage if that cell overlaps the mech sprite. Likewise,
  placing pieces on the enemy grid only harms the alien for each block that
  overlaps the alien sprite. Placing pieces outside the alien causes no damage.
  Damage from the player side only comes from these uncovered hazard squares
  that touch the mech.

The project is intentionally minimal and can be extended with gameplay and assets.
