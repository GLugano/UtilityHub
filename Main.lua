local ADDON_NAME, addonTable = ...;

local minimapIcons = {
  NORMAL = "Interface\\Addons\\" .. ADDON_NAME .. "\\Assets\\Icons\\addon.blp",
  NOTIFICATION = "Interface\\Addons\\" .. ADDON_NAME .. "\\Assets\\Icons\\cooldowns_ready",
};
---@type number|nil
local lastCountReadyCooldowns = nil;

local function InitVariables()
  ---@type string|nil
  local version = UtilityHub.Constants.AddonVersion;
  ---@type string|nil
  local oldVersion = nil;

  if (UHdatabase) then
    oldVersion = UHdatabase.global.oldVersion;
  end

  UtilityHub.Database = LibStub("AceDB-3.0")
      :New(
        "UHdatabase",
        {
          global = {
            version = version,
            debugMode = false,
            minimapIcon = {
              hide = false,
            },
            options = UtilityHub.GameOptions.defaults,
            presets = {},
            whispers = {},
            ---@type Character[]
            characters = {},
            ---@type string[]
            mailHistory = {},
          },
          char = {},
        },
        "Default"
      );
  UtilityHub.Database.global.oldVersion = version;

  if (oldVersion and oldVersion ~= version) then
    UtilityHub:MigrateDB(version, oldVersion);
  end
end

