# Pi Quest
A 2D action RPG built with Godot 4.2, running natively on Raspberry Pi 4. Developed as a graduation project for the Electrical-Electronics Engineering program at Istanbul Sabahattin Zaim University.
![Pi Quest Gameplay](docs/PiQuestGameplay.gif)
## Features
- 🗺️ **Procedural Dungeon Generation** — Grid-based random walk generates a unique room layout and connectivity graph every playthrough, with dedicated starting and boss rooms
- 🤖 **FSM-Based Enemy AI** — Each enemy type runs its own independent state machine and script, sharing common interfaces (`take_damage()`, `die()`, `died` signal) so new enemies can be added without touching existing code
  - **Slime** — 7-state FSM (Idle, Wander, Chase, Attack, Cooldown, Hurt, Dead) with lunge attacks and knockback
  - **Skeleton Mage** — Kites around the player at range while avoiding melee contact
  - **Boss** — Multiple attack patterns including spiral projectile bursts, targeted bursts, area attacks, and position-switching
- 🎒 **Card-Based Inventory System** — Custom-built UI with flippable item cards, full keyboard/gamepad navigation, and dynamic stat display (attack, speed, element)
- 🎲 **Weighted Loot System** — Chests roll rewards from a configurable weighted table (random weapon, HP boosts, bonus damage) once a room is cleared, so each run feels different
- ⚔️ **Resource-Based Weapon System** — Weapons defined as reusable Godot `Resource` objects with elemental types (Fire, Ice, Lightning), damage, cooldown, and knockback stats
- 🎮 **GPIO Gamepad Integration** — Physical controller support via Python
- 🍓 **Native Raspberry Pi 4 (ARM64) Performance** — Optimized for portable hardware
- 🎵 **Dynamic Music System** — Context-aware soundtrack switching between exploration, boss fights, and menus
## Tech Stack
![Godot](https://img.shields.io/badge/Godot-4.2-478CBF?logo=godot-engine&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.x-3776AB?logo=python&logoColor=white)
![Raspberry Pi](https://img.shields.io/badge/Raspberry%20Pi-4-A22846?logo=raspberry-pi&logoColor=white)
![GDScript](https://img.shields.io/badge/GDScript-478CBF)
## Setup
```bash
git clone https://github.com/Ragnell20/piquest.git
cd piquest
# Open the project with Godot 4.2
# or run the exported build directly on Raspberry Pi
```
## Architecture Overview
- **Procedural Generation:** `GameManager` builds the dungeon layout by performing a randomized walk across a grid, picking an unvisited neighboring cell in a random direction at each step. The starting room and the final room (boss) are marked with special indices, and a connectivity graph (`room_connections`) tracks which doors link to which rooms.
- **Enemy AI:** Enemies are self-contained `CharacterBody2D` scripts that manage their own finite state machine, detection radius, attack timing, and death sequence. Rooms listen for each enemy's `died` signal to track when they've been cleared.
- **Loot & Rewards:** Chests use a weighted-roll system — each possible reward has a weight, a random roll is compared against cumulative weights to pick an outcome, then the effect (weapon, HP, or damage bonus) is applied to the player with an animated pickup notification.
- **Hardware Integration:** GPIO input is bridged to the game via Python, mapping physical button/joystick input to in-game actions for a portable, dedicated-hardware feel.
## Hardware Setup

A custom GPIO controller was built using push buttons wired to a breadboard, connected to the Raspberry Pi 4's GPIO pins. A Python script polls the buttons at ~100 Hz and maps each press to a keyboard/mouse input, allowing the game to be played entirely through physical hardware.

![GPIO Controller Setup](docs/boss.gif)

See [`hardware/gpio_controller.py`](hardware/gpio_controller.py) for the full implementation.

## Project Presentation
📄 [Full project presentation](https://canva.link/or01gp2y9nc6op0)
## Developer
**Furkan Talha Çelik**
Istanbul Sabahattin Zaim University — Electrical-Electronics Engineering
[LinkedIn](https://www.linkedin.com/in/furkan-talha-%C3%A7elik-a4aa46271/) · [GitHub](https://github.com/Ragnell20)
