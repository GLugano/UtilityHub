local ADDON_NAME, addonTable = ...;
---@class UtilityHub
local UH = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceComm-3.0");
local interfaceVersion = select(4, GetBuildInfo())

UH:SetDefaultModuleState(false);
local LDB = LibStub:GetLibrary("LibDataBroker-1.1");
UH.LDBIcon = LibStub("LibDBIcon-1.0");
UH.UTILS = LibStub("Utils-1.0");
UH.AceConfigDialog = LibStub("AceConfigDialog-3.0");
UH.Compatibility = {};
UH.Helpers = {};
UH.prefix = "UH";
UH.IsClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) and (interfaceVersion < 20000);
UH.IsTBC = (interfaceVersion >= 20505) and (interfaceVersion < 30000);

local optionsMetatable = {};
function optionsMetatable:GetCategoryID(key)
  for _, value in ipairs(self) do
    if (value.key == key) then
      return value.categoryID;
    end
  end

  return nil;
end;

local mt = {
  __index = optionsMetatable
};

UH.addonReady = false;
UH.Options = setmetatable({}, mt);
UH.tempPreset = {};
UH.lastCountReadyCooldowns = nil;

-- Defaults
UH.defaultOptions = {
  -- Tooltip
  simpleStatsTooltip = true,
  -- AutoBuy
  autoBuy = false,
  autoBuyList = {},
  -- Cooldowns
  cooldowns = false,
  cooldowsList = {},
  cooldownPlaySound = false,
};

-- Enums
UH.Enums = {};
UH.Enums.CHARACTER_GROUP = {
  UNGROUPED = 0,
  MAIN_ALT = 1,
  BANK = 2,
  CD = 3,
};
UH.Enums.CHARACTER_GROUP_TEXT = {
  [UH.Enums.CHARACTER_GROUP.UNGROUPED] = "Ungrouped",
  [UH.Enums.CHARACTER_GROUP.MAIN_ALT] = "Main/alt",
  [UH.Enums.CHARACTER_GROUP.BANK] = "Bank",
  [UH.Enums.CHARACTER_GROUP.CD] = "CD",
};
UH.Enums.MINIMAP_ICON = {
  NORMAL = "BlizzardInterfaceArt\\Interface\\ICONS\\INV_Enchant_FormulaSuperior_01.blp",
  NOTIFICATION = "BlizzardInterfaceArt\\Interface\\ICONS\\INV_Enchant_FormulaEpic_01.blp",
};

function UH:InitVariables()
  local version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version");
  local oldVersion = nil;

  if (UHdatabase and UHdatabase.global and UHdatabase.global.oldVersion) then
    oldVersion = UHdatabase.global.oldVersion;
  end

  self.db = LibStub("AceDB-3.0"):New("UHdatabase", {
    global = {
      version = version,
      debugMode = false,
      minimapIcon = {
        hide = false,
      },
      options = UH.defaultOptions,
      presets = {},
      whispers = {},
      ---@type Character[]
      characters = {},
    },
  }, "Default");
  self.db.global.oldVersion = version;

  if (oldVersion and oldVersion ~= version) then
    UH:MigrateDB(version, oldVersion);
  end
end

