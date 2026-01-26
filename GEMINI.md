# UtilityHub WoW AddOn

## Project Overview

UtilityHub is a World of Warcraft AddOn designed to enhance various aspects of the game by providing additional functionalities and quality-of-life improvements. It's built using Lua and leverages a suite of Ace3 libraries, which are standard for WoW AddOn development, to create a robust and configurable user experience.

**Key Technologies:**
*   **Lua:** The primary scripting language for World of Warcraft AddOns.
*   **Ace3 Libraries:** A collection of highly optimized and commonly used libraries for WoW AddOn development, including:
    *   `AceAddon-3.0`: Core framework for AddOn creation and module management.
    *   `AceConfig-3.0` & `AceConfigDialog-3.0`: For creating in-game configuration panels.
    *   `AceDB-3.0`: For managing and storing AddOn data.
    *   `LibStub`: A utility library for managing shared libraries.
    *   `LibDataBroker-1.1` & `LibDBIcon-1.0`: For minimap icon integration and data display.
    *   `AceComm-3.0`: For inter-addon communication.
    *   `CallbackHandler-1.0`: For event handling and callbacks.
    *   `Utils-1.0`: A custom utility library.

## Key Features

UtilityHub offers a range of features, organized into modules that can be enabled or disabled:

*   **Mail Management:** Comprehensive tools for managing in-game mail, including:
    *   Character grouping and tracking.
    *   Configurable mail presets for sending items to specific recipients or groups.
    *   Support for item groups, manual inclusions, and exclusions in presets.
*   **AutoBuy:** Automatically purchases specified limited-stock items from vendors when their windows are opened.
*   **Cooldown Tracking:** Tracks and lists character cooldowns across alts, with optional sound notifications when cooldowns are ready.
*   **Daily Quests:** Tracks daily quest progress.
*   **Tooltip Enhancements:** Modifies the display of stats in item tooltips for a simpler view.
*   **Trade Information:** Provides extra information about the player you are trading with.

## Configuration

UtilityHub's options can be accessed in a few ways:

*   **Minimap Icon:**
    *   **Left Click:** Opens the AddOn's main options panel.
    *   **Right Click:** Toggles the cooldowns frame.
    *   **Shift + Right Click:** Toggles the daily quests frame.
*   **`/UH options` Slash Command:** Directly opens the options panel.

The configuration panel, built with AceConfig-3.0, provides intuitive controls (toggles, input fields, custom item lists, color pickers) to customize each module's behavior.

## Slash Commands

The AddOn supports the following slash commands, which can be prefixed with `/UH` or `/uh`:

*   `/UH help`: Displays a list of available commands.
*   `/UH debug`: Toggles debug mode on or off.
*   `/UH options`: Opens the AddOn's configuration panel.
*   `/UH cd` or `/UH cds`: Toggles the cooldowns frame.
*   `/UH daily` or `/UH dailies`: Toggles the daily quests frame.
*   `/UH migrate`: Forces a database migration (useful for development/troubleshooting).
*   `/UH update-quest-flags [module]`: Forces an update of daily quest flags.
*   `/UH execute [module] [function] [arg]`: Executes a specific function within a module (primarily for development/testing).

## Building and Running

As a World of Warcraft AddOn, there is no traditional "build" process. To install and run UtilityHub:

1.  Ensure the `UtilityHub` folder is placed directly into your World of Warcraft `Interface\AddOns\` directory.
2.  Launch World of Warcraft.
3.  The AddOn should be listed and enabled in the AddOns selection screen at the character login.

## Development Conventions

*   **Module-based Structure:** Features are organized into separate modules (e.g., `Modules/Mail`, `Modules/AutoBuy`).
*   **Ace3 Framework:** Should be used for the module structure, saving data between sessions and characters, options. Outside this scope of things, try not using it unless necessary or required.
*   **Event-driven:** Utilizes `CallbackRegistryMixin` for internal event handling and communication between modules.
*   **SavedVariables:** Uses `AceDB-3.0` to persist user settings and data across game sessions.
*   **Localization (Implied):** While not explicitly covered in the reviewed files, WoW AddOns typically support localization, often managed through separate `.lua` or `.xml` files.
*   **Lua Type Annotations:** The code includes LuaDoc-style type annotations for better code readability and IDE support.

## Sources of information

1. \\wsl.localhost\Ubuntu\home\dev\wow-ui-source - Source code of the WoW Interface - TBC Anniversary Version
2. https://warcraft.wiki.gg/ - Most accurate source documentation for the WoW Interface API
3. https://github.com/TheMouseNest/Baganator - Good addon to be used as example
4. https://github.com/TheMouseNest/Auctionator - Good addon to be used as example
5. https://github.com/Karl-HeinzSchneider/WoW-DragonflightUI - Good addon to be used as example
6. ../ - My current addons folder with mostly recently updated addons