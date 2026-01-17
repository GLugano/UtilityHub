local ADDON_NAME = ...;
---@type UtilityHub
local UH = LibStub('AceAddon-3.0'):GetAddon(ADDON_NAME);
local moduleName = 'Cooldowns';
---@class Cooldowns
---@diagnostic disable-next-line: undefined-field
local Module = UH:NewModule(moduleName);
Module.frame = nil;

---@class NormalizedCooldown
---@field duration number
---@field expiration number
---@field start number

---@class BasicCooldown
---@field name string
---@field spellID? number
---@field itemID? number

---@class GroupedCooldown : BasicCooldown
---@field spellList? BasicCooldown[]

---@class CurrentCooldown
---@field name string
---@field start number | nil
---@field maxCooldown number

---@class CooldownList
local baseCooldowns = {
  ---@type BasicCooldown[]
  Tailoring      = {},
  ---@type GroupedCooldown[]
  Alchemy        = {
    { name = "Transmutes", spellList = {} },
  },
  ---@type BasicCooldown[]
  Leatherworking = {},
};

if (UH.IsClassic) then
  tinsert(baseCooldowns.Tailoring, { name = "Mooncloth", spellID = 18560 });

  local transmutes = baseCooldowns.Alchemy[1];

  if (transmutes) then
    tinsert(transmutes.spellList, { name = "Arcanite Bar", spellID = 17187 });
    tinsert(transmutes.spellList, { name = "Water to Air", spellID = 17562 });
    tinsert(transmutes.spellList, { name = "Water to Undeath", spellID = 17564 });
    tinsert(transmutes.spellList, { name = "Earth to Life", spellID = 17566 });
    tinsert(transmutes.spellList, { name = "Earth to Water", spellID = 17561 });
    tinsert(transmutes.spellList, { name = "Air to Fire", spellID = 17559 });
    tinsert(transmutes.spellList, { name = "Life to Earth", spellID = 17565 });
    tinsert(transmutes.spellList, { name = "Undeath to Water", spellID = 17563 });
    tinsert(transmutes.spellList, { name = "Elemental Fire", spellID = 20761 });
    tinsert(transmutes.spellList, { name = "Mithril to Truesilver", spellID = 11480 });
    tinsert(transmutes.spellList, { name = "Iron to Gold", spellID = 11479 });
  end

  tinsert(baseCooldowns.Leatherworking, { name = "Cured Rugged Hide", itemID = 15846 });
elseif (UH.IsTBC) then
  tinsert(baseCooldowns.Tailoring, { name = "Shadowcloth", spellID = 36686 });
  tinsert(baseCooldowns.Tailoring, { name = "Spellcloth", spellID = 31373 });
  tinsert(baseCooldowns.Tailoring, { name = "Primal Mooncloth", spellID = 26751 });
end

--- @param cooldowns table<string, CurrentCooldown[]>
--- @param group string
--- @param value CurrentCooldown
local function InsertInCooldownTable(cooldowns, group, value)
  local cooldownGroup = cooldowns[group];

  if (not cooldownGroup) then
    cooldownGroup = {};
    cooldowns[group] = cooldownGroup;
  end

  tinsert(cooldowns[group], value);
end

local DAY_IN_MS = 24 * 60 * 60;

---@param cooldown CurrentCooldown
---@return string "Converted time"
---@return boolean "If its ready"
---@return table "RGB"
local function CooldownToRemainingTime(cooldown)
  ---@param rgb BasicRGB
  ---@return table
  function ToRGB(rgb)
    return { r = rgb.r / 255, g = rgb.g / 255, b = rgb.b / 255 };
  end

  if (cooldown.start and cooldown.start > 0) then
    local endTime = cooldown.start + cooldown.maxCooldown;
    local remaining = endTime - GetTime();

    if (remaining > 0) then
      if (remaining >= DAY_IN_MS) then
        local days = math.floor(remaining / DAY_IN_MS);
        return days .. (days == 1 and " day" or " days"), false, ToRGB({ r = 255, g = 255, b = 255 });
      end

      local hours = math.floor(remaining / 3600);
      local minutes = math.floor((remaining % 3600) / 60);
      local seconds = remaining % 60;
      local rgb = { r = 252, g = 186, b = 3 };

      if (hours < 12) then
        rgb = { r = 255, g = 71, b = 71 };
      end

      return string.format("%02d:%02d:%02d", hours, minutes, seconds), false, ToRGB(rgb);
    end
  end

  return "Ready", true, ToRGB({ r = 16, g = 179, b = 16 });