local function SetupSlashCommands()
  SLASH_UtilityHub1 = "/UH"
  SLASH_UtilityHub2 = "/uh"
  SlashCmdList.UtilityHub = function(strParam)
    local fragments = {};

    for word in string.gmatch(strParam, "%S+") do
      table.insert(fragments, word);
    end

    local command = (fragments[1] or ""):trim();

    if (command == "") then
      UtilityHub.Helpers.Notification:ShowNotification("Type /UH help for commands");
    elseif (command == "help") then
      UtilityHub.Helpers.Notification:ShowNotification("Use the following parameters with /UH");
      print("- |cffddff00debug|r");
      print("  Toggle the debug mode");
      print("- |cffddff00options|r");
      print("  Open the options");
      print("- |cffddff00cd or cds|r");
      print("  Toggle cooldowns frame");
      print("- |cffddff00daily or dailies|r");
      print("  Toggle daily frame");
      print("- |cffddff00autobuy [itemLink] [quantity]|r - Add item (default: quantity=1)");
      print("- |cffddff00autobuy list/remove/clear|r - Manage AutoBuy list");
      print("  Quantity=1: buy once | Quantity>1: maintain stock");
      print("- |cffddff00testcd|r");
      print("  Test cooldown notifications");
      print("- |cffddff00fakesync|r");
      print("  Inject fake characters to simulate cross-account sync");
      print("- |cffddff00clearfakesync|r");
      print("  Remove all fake sync characters");
      print("- |cffddff00listchars|r");
      print("  List all characters in database (debug)");
      print("- |cffddff00logs [count|clear|export|show]|r");
      print("  View recent logs, clear all logs, export to chat, or open log viewer window");
    elseif (command == "debug") then
      UtilityHub.Database.global.debugMode = (not UtilityHub.Database.global.debugMode);
      local debugText = UtilityHub.Database.global.debugMode and "ON" or "OFF";
      UtilityHub.Helpers.Notification:ShowNotification("Debug mode " .. debugText);
    elseif (command == "options") then
      print("|cffFFD700[UH Debug] Options command, category:|r", UtilityHub.GameOptions.category);
      UtilityHub.GameOptions.OpenConfig();
    elseif (command == "cd" or command == "cds") then
      UtilityHub.Events:TriggerEvent("TOGGLE_COOLDOWNS_FRAME");
    elseif (command == "daily" or command == "dailies") then
      UtilityHub.Events:TriggerEvent("TOGGLE_DAILY_FRAME");
    elseif (command == "testcd") then
      ---@type Cooldowns
      local cooldownsModule = UtilityHub.Addon:GetModule("Cooldowns");
      cooldownsModule:TestNotification();
    elseif (command == "fakesync") then
      ---@type Cooldowns
      local cooldownsModule = UtilityHub.Addon:GetModule("Cooldowns");
      cooldownsModule:InjectFakeSyncData();
    elseif (command == "clearfakesync") then
      ---@type Cooldowns
      local cooldownsModule = UtilityHub.Addon:GetModule("Cooldowns");
      cooldownsModule:ClearFakeSyncData();
    elseif (command == "listchars") then
      print("|cffFFD700Characters in database (" .. #UtilityHub.Database.global.characters .. " total):|r");
      for i, char in ipairs(UtilityHub.Database.global.characters) do
        local cooldownCount = 0;

        if (char.cooldownGroup) then
          for _, group in pairs(char.cooldownGroup) do
            cooldownCount = cooldownCount + #group;
          end
        end

        print(
          string.format(
            "  %d. %s (class=%s, race=%s, cooldowns=%d)",
            i,
            char.name or "nil",
            char.className or "nil",
            char.race or "nil",
            cooldownCount
          )
        );
      end
    elseif (command == "logs") then
      local subCommand = fragments[2];

      if (subCommand == "clear") then
        UtilityHub.Helpers.DebugLog:Clear();
        print("|cff00FF00Debug logs cleared|r");
      elseif (subCommand == "show") then
        UtilityHub.DebugLogViewer:Show();
      elseif (subCommand == "export") then
        local exported = UtilityHub.Helpers.DebugLog:Export();
        if (exported == "") then
          print("|cffFF6B6BNo logs to export|r");
        else
          print("|cffFFD700Exported logs (copy from chat):|r");
          print(exported);
        end
      else
        local count = tonumber(subCommand) or 20;
        local logs = UtilityHub.Helpers.DebugLog:GetRecent(count);
        local totalCount = UtilityHub.Helpers.DebugLog:Count();

        if (#logs == 0) then
          print("|cffFF6B6BNo debug logs available|r");
        else
          print(string.format("|cffFFD700Recent logs (showing last %d of %d total):|r", #logs, totalCount));
          for _, log in ipairs(logs) do
            print(log);
          end
          print("|cff808080Use '/uh logs show' to open log viewer window|r");
        end
      end
    elseif (command == "migrate") then
      UtilityHub:MigrateDB();
    elseif (command == "update-quest-flags") then
      UtilityHub.Events:TriggerEvent("FORCE_DAILY_QUESTS_FLAG_UPDATE", fragments[2]);
    elseif (command == "execute") then
      local functionName = fragments[3];
      local arg = fragments[4];
      local module = UtilityHub.Addon:GetModule(fragments[2]);
      module[functionName](module, arg);
    elseif (command == "autobuy") then
      local subCommand = fragments[2];

      -- Extract itemLink from the full command string (handles spaces in item names)
      local fullCommand = strParam;
      local itemLink = string.match(fullCommand, "(|c%x+|Hitem:.-|h%[.-%]|h|r)");

      -- Extract quantity (last number in the command)
      local quantity = 1; -- default
      for i = #fragments, 1, -1 do
        local num = tonumber(fragments[i]);
        if (num) then
          quantity = num;
          break;
        end
      end

      -- If no valid subcommand specified and there's an itemLink, assume "add"
      if (itemLink and subCommand ~= "list" and subCommand ~= "remove" and subCommand ~= "clear") then
        subCommand = "add";
      end

      if (subCommand == "add") then
        if (not itemLink) then
          print("|cffFF6B6BError:|r Shift+Click an item first, then use: /uh autobuy [itemLink] [quantity]");
          return;
        end

        -- Extract itemID from link
        local itemID = tonumber(string.match(itemLink, "item:(%d+):"));

        -- If itemID not found, try to resolve item name to link
        if (not itemID) then
          -- Try to get item info by name (remove brackets if present)
          local itemName = string.match(itemLink, "%[(.-)%]") or itemLink;
          local resolvedLink = select(2, C_Item.GetItemInfo(itemName));

          if (resolvedLink) then
            itemLink = resolvedLink;
            itemID = tonumber(string.match(itemLink, "item:(%d+):"));
            print("|cff00FF00Resolved item name to:|r " .. itemLink);
          else
            print("|cffFF6B6BError:|r Invalid item link. Please Shift+Click the item from your bags or inventory.");
            return;
          end
        end

        if (not itemID) then
          print("|cffFF6B6BError:|r Could not extract item ID");
          return;
        end

        local autoBuyList = UtilityHub.Database.global.options.autoBuyList or {};

        -- Check if already exists
        for _, existingItem in ipairs(autoBuyList) do
          local existingID = tonumber(string.match(existingItem.itemLink, "item:(%d+):"));
          if (existingID == itemID) then
            print("|cffFF6B6BError:|r Item already in AutoBuy list");
            return;
          end
        end

        tinsert(autoBuyList, {
          itemLink = itemLink,
          quantity = quantity,
        });
        UtilityHub.Database.global.options.autoBuyList = autoBuyList;

        if (quantity == 1) then
          print("|cff00FF00Added to AutoBuy:|r " .. itemLink .. " |cff808080(buy once)|r");
        else
          print("|cff00FF00Added to AutoBuy:|r " .. itemLink .. " |cff808080(maintain: " .. quantity .. ")|r");
        end
      elseif (subCommand == "remove") then
        if (not itemLink) then
          print("|cffFF6B6BError:|r Usage: /uh autobuy remove [itemLink]");
          return;
        end

        local autoBuyList = UtilityHub.Database.global.options.autoBuyList or {};
        local itemID = tonumber(string.match(itemLink, "item:(%d+):"));
        local removed = false;

        for i = #autoBuyList, 1, -1 do
          local existingID = tonumber(string.match(autoBuyList[i].itemLink, "item:(%d+):"));
          if (existingID == itemID) then
            table.remove(autoBuyList, i);
            removed = true;
            break;
          end
        end

        if (removed) then
          UtilityHub.Database.global.options.autoBuyList = autoBuyList;
          print("|cff00FF00Removed from AutoBuy:|r " .. itemLink);
        else
          print("|cffFF6B6BError:|r Item not found in AutoBuy list");
        end
      elseif (subCommand == "list") then
        local autoBuyList = UtilityHub.Database.global.options.autoBuyList or {};
        if (#autoBuyList == 0) then
          print("|cffFFD700AutoBuy list is empty|r");
        else
          print("|cffFFD700AutoBuy list (" .. #autoBuyList .. " items):|r");
          for i, item in ipairs(autoBuyList) do
            if (item.quantity == 1) then
              print("  " .. i .. ". " .. item.itemLink .. " |cff808080(buy once)|r");
            else
              local itemID = tonumber(string.match(item.itemLink, "item:(%d+):"));
              local currentCount = itemID and C_Item.GetItemCount(itemID, false, true) or 0;
              print("  " .. i .. ". " .. item.itemLink .. " |cff808080(" .. currentCount .. "/" .. item.quantity .. ")|r");
            end
          end
        end
      elseif (subCommand == "clear") then
        UtilityHub.Database.global.options.autoBuyList = {};
        print("|cff00FF00AutoBuy list cleared|r");
      else
        print("|cffFF6B6BError:|r Usage: /uh autobuy [itemLink] [quantity] OR /uh autobuy [list|remove|clear]");
      end
    else
      UtilityHub.Helpers.Notification:ShowNotification("Command not found");
    end
  end
end

local function CreateMinimapIcon()
  UtilityHub.Libs.LDB:NewDataObject(ADDON_NAME, {
    type = "data source",
    text = "0",
    icon = minimapIcons.NORMAL,
    OnClick = function(self, button)
      if (button == "LeftButton") then
        if (IsShiftKeyDown()) then
          -- UtilityHub.Events:TriggerEvent("TOGGLE_DATA_FRAME");
        else
          if (SettingsPanel:IsShown()) then
            HideUIPanel(SettingsPanel);
          else
            UtilityHub.GameOptions.OpenConfig();
          end
        end
      elseif (button == "RightButton") then
        if (IsShiftKeyDown()) then
          UtilityHub.Events:TriggerEvent("TOGGLE_DAILY_FRAME");
        else
          UtilityHub.Events:TriggerEvent("TOGGLE_COOLDOWNS_FRAME");
        end
      end
    end,
    OnTooltipShow = function(self)
      self:AddDoubleLine(ADDON_NAME,
        UtilityHub.Helpers.Color:AddColorToString("Version " .. UtilityHub.Constants.AddonVersion, "FFB1B1B1"));

      if (UtilityHub.Database.global.options.cooldowns) then
        local textCount;
        local sessionData = UtilityHub.DatabaseFunctions.GetSessionData();
        local count = sessionData.lastCooldownReadyCount or 0;

        if (count > 0) then
          local textWithoutColor = string.format(
            "%s cooldown%s READY",
            count,
            (count > 1 and "s" or "")
          );
          textCount = UtilityHub.Helpers.Color:AddColorToString(textWithoutColor, "FF27BD34");
        else
          textCount = "No cooldowns ready";
        end

        self:AddLine(" ");
        self:AddLine(textCount);
      end

      self:AddLine(" ");
      self:AddLine(UtilityHub.Helpers.Color:AddColorToString("[Left Click]", "FF9CD6DE") ..
        " " .. UtilityHub.Helpers.Color:AddColorToString("to open the options", "FFDDFF00"));
      self:AddLine(UtilityHub.Helpers.Color:AddColorToString("[Right Click]", "FF9CD6DE") ..
        " " .. UtilityHub.Helpers.Color:AddColorToString("to open/close cooldowns", "FFDDFF00"));
      self:AddLine(UtilityHub.Helpers.Color:AddColorToString("[Shift] + [Right Click]", "FF9CD6DE") ..
        " " .. UtilityHub.Helpers.Color:AddColorToString("to open/close daily quests", "FFDDFF00"));
    end
  });
  UtilityHub.Libs.LDBIcon:Register(
    ADDON_NAME,
    UtilityHub.Libs.LDB:GetDataObjectByName(ADDON_NAME),
    UtilityHub.Database.global.minimapIcon
  );

  local frame = UtilityHub.Libs.LDBIcon:GetMinimapButton(ADDON_NAME);
  if (frame) then
    frame:SetFrameLevel(9);
  end
end

local function UpdateCharacter()
  ---@type string
  local name = UnitName("player");
  local characterIndex = UtilityHub.DatabaseFunctions.GetCharacterIndex(name);

  if (characterIndex) then
    UtilityHub.DatabaseFunctions.UpdateCurrentCharacter();
    UtilityHub.Events:TriggerEvent("CHARACTER_UPDATED");

    if (UtilityHub.Database.global.debugMode) then
      UtilityHub.Helpers.DebugLog:Add(
        string.format("|cffFFFF00[UH-LOCAL]|r |cff00FF00UPDATED|r local character '%s'", name)
      );
    end
  end
end

local function UpdateMinimapIcon(hasNotification)
  local data = UtilityHub.Libs.LDB:GetDataObjectByName(ADDON_NAME);
  data.icon = hasNotification and minimapIcons.NOTIFICATION or minimapIcons.NORMAL;
end

-- Events
UtilityHub.Events:OnLoad();
UtilityHub.Events:GenerateCallbackEvents({
  "CHARACTER_UPDATE_NEEDED",
  "CHARACTER_UPDATED",
  "OPTIONS_CHANGED",
  "CHARACTER_DELETED",
  "SHOW_COOLDOWNS_FRAME",
  "HIDE_COOLDOWNS_FRAME",
  "TOGGLE_COOLDOWNS_FRAME",
  "COUNT_READY_COOLDOWNS_CHANGED",
  "TOGGLE_DAILY_FRAME",
  "FORCE_DAILY_QUESTS_FLAG_UPDATE",
  "WHISPER_LIST_UPDATED",
  "COOLDOWNS_UPDATED",
});

UtilityHub.Events:RegisterCallback("CHARACTER_UPDATE_NEEDED", function(_, name)
  UpdateCharacter();
end);

UtilityHub.Events:RegisterCallback("OPTIONS_CHANGED", function(_, name)
  if (name == "autoBuy") then
    if (UtilityHub.Database.global.options.autoBuy) then
      UtilityHub.Addon:EnableModule("AutoBuy");
    else
      UtilityHub.Addon:DisableModule("AutoBuy");
    end
  end

  if (name == "cooldowns") then
    if (UtilityHub.Database.global.options.cooldowns) then
      UtilityHub.Addon:EnableModule("Cooldowns");
    else
      UtilityHub.Addon:DisableModule("Cooldowns");
    end
  end

  if (name == "dailyQuests") then
    if (UtilityHub.Database.global.options.dailyQuests) then
      UtilityHub.Addon:EnableModule("DailyQuests");
    else
      UtilityHub.Addon:DisableModule("DailyQuests");
    end
  end

  if (name == "tradeExtraInfo") then
    if (UtilityHub.Database.global.options.tradeExtraInfo) then
      UtilityHub.Addon:EnableModule("Trade");
    else
      UtilityHub.Addon:DisableModule("Trade");
    end
  end

  if (name == "mouseRing") then
    if (UtilityHub.Addon:GetModule("MouseRing", true)) then
      local db = UtilityHub.Database.global.options.mouseRing;

      if (db and db.enabled) then
        UtilityHub.Addon:EnableModule("MouseRing");
      else
        UtilityHub.Addon:DisableModule("MouseRing");
      end
    end
  end
end);

UtilityHub.Events:RegisterCallback("COUNT_READY_COOLDOWNS_CHANGED", function(_, count, changed)
  if (changed) then
    UpdateMinimapIcon(count > 0);
  end
end);

EventRegistry:RegisterFrameEventAndCallback("LOADING_SCREEN_DISABLED", function()
  C_Timer.After(2, function()
    UtilityHub.Flags.addonReady = true;
    local _, recentlyCreated = UtilityHub.DatabaseFunctions.CreateCurrentCharacter();
    UtilityHub.DatabaseFunctions.UpdateCurrentCooldownOptions();

    if (not recentlyCreated) then
      UtilityHub.DatabaseFunctions.UpdateCurrentCharacter();
    end

    UtilityHub.Events:TriggerEvent("CHARACTER_UPDATE_NEEDED");
  end);
end);

EventRegistry:RegisterFrameEventAndCallback("CHAT_MSG_WHISPER", function(_, text, name)
  UtilityHub.Database.global.whispers[name] = text;
  UtilityHub.Events:TriggerEvent("WHISPER_LIST_UPDATED", name, text);
end);

EventRegistry:RegisterFrameEventAndCallback("PLAYER_LOGIN", function()
  UtilityHub.DatabaseFunctions.StartSessionData();
end);

function UtilityHub.Addon:OnInitialize()
  InitVariables();
  SetupSlashCommands();
  CreateMinimapIcon();

  UtilityHub.GameOptions.Register();
  UtilityHub.Integration.Baganator:Init();
  -- UtilityHub.Integration.Auctionator();
  UtilityHub.Integration.TSM:Init();
  UtilityHub.Integration.DragonflightUI:Init();

  if (UtilityHub.Database.global.options.simpleStatsTooltip) then
    UtilityHub.Addon:EnableModule("Tooltip");
  end

  if (UtilityHub.Database.global.options.autoBuy) then
    UtilityHub.Addon:EnableModule("AutoBuy");
  end

  if (UtilityHub.Database.global.options.cooldowns) then
    UtilityHub.Addon:EnableModule("Cooldowns");
  end

  if (UtilityHub.Database.global.options.dailyQuests) then
    UtilityHub.Addon:EnableModule("DailyQuests");
  end

  if (UtilityHub.Database.global.options.tradeExtraInfo) then
    UtilityHub.Addon:EnableModule("Trade");
  end

  UtilityHub.Addon:EnableModule("GraphicsSettings");

  local mouseRingDB = UtilityHub.Database.global.options.mouseRing;

  if (mouseRingDB and mouseRingDB.enabled and UtilityHub.Addon:GetModule("MouseRing", true)) then
    UtilityHub.Addon:EnableModule("MouseRing");
  end
end
