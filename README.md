# Sokoban (Roblox)

A classic [Sokoban](https://en.wikipedia.org/wiki/Sokoban) puzzle for Roblox: push crates onto every target. This project is structured as a **Rojo**-compatible place so you can keep game logic in files under version control and sync them into a Roblox place.

## Features

- **Faithful rules** — Walls block movement, crates only move when pushed, and you can only push one crate at a time. Win when every target has a crate.
- **4 Microban-style levels** — Small layouts suitable for a demo: Tutorial, Corners, Hallway, and Four rooms.
- **3D view** — Orthographic-style camera on the board, with walls, floor tiles, target markers, wooden crates, and your avatar on the grid.
- **HUD** — Level name, progress (level index and total), move count, and control hints.
- **Strict Luau** — `SokobanCore` and the client use `--!strict` for clearer typing and fewer runtime surprises.

## Project layout

| Path | Role |
|------|------|
| `default.project.json` | Rojo project tree: maps `src/` files into `ReplicatedStorage` and `StarterPlayer.StarterPlayerScripts`. |
| `src/ReplicatedStorage/Sokoban/SokobanCore.lua` | Grid parsing, player lookup, one-step moves (`tryMove`), win check (`isWin`), and dimensions. |
| `src/ReplicatedStorage/Sokoban/Levels.lua` | Level definitions: each level has a `name` and ASCII `map` string. |
| `src/StarterPlayer/StarterPlayerScripts/SokobanClient.client.lua` | Local script: builds the level in `Workspace`, handles input, camera, UI, and auto-advances after a level clear. |

## Tile notation (ASCII maps)

| Character | Meaning |
|-----------|---------|
| `#` | Wall |
| ` ` (space) | Floor |
| `.` | Empty target |
| `@` | Player |
| `+` | Player on target |
| `$` | Crate |
| `*` | Crate on target |

## Controls

| Input | Action |
|-------|--------|
| **W** / **↑** | Move up (negative row) |
| **S** / **↓** | Move down |
| **A** / **←** | Move left |
| **D** / **→** | Move right |
| **R** | Restart current level |
| **N** | Go to next level (wraps from last to first) |

After you clear a level, a short “Level complete!” banner appears; if there is another level, the game loads it automatically after a brief delay.

## Requirements

- **Roblox Studio** (current release)
- **[Rojo](https://rojo.space/)** 7.x (or a version compatible with your `default.project.json`) to sync the filesystem into a place, *or* paste/copy scripts manually if you are not using Rojo

## Building and running with Rojo

1. Install Rojo and open this folder as the project root (the one containing `default.project.json`).
2. From a terminal, start the Rojo server in this directory, for example:

   ```bash
   rojo serve
   ```

3. In Roblox Studio, use the Rojo plugin to connect to the server and sync. Play solo to run the local client script; your character is placed on the player tile and input moves the logical grid (walk/jump are disabled for the puzzle).

## Extending the game

- **New levels** — Add entries to the table in `Levels.lua`. Each level needs a unique `name` and a multiline `map` string using the characters above. Rows are padded to the same width automatically when parsed.
- **Rule tweaks** — All movement and win logic live in `SokobanCore.lua`; the client only renders and forwards input.

## License

Add a `LICENSE` file in this repository if you want to specify terms for reuse. Until then, assume all rights are reserved unless you state otherwise.