end

Module.Ticker = C_Timer.NewTicker(1, function()
  if (UH.addonReady) then
    Module:UpdateCountReadyCooldowns();
  end

  if (not Module.Frame or not Module.Frame:IsShown()) then
    return;
  end

  local dataProvider = Module.Frame.ScrollBox:GetDataProvider();

  if (not dataProvider) then
    return;
  end

  for _, frame in ipairs(Module.Frame.ScrollBox:GetFrames()) do
    if (frame.Timer) then
      frame.Timer:Update();
    end
  end
end);

Module.CollapsedGroups = {};

---@return table<string, CurrentCooldown[]>
function Module:UpdateCurrentCharacterCooldowns()
  ---@param cooldown BasicCooldown|GroupedCooldown
  ---@return number|nil
  function GetSpellIDFromCooldown(cooldown)
    if (cooldown.spellList and #cooldown.spellList > 0) then
      for _, spell in pairs(cooldown.spellList) do
        if (C_SpellBook.IsSpellKnown(spell.spellID)) then
          return spell.spellID;
        end
      end
    else
      if (C_SpellBook.IsSpellKnown(cooldown.spellID)) then
        return cooldown.spellID;
      end
    end

    return nil;
  end

  ---@param start number|nil
  ---@param duration number|nil
  ---@return NormalizedCooldown
  function GetNormalizedCooldownValues(start, duration)
    -- Source: https://wago.io/ku2ECkSTv/3
    -- The good function doesnt exist in classic
    local normalizedData = {};
    local now = GetTime();

    if (not start) then
      start = 0;
    end

    if (not duration) then
      duration = 0;
    end

    if (duration > 604800) then
      start = 0;
      duration = 0;
    end

    if (start > now + 2147483.648) then
      start = start - 4294967.296;
    end

    local dt = now - start;
    local serverStart = GetServerTime() - dt;
    local serverExpiration = serverStart + duration;

    normalizedData.start = start;
    normalizedData.duration = duration;
    normalizedData.expiration = serverExpiration;

    return normalizedData;
  end

  ---@type table<string, CurrentCooldown[]>
  local newCooldowns = {};

  for i = 1, GetNumSkillLines() do
    local skillName = GetSkillLineInfo(i);
    ---@type GroupedCooldown|BasicCooldown|nil
    local cdGroup = baseCooldowns[skillName];

    if (cdGroup) then
      for _, cooldown in pairs(cdGroup) do
        if (cooldown.spellID or (cooldown.spellList and #cooldown.spellList > 0)) then
          ---@type number|nil
          local spellID = GetSpellIDFromCooldown(cooldown);

          if (spellID) then
            local spi = C_Spell.GetSpellCooldown(spellID);
            local normalized = GetNormalizedCooldownValues(spi.startTime, spi.duration);

            if (spi) then
              InsertInCooldownTable(
                newCooldowns,
                skillName,
                {
                  name = cooldown.name,
                  maxCooldown = normalized.duration,
                  start = normalized.start,
                }
              );
            end
          end
        elseif (cooldown.itemID) then
          if (C_Item.GetItemCount(cooldown.itemID, true) > 0) then
            local start, duration = C_Container.GetItemCooldown(cooldown.itemID);
            local normalized = GetNormalizedCooldownValues(start, duration);
            InsertInCooldownTable(
              newCooldowns,
              skillName,
              {
                name = cooldown.name,
                maxCooldown = normalized.duration,
                start = normalized.start,
              }
            );
          end
        end
      end
    end
  end

  return newCooldowns;
end

function Module:UpdateCountReadyCooldowns()
  local currentCount = 0;

  for _, character in pairs(UH.db.global.characters) do
    for _, cooldownGroup in pairs(character.cooldownGroup or {}) do
      for _, cooldown in pairs(cooldownGroup) do
        local endTime = cooldown.start + cooldown.maxCooldown;
        local remaining = endTime - GetTime();

        if (cooldown.start == 0 or remaining < 0) then
          currentCount = currentCount + 1;
        end
      end
    end
  end

  if (currentCount ~= UH.lastCountReadyCooldowns) then
    UH.Events:TriggerEvent("COUNT_READY_COOLDOWNS_CHANGED", currentCount, UH.lastCountReadyCooldowns == nil);
  end

  UH.lastCountReadyCooldowns = currentCount;
end

-- Frame
function Module:CreateCooldownsFrame()
  local frame = CreateFrame("Frame", nil, UIParent, "SettingsFrameTemplate");
  Module.Frame = frame;
  frame:SetSize(250, 350);
  frame:Hide();
  local savedPosition = UH.db.global.cooldownFramePosition;

  if (UH.db.global.cooldownFramePosition) then
    frame:SetPoint(
      savedPosition.point,
      frame:GetParent(),
      savedPosition.relativePoint,
      savedPosition.x,
      savedPosition.y
    );
  else
    frame:SetPoint("CENTER");
  end

  frame.NineSlice.Text:SetText("Cooldowns");
  UH.UTILS:AddMovableToFrame(frame, function(pos)
    UH.db.global.cooldownFramePosition = pos;
  end);

  local content = CreateFrame("Frame", nil, frame);
  frame.Content = content;
  content:SetWidth(frame:GetSize());
  content:SetPoint("TOPLEFT", 15, -25);
  content:SetPoint("BOTTOMRIGHT", -5, 7);

  frame.ScrollBar = CreateFrame("EventFrame", nil, content, "MinimalScrollBar");
  frame.ScrollBar:SetPoint("TOPRIGHT", -10, -5);
  frame.ScrollBar:SetPoint("BOTTOMRIGHT", 0, 5);

  frame.ScrollBox = CreateFrame("Frame", nil, content, "WowScrollBoxList");
  frame.ScrollBox:SetPoint("TOPLEFT", 2, -4);
  frame.ScrollBox:SetPoint("BOTTOMRIGHT", frame.ScrollBar, "BOTTOMLEFT", -3, 0);

  local indent = 10;
  local padLeft = 0;
  local pad = 5;
  local spacing = 1;
  local view = CreateScrollBoxListTreeListView(indent, pad, pad, padLeft, pad, spacing);
  Module.View = view;

  view:SetElementFactory(function(factory, node)
    local elementData = node:GetData();

    if (elementData.group) then
      local function Initializer(button, node)
        if (not Module.CollapsedGroups[elementData.group]) then
          Module.CollapsedGroups[elementData.group] = node:IsCollapsed();
        end
        button.Label:SetText(elementData.group);
        button:SetCollapseState(Module.CollapsedGroups[elementData.group]);

        button:SetScript("OnClick", function(button)
          node:ToggleCollapsed();
          Module.CollapsedGroups[elementData.group] = node:IsCollapsed();
          button:SetCollapseState(node:IsCollapsed());
          PlaySound(SOUNDKIT.IG_MAINMENU_OPTION);
        end);
      end

      factory("TreeGroupButtonTemplate", Initializer);
    elseif (elementData.character) then
      local function Initializer(button, node)
        local width = button:GetWidth();

        button:SetPushedTextOffset(0, 0);
        button:SetHighlightAtlas("search-highlight");
        button:SetNormalFontObject(GameFontHighlight);
        button:SetText(elementData.character);
        button.elementData = elementData;
        button:GetFontString():SetPoint("LEFT", 12, 0);
        button:GetFontString():SetPoint("RIGHT", -(width / 2), 0);
        button:GetFontString():SetJustifyH("LEFT");

        if (not button.Timer) then
          button.Timer = button:CreateFontString(nil, "OVERLAY", "GameFontNormal");
          button.Timer:SetPoint("LEFT", (width / 2), 0);
          button.Timer:SetPoint("RIGHT", -6, 0);
          button.Timer:SetJustifyH("RIGHT");

          function button.Timer:Update()
            local parent = self:GetParent();
            local text, ready, rgb = CooldownToRemainingTime(parent.elementData);
            self:SetText(text);
            self:SetTextColor(rgb.r, rgb.g, rgb.b);
          end
        end

        button.Timer:Update();

        node:SetCollapsed(Module.CollapsedGroups[elementData.group]);
      end
      factory("Button", Initializer);
    else
      factory("Frame");
    end
  end);

  view:SetElementExtentCalculator(function(dataIndex, node)
    local elementData = node:GetData();
    local baseElementHeight = 20;
    local categoryPadding = 5;

    if (elementData.character) then
      return baseElementHeight;
    end

    if (elementData.group) then
      return baseElementHeight + categoryPadding;
    end

    return 0;
  end);

  ScrollUtil.InitScrollBoxListWithScrollBar(frame.ScrollBox, frame.ScrollBar, view);
end

function Module:UpdateCooldownsFrameList()
  local groups = setmetatable({}, {
    __index = {
      InsertGroup = function(self, group)
        for _, loopGroup in ipairs(self) do
          if (loopGroup.group == group.group) then
            return loopGroup;
          end
        end

        tinsert(self, group);

        return group;
      end,
      ToTreeDataProvider = function(self)
        local dataProvider = CreateTreeDataProvider();

        for _, group in pairs(self) do
          local groupDataNode = dataProvider:Insert({ group = group.group });

          for _, cooldown in pairs(group.cooldowns) do
            groupDataNode:Insert(cooldown);
          end
        end

        return dataProvider;
      end,
    },
  });

  for _, character in pairs(UH.db.global.characters) do
    for _, cooldownGroup in pairs(character.cooldownGroup or {}) do
      for _, cooldown in pairs(cooldownGroup) do
        local group = groups:InsertGroup({ group = cooldown.name, cooldowns = {} });
        tinsert(group.cooldowns, {
          groupName = cooldown.name,
          cooldown = cooldown.name,
          character = character.name,
          start = cooldown.start,
          maxCooldown = cooldown.maxCooldown,
        });
      end
    end
  end

  Module.Frame.ScrollBox:SetDataProvider(groups:ToTreeDataProvider());
end

function Module:ShowFrame()
  if (not Module:IsEnabled()) then
    UH.Helpers:ShowNotification(moduleName .. " module is not enabled");
    return;
  end

  if (Module.Frame) then
    Module.Frame:Show();
    Module:UpdateCooldownsFrameList();
  end
end

function Module:HideFrame()
  if (Module.Frame) then
    Module.Frame:Hide();
  end
end

function Module:ToggleFrame()
  if (not Module.Frame) then
    return;
  end

  if (Module.Frame:IsShown()) then
    Module:HideFrame();
  else
    Module:ShowFrame();
  end
end

-- Life cycle
function Module:OnInitialize()
  if (not Module.Frame) then
    Module:CreateCooldownsFrame();
  end
end

-- Events
local function skillUpdated(...)
  if (UH.addonReady and GetNumSkillLines() > 0) then
    UH.Events:TriggerEvent("CHARACTER_UPDATE_NEEDED");
  end
end

EventRegistry:RegisterFrameEventAndCallback("SKILL_LINES_CHANGED", skillUpdated);
EventRegistry:RegisterFrameEventAndCallback("TRADE_SKILL_LIST_UPDATE", skillUpdated);
EventRegistry:RegisterFrameEventAndCallback("TRADE_SKILL_UPDATE", skillUpdated);

UH.Events:RegisterCallback("CHARACTER_UPDATED", function(_, name)
  Module:UpdateCooldownsFrameList();
end);

UH.Events:RegisterCallback("OPEN_COOLDOWNS_FRAME", function(_, name)
  Module:ShowFrame();
end);

UH.Events:RegisterCallback("HIDE_COOLDOWNS_FRAME", function(_, name)
  Module:HideFrame();
end);

UH.Events:RegisterCallback("TOGGLE_COOLDOWNS_FRAME", function(_, name)
  Module:ToggleFrame();
end);
