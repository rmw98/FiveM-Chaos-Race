# FiveM Chaos Race Gamemode

A complete, custom gamemode for FiveM that combines competitive point-to-point racing with the unpredictability of the GTA V Chaos Mod. 

**Status:** ⚠️ *Archived / As-Is. I built this months ago as a passion project to learn Lua, C#, and FiveM networking. I am dumping the source code here for the community. Anyone is free to use or modify, see LICENSE.*

## 🏁 How the Gamemode Works
* **The Race:** Players spawn in a lobby, ready up, and are teleported to a random start point with a random destination.
* **The Chaos:** Every few seconds, a random effect triggers (e.g., cars lose gravity, meteors fall from the sky, everyone is forced into a tank).
* **The Ghost System:** If a player dies (runs out of lives), they become a Spectator/Ghost.
* **The Sabotage UI:** Spectators have access to a custom NUI (HTML/JS/CSS) where they can spend "Chaos Cash" earned from previous rounds to manually trigger specific effects on surviving racers.

## 🛠️ Technical Ecosystem
This project isn't just a Lua script; it's a multi-part ecosystem consisting of:

1. **`gamemanager` (Lua & NUI):** Handles round state, spawning, money economies, and the NUI (frontend) for the Spectator Haunting system.
2. **`chaos` (Lua):** The core engine that parses context (is the player in a car, boat, or on foot?) and executes dozens of modular, isolated effect scripts safely.
3. **`ChaosConfigEditor` (C# WPF):** A standalone Windows desktop application I built so server owners can easily edit the `config.lua` (changing effect weights, costs, and durations) via a clean graphical interface without touching the code.

## 📥 Installation (For Developers)
To use this, drop `[chaos-race]` into your FiveM `server-data/resources` folder and ensure `ensure gamemanager` and `ensure chaos` are in your `server.cfg`. 

*Note: Some effects require specific add-on peds/sounds. Since this is an archived dump, those external assets are not included. You will need to comment those effects out or provide the assets yourself.*

List of assets used:
* Sonic Ped
* Jesse Pinkman Ped
* Tom Hanks Ped
* Walter White Ped 
* Lightning McQueen Car
* Lp700 KSI Livery Car
* Sf24 Car
* Xsound
* Random .ogg copyrighted sound effects (I won't be providing these; may cause errors with missing files).

## ⚖️ License & Rules (GPLv3)
This project is open-source under the **GNU GPLv3 License**. 

I am releasing this framework for free for the community to learn from and enjoy. You are free to use it and modify it, but **you must play by the rules**:

1. **Credit:** You must credit me (`rmw98`) as the original creator.
2. **No Closed-Source Selling:** You may NOT take this code, change a few lines, and lock it behind FiveM's CFX Escrow/Tebex encryption to sell as a closed-source product.
3. **Open Source Your Changes:** If you modify this code and distribute it as a download, your modified version MUST ALSO BE OPEN-SOURCE.