function UH:MigrateDB(version, oldVersion)
  if (version and oldVersion) then
    self.Helpers:ShowNotification("Migrating DB version from " .. oldVersion .. " to " .. version);
  else
    self.Helpers:ShowNotification("Migrating DB version - Forced action without any version change");
  end

  if (#self.db.global.presets > 0) then
    for _, preset in pairs(self.db.global.presets) do
      local shouldFixEssenceElemental = false;

      for j, _ in pairs(preset.itemGroups) do
        if (j == "Essence") then
          shouldFixEssenceElemental = true;
        end
      end

      if (shouldFixEssenceElemental) then
        local newItemGroups = {};

        for key, value in pairs(preset.itemGroups) do
          if (key == "Essence") then
            newItemGroups["EssenceElemental"] = value;
          else
            newItemGroups[key] = value;
          end
        end

        preset.itemGroups = newItemGroups;
      end
    end
  end

  if (not self.db.global.options) then
    self.db.global.options = UH.defaultOptions;
  end

  if (not self.db.global.options.autoBuyList) then
    self.db.global.options.autoBuyList = UH.defaultOptions.autoBuyList;
  end

  if (self.db.global.characters) then
    for index, value in ipairs(self.db.global.characters) do
      if (type(value) == "string") then
        local name = self.db.global.characters[index];

        if (name == UnitName("player")) then
          local race = select(2, UnitRace("player"));
          local className = select(2, UnitClass("player"));

          self.db.global.characters[index] = {
            name = name,
            race = race,
            className = className,
            group = nil,
          };
        else
          self.db.global.characters[index] = {
            name = name,
            race = nil,
            className = nil,
            group = nil,
          };
        end
      end
    end
  end

  if (not self.db.global.options.cooldowns) then
    self.db.global.options.cooldowns = false;
  end

  if (not self.db.global.options.cooldowsList) then
    self.db.global.options.cooldowsList = {};
  end
end

function UH:SetupSlashCommands()
  SLASH_UtilityHub1 = "/UH"
  SLASH_UtilityHub2 = "/uh"
  SlashCmdList.UtilityHub = function(strParam)
    local fragments = {};

    for word in string.gmatch(strParam, "%S+") do
      table.insert(fragments, word);
    end

    local command = (fragments[1] or ""):trim();

    if (command == "") then
      UH.Helpers:ShowNotification("Type /UH help for commands");
    elseif (command == "help") then
      UH.Helpers:ShowNotification("Use the following parameters with /UH");
      print("- |cffddff00debug|r");
      print("  Toggle the debug mode");
      print("- |cffddff00options|r");
      print("  Open the options");
      print("- |cffddff00cd or cds|r");
      print("  Toggle cooldowns frame");
    elseif (command == "debug") then
      UH.db.global.debugMode = (not UH.db.global.debugMode);
      local debugText = UH.db.global.debugMode and "ON" or "OFF";
      UH.Helpers:ShowNotification("Debug mode " .. debugText);
    elseif (command == "options") then
      Settings.OpenToCategory(ADDON_NAME);
    elseif (command == "cd" or command == "cds") then
      UH.Events:TriggerEvent("TOGGLE_COOLDOWNS_FRAME");
    elseif (command == "migrate") then
      UH:MigrateDB();
    else
      UH.Helpers:ShowNotification("Command not found");
    end
  end
end

function UH:RegisterOptions()
  local parent = nil;
  addonTable.GenerateOptions();

  for _, option in ipairs(UH.Options) do
    LibStub("AceConfig-3.0"):RegisterOptionsTable(option.key, option.group);
    local frame, categoryID = UH.AceConfigDialog:AddToBlizOptions(option.key, option.name, parent);
    option.categoryID = categoryID;

    if (option.root) then
      parent = option.name;
    end
  end
end

function UH:CreateMinimapIcon()
  LDB:NewDataObject(ADDON_NAME, {
    type = "data source",
    text = "0",
    icon = UH.Enums.MINIMAP_ICON.NORMAL,
    OnClick = function(self, button)
      if (button == "LeftButton") then
        if (IsShiftKeyDown()) then
          -- UH.Events:TriggerEvent("TOGGLE_DATA_FRAME");
        else
          if (SettingsPanel:IsShown()) then
            SettingsPanel:Close();
          else
            Settings.OpenToCategory(ADDON_NAME);
          end
        end
      elseif (button == "RightButton") then
        if (IsShiftKeyDown()) then
          -- Settings.OpenToCategory(ADDON_NAME);
        else
          UH.Events:TriggerEvent("TOGGLE_COOLDOWNS_FRAME");
        end
      end
    end,
    OnTooltipShow = function(self)
      self:AddDoubleLine(ADDON_NAME,
        UH.Helpers:AddColorToString("Version " .. C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version"), "FFB1B1B1"));

      if (UH.db.global.options.cooldowns) then
        local textCount;

        if (UH.lastCountReadyCooldowns > 0) then
          textCount = UH.Helpers:AddColorToString(
            UH.lastCountReadyCooldowns .. " cooldown" .. (UH.lastCountReadyCooldowns > 1 and "s" or "") .. " READY",
            "FF27BD34");
        else
          textCount = "No cooldowns ready";
        end

        self:AddLine(" ");
        self:AddLine(textCount);
      end

      self:AddLine(" ");
      self:AddLine(UH.Helpers:AddColorToString("[Left Click]", "FF9CD6DE") ..
        " " .. UH.Helpers:AddColorToString("to open the options", "FFDDFF00"));
      self:AddLine(UH.Helpers:AddColorToString("[Right Click]", "FF9CD6DE") ..
        " " .. UH.Helpers:AddColorToString("to open/close cooldowns", "FFDDFF00"));
    end
  });
  UH.LDBIcon:Register(ADDON_NAME, LDB:GetDataObjectByName(ADDON_NAME), UH.db.global.minimapIcon);

  local frame = UH.LDBIcon:GetMinimapButton(ADDON_NAME);
  if (frame) then
    frame:SetFrameLevel(9);
  end
end

function UH:OnInitialize()
  -- Migration code from the old name, should be
  if (MDHdatabase) then
    UHdatabase = MDHdatabase;
    MDHdatabase = nil;
  end

  UH:InitVariables();
  UH:SetupSlashCommands();
  UH:RegisterOptions();
  UH:CreateMinimapIcon();

  UH.Compatibility.Baganator();

  if (UH.db.global.options.simpleStatsTooltip) then
    UH:EnableModule("Tooltip");
  end

  if (UH.db.global.options.autoBuy) then
    UH:EnableModule("AutoBuy");
  end

  if (UH.db.global.options.cooldowns) then
    UH:EnableModule("Cooldowns");
  end

  UH.addonReady = true;
end

function UH:UpdateCharacter()
  function GetPlayerIndex(name)
    for index, value in pairs(UH.db.global.characters) do
      if (value.name == name) then
        return index;
      end
    end
  end

  local name = UnitName("player");
  ---@type Character
  local playerTable = {
    name = name,
    race = select(1, UnitRace("player")),
    className = select(2, UnitClass("player")),
    group = UH.Enums.CHARACTER_GROUP.UNGROUPED,
    cooldownGroup = UH:GetModule("Cooldowns"):UpdateCurrentCharacterCooldowns(),
  };

  local playerIndex = GetPlayerIndex(name);

  if (playerIndex) then
    playerTable.group = UH.db.global.characters[playerIndex].group;
    UH.db.global.characters[playerIndex] = playerTable;
  else
    tinsert(UH.db.global.characters, playerTable);
  end

  UH.Events:TriggerEvent("CHARACTER_UPDATED");
end

function UH:UpdateBrokerIcon(hasNotification)
  local data = LDB:GetDataObjectByName(ADDON_NAME);
  data.icon = hasNotification and UH.Enums.MINIMAP_ICON.NOTIFICATION or UH.Enums.MINIMAP_ICON.NORMAL;
  UH.LDBIcon:Refresh(ADDON_NAME);
end

-- Events
UH.Events = CreateFromMixins(CallbackRegistryMixin);
UH.Events:OnLoad();
UH.Events:GenerateCallbackEvents({
  "CHARACTER_UPDATE_NEEDED",
  "CHARACTER_UPDATED",
  "OPTIONS_CHANGED",
  "CHARACTER_DELETED",
  "SHOW_COOLDOWNS_FRAME",
  "HIDE_COOLDOWNS_FRAME",
  "TOGGLE_COOLDOWNS_FRAME",
  "COUNT_READY_COOLDOWNS_CHANGED",
});

UH.Events:RegisterCallback("CHARACTER_UPDATE_NEEDED", function(_, name)
  UH:UpdateCharacter();
end);

UH.Events:RegisterCallback("OPTIONS_CHANGED", function(_, name)
  if (name == "autoBuy") then
    if (UH.db.global.options.autoBuy) then
      UH:EnableModule("AutoBuy");
    else
      UH:DisableModule("AutoBuy");
    end
  end

  if (name == "cooldowns") then
    if (UH.db.global.options.cooldowns) then
      UH:EnableModule("Cooldowns");
    else
      UH:DisableModule("Cooldowns");
    end
  end
end);

UH.Events:RegisterCallback("COUNT_READY_COOLDOWNS_CHANGED", function(_, count, first)
  UH:UpdateBrokerIcon(count > 0);

  if (not first and count > 0 and UH.db.global.options.cooldownPlaySound) then
    PlaySoundFile("Interface\\AddOns\\" .. ADDON_NAME .. "\\Assets\\Sounds\\Cooldown_Ready.ogg", "Master");
  end
end);

---@class Character
---@field name string
---@field race number
---@field className number
---@field group number
---@field cooldownGroup table<string, CurrentCooldown[]>
