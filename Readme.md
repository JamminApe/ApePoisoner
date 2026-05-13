# 🐒 ApePoisoner

A lightweight poison management addon for **Project Ascension** (WoW 3.3.5 custom server).  
Adds a movable button to your screen that applies poisons to your Main Hand and Off Hand weapons with a single click — with expiration tracking, audio alerts, dual profiles, and a clean settings panel.

---

## Features

- **One-click poison application** — Left click for Main Hand, Right click for Off Hand
- **Dual profiles** — Hold Shift to use your alternate poison loadout (e.g. PvE vs PvP setup)
- **Expiration countdown** — Live timer on the button face showing time remaining, colour-coded green → yellow → red
- **Audio alerts** — Plays a sound when poisons are about to expire or when no poisons are applied
- **Glow effect** — Button pulses green when weapons are unpoisoned so you never forget
- **Fade mode** — Optionally fades the button out when weapons are already poisoned
- **Movable button** — Shift+Drag to reposition, position saved across sessions
- **Configurable modifier key** — Choose Alt, Ctrl, or Shift to open settings with a click
- **Scale slider** — Resize the button from 0.5x to 2.0x
- **Lock toggle** — Lock the button position so it can't be accidentally moved

---

## Supported Poisons

| Poison | Slot |
|---|---|
| Instant Poison | MH / OH |
| Deadly Poison | MH / OH |
| Wound Poison | MH / OH |
| Crippling Poison | MH / OH |
| Mind-numbing Poison | MH / OH |
| Anesthetic Poison | MH / OH |

---

## Installation

1. Download or clone this repository
2. Copy the `ApePoisoner` folder into your addons directory:
   ```
   World of Warcraft/Interface/AddOns/ApePoisoner/
   ```
3. Make sure the folder is named exactly `ApePoisoner`
4. Launch the game and enable the addon in the **AddOns** menu on the character select screen

---

## Usage

### Button
| Action | Result |
|---|---|
| Left Click | Apply Main Hand poison |
| Right Click | Apply Off Hand poison |
| Shift + Click | Use Shift profile instead of Normal |
| Alt/Ctrl/Shift + Click | Open settings (configurable) |
| Shift + Drag | Move the button |

### Slash Commands
| Command | Description |
|---|---|
| `/apep` | Show help |
| `/apep enable` | Enable the addon |
| `/apep disable` | Disable the addon |
| `/apep config` | Open settings panel |

### Keybind
A keybind to toggle the settings panel is available under:  
**Escape → Key Bindings → ApePoisoner → Toggle ApePoisoner Config**

---

## Settings

Open settings via **Interface → AddOns → ApePoisoner**, `/apep config`, or your configured modifier key + click on the button.

| Setting | Description |
|---|---|
| Normal Profile | Assign MH and OH poisons for your default loadout |
| Shift Profile | Assign MH and OH poisons for your alternate loadout |
| Fade | Fades the button when weapons are already poisoned |
| Sound | Enables audio alerts for expiring or missing poisons |
| Lock | Prevents the button from being moved |
| Button Scale | Resizes the button (0.5x – 2.0x) |
| Config Modifier | The modifier key used to open settings on click (Alt / Ctrl / Shift) |

---

## File Structure

```
ApePoisoner/
├── ApePoisoner.toc       — Addon metadata and load order
├── Bindings.xml          — Keybinding definition
├── PoisonData.lua        — Poison list and SavedVariables defaults
├── Core.lua              — Enchant tracking, expiration alerts, slash commands
├── UI.lua                — Button, glow, countdown, click handling
├── Config.lua            — Settings panel (standalone + Interface > AddOns)
└── Media/
    ├── AscPoisoner_ExpPoison.ogg   — Expiration warning sound
    └── AscPoisoner_NoPoison.ogg    — No poison applied sound
```

---

## Compatibility

- **Server:** Project Ascension (Warcraft Reborn)
- **Client:** World of Warcraft 3.3.5 (Interface version 30300)
- **Tested with:** ElvUI, GatherMate2, TomTom, Zygor

---

## Author

**JamminApe**  
Project Ascension — Bronzebeard realm

---

## License

This project is open source. Feel free to fork, modify, and share.