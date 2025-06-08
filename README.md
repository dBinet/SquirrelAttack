# SquirrelAttack

This repository contains a minimal Godot project for a simple 2D card game prototype.

## Project Structure
- `project.godot` – Godot project configuration.
- `scenes/` – Godot scene files including the main scene and a basic card scene.
- `scripts/` – GDScript files for the main scene and card logic.

## Getting Started
1. Open the folder in Godot 4.x.
2. Run the project to see the empty scene. The left grid represents the enemy
   and the right grid is the player. Each side now displays a health counter
   above its grid. At the start of each turn, four random squares on the
   player's grid light up. Any lit square left uncovered when the "End Turn"
   button is pressed causes one point of damage to the player.

The project is intentionally minimal and can be extended with gameplay and assets.
