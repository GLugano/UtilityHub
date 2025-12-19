local ADDON_NAME = ...;
---@type UtilityHub
local UH = LibStub('AceAddon-3.0'):GetAddon(ADDON_NAME);
local moduleName = 'Cooldowns';
---@class Cooldowns
---@diagnostic disable-next-line: undefined-field
local Module = UH:NewModule(moduleName);
Module.frame = nil;

---@class SimpleCooldown
---@field name string
---@field spellID? number
---@field itemID? number

---@class Cooldown : SimpleCooldown
---@field spellList? SimpleCooldown[]

---@class CurrentCooldown
---@field name string
---@field start number | nil
---@field maxCooldown number

UH.cooldowns = {
  ---@type Cooldown[]
  Tailoring = {},
  ---@type Cooldown[]
  Alchemy = {
    { name = "Transmutes", spellList = {} },
  },
  ---@type Cooldown[]
  Leatherworking = {},
};

-- TODO: Check if its necessary now to be here instead of fixed in the list
if (UH.IsClassic) then
  tinsert(UH.cooldowns.Tailoring, { name = "Mooncloth", spellID = 18560 });

  tinsert(UH.cooldowns.Alchemy[1].spellList, { name = "Arcanite Bar", spellID = 17187 });
  tinsert(UH.cooldowns.Alchemy[1].spellList, { name = "Water to Air", spellID = 17562 });
  tinsert(UH.cooldowns.Alchemy[1].spellList, { name = "Water to Undeath", spellID = 17564 });
  tinsert(UH.cooldowns.Alchemy[1].spellList, { name = "Earth to Life", spellID = 17566 });
  tinsert(UH.cooldowns.Alchemy[1].spellList, { name = "Earth to Water", spellID = 17561 });
  tinsert(UH.cooldowns.Alchemy[1].spellList, { name = "Air to Fire", spellID = 17559 });
  tinsert(UH.cooldowns.Alchemy[1].spellList, { name = "Life to Earth", spellID = 17565 });
  tinsert(UH.cooldowns.Alchemy[1].spellList, { name = "Undeath to Water", spellID = 17563 });
  tinsert(UH.cooldowns.Alchemy[1].spellList, { name = "Elemental Fire", spellID = 20761 });
  tinsert(UH.cooldowns.Alchemy[1].spellList, { name = "Mithril to Truesilver", spellID = 11480 });
  tinsert(UH.cooldowns.Alchemy[1].spellList, { name = "Iron to Gold", spellID = 11479 });

  tinsert(UH.cooldowns.Leatherworking, { name = "Cured Rugged Hide", itemID = 15846 });
elseif (UH.IsTBC) then
  tinsert(UH.cooldowns.Tailoring, { name = "Shadowcloth", spellID = 36686 });
  tinsert(UH.cooldowns.Tailoring, { name = "Spellcloth", spellID = 31373 });
  tinsert(UH.cooldowns.Tailoring, { name = "Primal Mooncloth", spellID = 26751 });
end

local function InsertInCooldownTable(cooldowns, group, value)
  if (not cooldowns[group]) then
    cooldowns[group] = {};
  end

  tinsert(cooldowns[group], value);
end

local DAY_IN_MS = 24 * 60 * 60;
---@return string "Converted time"
---@return boolean "If its ready"
---@return table "RGB"
local function CooldownToRemainingTime(cooldown)
  function ToRGB(rgb)
    return { r = rgb.r / 255, g = rgb.g / 255, b = rgb.b / 255 }
  end

  local endTime = cooldown.start + cooldown.maxCooldown;
  local remaining = endTime - GetTime();

  if (cooldown.start == 0 or remaining < 0) then
    return "Ready", true, ToRGB({ r = 16, g = 179, b = 16 });
  end

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
  local function GetCurrentCooldownFromSpellID(spellID, name)
    local spi = C_Spell.GetSpellCooldown(spellID);

    return {
      name = name,
      maxCooldown = spi.duration,
      start = spi.startTime,
    };
  end

  ---@type table<string, CurrentCooldown[]>
  local cooldowns = {};

  for i = 1, GetNumSkillLines() do
    local skillName = GetSkillLineInfo(i);
    ---@type Cooldown[]
    local cdGroup = UH.cooldowns[skillName];

    if (cdGroup) then
      for _, cooldown in pairs(cdGroup) do
        if (cooldown.spellID) then
          if (C_SpellBook.IsSpellKnown(cooldown.spellID) or (cooldown.spellList and #cooldown.spellList > 0)) then
            local ic;

            if (cooldown.spellList and #cooldown.spellList > 0) then
              ic = cooldown.spellList[0];
            else
              ic = cooldown;
            end

            if (ic) then
              InsertInCooldownTable(cooldowns, skillName, GetCurrentCooldownFromSpellID(ic.spellID, ic.name));
            end
          elseif (cooldown.itemID) then
            if (C_Item.GetItemCount(cooldown.itemID, true) > 0) then
              local startTime, duration, enabled = C_Container.GetItemCooldown(cooldown.itemID);

              ---@type CurrentCooldown
              local currentCooldown = {
                name = cooldown.name,
                maxCooldown = duration,
                start = startTime,
              };
              InsertInCooldownTable(cooldowns, skillName, currentCooldown);
            end
          end
        end
      end
    end
  end

  return cooldowns;
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

      factory("CooldownGroupButtonTemplate", Initializer);
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
      GetGroupIndex = function(self, name)
        for index, group in ipairs(self) do
          if (group.name == name) then
            return index;
          end
        end

        return nil;
      end,
      InsertGroup = function(self, group)
        for index, loopGroup in ipairs(self) do
          if (loopGroup.name == group.name) then
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
    for cooldownGroupName, cooldownGroup in pairs(character.cooldownGroup or {}) do
      for _, cooldown in pairs(cooldownGroup) do
        local group = groups:InsertGroup({ group = cooldown.name, cooldowns = {} });
        tinsert(group.cooldowns, {
          groupName = character.cooldownGroup,
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
    UH.Helpers:ShowNotification("Cooldowns module is not enabled");
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

-- Mixins
CooldownGroupMixin = {};

function CooldownGroupMixin:OnEnter()
  self.Label:SetFontObject(GameFontHighlight_NoShadow);
end

function CooldownGroupMixin:OnLeave()
  self.Label:SetFontObject(GameFontNormal_NoShadow);
end

function CooldownGroupMixin:SetCollapseState(collapsed)
  if (collapsed) then
    self.CollapseIcon:SetTexCoord(0.302246, 0.312988, 0.0537109, 0.0693359)
    self.CollapseIconAlphaAdd:SetTexCoord(0.302246, 0.312988, 0.0537109, 0.0693359)
  else
    self.CollapseIcon:SetTexCoord(0.270508, 0.28125, 0.0537109, 0.0693359)
    self.CollapseIconAlphaAdd:SetTexCoord(0.270508, 0.28125, 0.0537109, 0.0693359)
  end
end
