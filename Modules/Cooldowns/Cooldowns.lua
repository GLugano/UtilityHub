local moduleName = 'Cooldowns';
---@class Cooldowns
local Module = UtilityHub.Addon:NewModule(moduleName);
Module.frame = nil;

---@return boolean
local function IsDebugMode()
  return UtilityHub.Database and UtilityHub.Database.global and UtilityHub.Database.global.debugMode;
end

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

-- Still a cooldown in the tbc pre patch
tinsert(baseCooldowns.Leatherworking, { name = "Refined Deeprock Salt", itemID = 15846 });

if (UtilityHub.Constants.IsClassic) then
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
elseif (UtilityHub.Constants.IsTBC) then
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

---@param str string
---@param numChars number
---@return string
local function Utf8Sub(str, numChars)
  local bytePos = 1;
  local strLen = #str;

  for i = 1, numChars do
    if (bytePos > strLen) then
      break;
    end

    local byte = string.byte(str, bytePos);

    if (byte >= 240) then
      bytePos = bytePos + 4;
    elseif (byte >= 224) then
      bytePos = bytePos + 3;
    elseif (byte >= 192) then
      bytePos = bytePos + 2;
    else
      bytePos = bytePos + 1;
    end
  end

  return string.sub(str, 1, bytePos - 1);
end

---@param remaining number
---@return string
local function FormatReadyDate(remaining)
  local readyTime = time() + remaining;
  local t = date("*t", readyTime);

  local dayName = CALENDAR_WEEKDAY_NAMES[t.wday];
  local monthName = CALENDAR_FULLDATE_MONTH_NAMES[t.month];
  local shortDay = Utf8Sub(dayName, 3);
  local shortMonth = Utf8Sub(monthName, 3);

  local locale = GetLocale();

  if (locale == "enUS" or locale == "enGB") then
    return string.format("%s, %s %d %02d:%02d", shortDay, shortMonth, t.day, t.hour, t.min);
  end

  return string.format("%s, %d %s %02d:%02d", shortDay, t.day, shortMonth, t.hour, t.min);
end

---@param timestamp number
---@return string
local function FormatDateGroupLabel(timestamp)
  local t = date("*t", timestamp);

  local dayName = CALENDAR_WEEKDAY_NAMES[t.wday];
  local monthName = CALENDAR_FULLDATE_MONTH_NAMES[t.month];
  local shortDay = Utf8Sub(dayName, 3);
  local shortMonth = Utf8Sub(monthName, 3);

  local locale = GetLocale();

  if (locale == "enUS" or locale == "enGB") then
    return string.format("%s, %s %d", shortDay, shortMonth, t.day);
  end

  return string.format("%s, %d %s", shortDay, t.day, shortMonth);
end

---@param remaining number
---@return string
local function FormatReadyTime(remaining)
  local readyTime = time() + remaining;
  local t = date("*t", readyTime);
  return string.format("%02d:%02d", t.hour, t.min);
end

---@param cooldown CurrentCooldown
---@return string "Converted time"
---@return boolean "If its ready"
---@return table "RGB"
---@return string|nil "Ready date"
---@return string|nil "Ready time (HH:MM)"
local function CooldownToRemainingTime(cooldown)
  if (cooldown.start and cooldown.maxCooldown and cooldown.maxCooldown > 0) then
    local endTime = cooldown.start + cooldown.maxCooldown;
    local remaining = endTime - GetTime();

    if (remaining > 0) then
      local progress = math.max(0, math.min(1, remaining / cooldown.maxCooldown));
      local r, g;

      if (progress > 0.5) then
        r = 1.0;
        g = (1.0 - progress) * 2;
      else
        r = progress * 2;
        g = 1.0;
      end

      local rgb = { r = r, g = g, b = 0 };
      local readyDate = FormatReadyDate(remaining);
      local readyTime = FormatReadyTime(remaining);

      if (remaining >= DAY_IN_MS) then
        local days = math.floor(remaining / DAY_IN_MS);
        return days .. (days == 1 and " day" or " days"), false, rgb, readyDate, readyTime;
      end

      local hours = math.floor(remaining / 3600);
      local minutes = math.floor((remaining % 3600) / 60);
      local seconds = remaining % 60;

      return string.format("%02d:%02d:%02d", hours, minutes, seconds), false, rgb, readyDate, readyTime;
    end
  end

  return "Ready", true, { r = 16 / 255, g = 179 / 255, b = 16 / 255 }, nil, nil;
end

Module.Ticker = C_Timer.NewTicker(1, function()
  if (UtilityHub.Flags.addonReady) then
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
Module.NotifiedCooldowns = {};
Module.CountReadyGraceTicks = 5;

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
  local currentReadySet = {};

  for _, character in ipairs(UtilityHub.Database.global.characters) do
    for _, cooldownGroup in pairs(character.cooldownGroup or {}) do
      for _, cooldown in ipairs(cooldownGroup) do
        local endTime = cooldown.start + cooldown.maxCooldown;
        local remaining = endTime - GetTime();

        if (cooldown.start == 0 or remaining < 0) then
          currentCount = currentCount + 1;

          local key = character.name .. ":" .. cooldown.name;
          currentReadySet[key] = character.name .. " - " .. cooldown.name;

          -- Log Point 6: Transição para Ready
          if (IsDebugMode() and not Module.NotifiedCooldowns[key] and Module.CountReadyGraceTicks == 0) then
            local reason;
            if (cooldown.start == 0) then
              reason = "start=0";
            else
              reason = string.format("expired (%.0fs ago)", math.abs(remaining));
            end
            local now = GetTime();
            UtilityHub.Helpers.DebugLog:Add(
              string.format(
                "|cffFFFF00[UH-SYNC]|r |cff00FF00READY|r %s - %s (%s) [start=%.2f, max=%d, end=%.2f, now=%.2f]",
                character.name,
                cooldown.name,
                reason,
                cooldown.start,
                cooldown.maxCooldown,
                cooldown.start + cooldown.maxCooldown,
                now
              ));
          end
        end
      end
    end
  end

  local isInitializing = Module.CountReadyGraceTicks > 0;

  if (Module.CountReadyGraceTicks > 0) then
    Module.CountReadyGraceTicks = Module.CountReadyGraceTicks - 1;
  end

  if (not isInitializing) then
    local hasNewReady = false;

    for key, label in pairs(currentReadySet) do
      if (not Module.NotifiedCooldowns[key]) then
        UtilityHub.Helpers.Notification:ShowNotification("Cooldown - " .. label .. " is ready!");
        hasNewReady = true;
      end
    end

    if (hasNewReady and UtilityHub.Database.global.options.cooldownPlaySound) then
      PlaySoundFile("Interface\\AddOns\\UtilityHub\\Assets\\Sounds\\Cooldown_Ready.ogg", "Master");
    end

    Module.NotifiedCooldowns = currentReadySet;
  end

  if (currentCount ~= UtilityHub.lastCountReadyCooldowns) then
    UtilityHub.Events:TriggerEvent(
      "COUNT_READY_COOLDOWNS_CHANGED",
      currentCount,
      isInitializing
    );
  end

  UtilityHub.lastCountReadyCooldowns = currentCount;
end

-- Frame
function Module:CreateCooldownsFrame()
  local MIN_WIDTH = 250;
  local MIN_HEIGHT = 180;
  local DEFAULT_WIDTH = 400;
  local DEFAULT_HEIGHT = 450;

  local frame = CreateFrame("Frame", nil, UIParent, "SettingsFrameTemplate");
  Module.Frame = frame;
  frame:SetResizable(true);
  frame:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT);
  frame:Hide();

  local savedSize = UtilityHub.Database.global.cooldownFrameSize;
  if (savedSize) then
    frame:SetSize(savedSize.width, savedSize.height);
  else
    frame:SetSize(DEFAULT_WIDTH, DEFAULT_HEIGHT);
  end
  local savedPosition = UtilityHub.Database.global.cooldownFramePosition;

  if (UtilityHub.Database.global.cooldownFramePosition) then
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
  UtilityHub.Libs.Utils:AddMovableToFrame(frame, function(pos)
    UtilityHub.Database.global.cooldownFramePosition = pos;
  end);

  local resizeHandle = CreateFrame("Button", nil, frame);
  resizeHandle:SetSize(16, 16);
  resizeHandle:SetPoint("BOTTOMRIGHT", -4, 4);
  resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");
  resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight");
  resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down");
  resizeHandle:SetScript("OnMouseDown", function(self, button)
    if (button == "LeftButton") then
      frame:StartSizing("BOTTOMRIGHT");
    end
  end);
  resizeHandle:SetScript("OnMouseUp", function(self, button)
    frame:StopMovingOrSizing();
    local w, h = frame:GetSize();
    UtilityHub.Database.global.cooldownFrameSize = { width = math.floor(w), height = math.floor(h) };
    Module:UpdateCooldownsFrameList();
  end);

  local content = CreateFrame("Frame", nil, frame);
  frame.Content = content;
  content:SetWidth(frame:GetSize());
  content:SetPoint("TOPLEFT", 15, -37);
  content:SetPoint("BOTTOMRIGHT", -5, 7);

  local groupByEnum = UtilityHub.Enums.CooldownGroupBy;
  local groupByText = UtilityHub.Enums.CooldownGroupByText;

  local dropdown = CreateFrame("Frame", "UHCooldownGroupByDropdown", content, "UIDropDownMenuTemplate");
  frame.GroupByDropdown = dropdown;
  dropdown:SetPoint("TOPLEFT", content, "TOPLEFT", -15, 2);
  UIDropDownMenu_SetWidth(dropdown, 140);

  local currentGroupBy = UtilityHub.Database.global.cooldownGroupBy or groupByEnum.CHARACTER;
  UIDropDownMenu_SetText(dropdown, groupByText[currentGroupBy]);

  UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
    local current = UtilityHub.Database.global.cooldownGroupBy or groupByEnum.CHARACTER;

    for _, value in ipairs({ groupByEnum.CHARACTER, groupByEnum.TYPE, groupByEnum.READY_DATE, groupByEnum.READY_DATE_PROFESSION }) do
      local info = UIDropDownMenu_CreateInfo();
      info.text = groupByText[value];
      info.value = value;
      info.checked = (current == value);
      info.func = function(btn)
        UtilityHub.Database.global.cooldownGroupBy = btn.value;
        UIDropDownMenu_SetText(dropdown, groupByText[btn.value]);
        Module.CollapsedGroups = {};
        Module:UpdateCooldownsFrameList();
        CloseDropDownMenus();
      end;
      UIDropDownMenu_AddButton(info);
    end
  end);

  local collapseBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate");
  frame.CollapseButton = collapseBtn;
  collapseBtn:SetSize(80, 28);
  collapseBtn:SetPoint("TOPRIGHT", content, "TOPRIGHT", -30, 2);
  collapseBtn:SetText("Collapse");

  collapseBtn:SetScript("OnClick", function()
    local dataProvider = Module.Frame.ScrollBox:GetDataProvider();

    if (not dataProvider) then
      return;
    end

    -- Check current state from all group nodes
    local allCollapsed = true;

    for _, node in dataProvider:EnumerateEntireRange() do
      local data = node:GetData();

      if (data.group) then
        if (not Module.CollapsedGroups[data.group]) then
          allCollapsed = false;
          break;
        end
      end
    end

    local newState = not allCollapsed;

    for _, node in dataProvider:EnumerateEntireRange() do
      local data = node:GetData();

      if (data.group) then
        Module.CollapsedGroups[data.group] = newState;
      end
    end

    collapseBtn:SetText(newState and "Expand" or "Collapse");
    Module:UpdateCooldownsFrameList();
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION);
  end);

  frame.ScrollBar = CreateFrame("EventFrame", nil, content, "MinimalScrollBar");
  frame.ScrollBar:SetPoint("TOPRIGHT", -10, -5);
  frame.ScrollBar:SetPoint("BOTTOMRIGHT", 0, 5);

  frame.ScrollBox = CreateFrame("Frame", nil, content, "WowScrollBoxList");
  frame.ScrollBox:SetPoint("TOPLEFT", 2, -30);
  frame.ScrollBox:SetPoint("BOTTOMRIGHT", frame.ScrollBar, "BOTTOMLEFT", -3, 0);

  local function UpdateScrollBoxAnchor()
    frame.ScrollBox:ClearAllPoints();
    frame.ScrollBox:SetPoint("TOPLEFT", 2, -30);
    if (frame.ScrollBar:IsShown()) then
      frame.ScrollBox:SetPoint("BOTTOMRIGHT", frame.ScrollBar, "BOTTOMLEFT", -3, 0);
    else
      frame.ScrollBox:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -3, 0);
    end
  end

  frame.ScrollBar:HookScript("OnShow", UpdateScrollBoxAnchor);
  frame.ScrollBar:HookScript("OnHide", UpdateScrollBoxAnchor);

  local indent = 10;
  local padLeft = 0;
  local pad = 5;
  local spacing = 2;
  local view = CreateScrollBoxListTreeListView(indent, pad, pad, padLeft, pad, spacing);
  Module.View = view;

  view:SetElementFactory(function(factory, node)
    local elementData = node:GetData();

    if (elementData.group) then
      local function Initializer(button, node)
        if (Module.CollapsedGroups[elementData.group] == nil) then
          Module.CollapsedGroups[elementData.group] = node:IsCollapsed();
        end

        local color = UtilityHub.Helpers.Color:GetRGBFromClassName(elementData.className);
        button.Label:SetText(elementData.group);
        button.Label:SetTextColor(color.r, color.g, color.b);

        local readySuffix = elementData.readyCount .. "/" .. elementData.totalCount .. " ready";
        button.LabelRight:SetText(readySuffix);
        button:SetCollapseState(Module.CollapsedGroups[elementData.group]);

        if (elementData.nearestEndTime) then
          button.Timer = {
            Update = function()
              local remaining = elementData.nearestEndTime - GetTime();

              if (remaining > 0) then
                local timeText;

                if (remaining >= DAY_IN_MS) then
                  local days = math.floor(remaining / DAY_IN_MS);
                  timeText = days .. (days == 1 and " day" or " days");
                else
                  local hours = math.floor(remaining / 3600);
                  local minutes = math.floor((remaining % 3600) / 60);
                  local seconds = remaining % 60;
                  timeText = string.format("%02d:%02d:%02d", hours, minutes, seconds);
                end

                button.LabelRight:SetText(timeText .. " - " .. readySuffix);
              else
                button.LabelRight:SetText(readySuffix);
              end
            end,
          };
          button.Timer:Update();
        else
          button.Timer = nil;
        end

        button:SetScript("OnClick", function(button)
          node:ToggleCollapsed();
          Module.CollapsedGroups[elementData.group] = node:IsCollapsed();
          button:SetCollapseState(node:IsCollapsed());
          PlaySound(SOUNDKIT.IG_MAINMENU_OPTION);
        end);
      end

      factory("TreeGroupButtonTemplate", Initializer);
    elseif (elementData.cooldown) then
      local function Initializer(button, node)
        local width = button:GetWidth();
        local timerWidth = width * 0.3;

        button:SetPushedTextOffset(0, 0);
        button:SetHighlightAtlas("search-highlight");
        button:SetNormalFontObject(GameFontHighlight);
        button:SetText(elementData.cooldown);
        button.elementData = elementData;
        button:GetFontString():ClearAllPoints();
        button:GetFontString():SetPoint("LEFT", 12, 0);
        button:GetFontString():SetPoint("RIGHT", -(timerWidth + 6), 0);
        button:GetFontString():SetJustifyH("LEFT");
        button:GetFontString():SetWordWrap(false);

        if (not button.Timer) then
          button.Timer = button:CreateFontString(nil, "OVERLAY");
          local font, size, flags = GameFontNormal:GetFont();
          button.Timer:SetFont(font, size, flags);
          button.Timer:SetJustifyH("RIGHT");
        end
        button.Timer:ClearAllPoints();
        button.Timer:SetPoint("TOPRIGHT", -6, -2);
        button.Timer:SetPoint("LEFT", width - timerWidth - 6, 0);

        if (not button.ReadyDate) then
          button.ReadyDate = button:CreateFontString(nil, "OVERLAY");
          local font, size, flags = GameFontNormal:GetFont();
          button.ReadyDate:SetFont(font, size - 2, flags);
          button.ReadyDate:SetJustifyH("RIGHT");
          button.ReadyDate:SetTextColor(0.7, 0.7, 0.7);
        end
        button.ReadyDate:ClearAllPoints();
        button.ReadyDate:SetPoint("BOTTOMRIGHT", -6, 2);
        button.ReadyDate:SetPoint("LEFT", width - timerWidth - 6, 0);

        function button.Timer:Update()
          local parent = self:GetParent();
          local text, ready, rgb, readyDate, readyTime = CooldownToRemainingTime(parent.elementData);

          if (parent.elementData.hideCountdown) then
            if (ready) then
              self:SetText(text);
              self:SetTextColor(rgb.r, rgb.g, rgb.b);
            else
              self:SetText(readyTime);
              self:SetTextColor(0.7, 0.7, 0.7);
            end
            parent.ReadyDate:Hide();
          else
            self:SetText(text);
            self:SetTextColor(rgb.r, rgb.g, rgb.b);

            if (readyDate) then
              parent.ReadyDate:SetText(readyDate);
              parent.ReadyDate:Show();
            else
              parent.ReadyDate:Hide();
            end
          end
        end

        button.Timer:Update();
      end
      factory("Button", Initializer);
    else
      factory("Frame");
    end
  end);

  view:SetElementExtentCalculator(function(dataIndex, node)
    local elementData = node:GetData();

    if (elementData.cooldown) then
      return elementData.hideCountdown and 26 or 30;
    end

    if (elementData.group) then
      return 30;
    end

    return 0;
  end);

  ScrollUtil.InitScrollBoxListWithScrollBar(frame.ScrollBox, frame.ScrollBar, view);
  ScrollUtil.AddManagedScrollBarVisibilityBehavior(frame.ScrollBox, frame.ScrollBar);
end

function Module:UpdateCooldownsFrameList()
  local groupByEnum = UtilityHub.Enums.CooldownGroupBy;
  local groupBy = UtilityHub.Database.global.cooldownGroupBy or groupByEnum.CHARACTER;
  local dataProvider = CreateTreeDataProvider();

  -- Collect all cooldown entries across all characters
  local allEntries = {};

  for _, character in ipairs(UtilityHub.Database.global.characters) do
    for profName, cooldownGroup in pairs(character.cooldownGroup or {}) do
      for _, cooldown in ipairs(cooldownGroup) do
        local _, isReady = CooldownToRemainingTime(cooldown);
        local remaining = 0;

        if (cooldown.start and cooldown.maxCooldown and cooldown.maxCooldown > 0) then
          remaining = (cooldown.start + cooldown.maxCooldown) - GetTime();

          if (remaining < 0) then
            remaining = 0;
          end
        end

        tinsert(allEntries, {
          characterName = character.name,
          className = character.className,
          professionName = profName,
          cooldownName = cooldown.name,
          start = cooldown.start,
          maxCooldown = cooldown.maxCooldown,
          isReady = isReady,
          remaining = remaining,
        });
      end
    end
  end

  ---@param entry table
  ---@return string
  local function ColorCharName(entry)
    if (entry.className) then
      local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[entry.className];

      if (color and color.colorStr) then
        return "|c" .. color.colorStr .. entry.characterName .. "|r";
      end
    end

    return entry.characterName;
  end

  ---@param entry table
  ---@return string
  local function MakeEntryLabel(entry)
    if (groupBy == groupByEnum.CHARACTER) then
      return entry.cooldownName;
    elseif (groupBy == groupByEnum.TYPE) then
      return ColorCharName(entry);
    elseif (groupBy == groupByEnum.READY_DATE_PROFESSION) then
      return ColorCharName(entry) .. " " .. entry.cooldownName;
    end

    return ColorCharName(entry) .. " - " .. entry.cooldownName;
  end

  ---@param entry table
  ---@return table
  local function MakeEntryData(entry)
    return {
      cooldown = MakeEntryLabel(entry),
      start = entry.start,
      maxCooldown = entry.maxCooldown,
      hideCountdown = (groupBy == groupByEnum.READY_DATE or groupBy == groupByEnum.READY_DATE_PROFESSION),
    };
  end

  ---@param entries table[]
  ---@param key string
  ---@param groupData table
  ---@param groups table
  ---@param order string[]
  local function AddToGroup(entries, key, groupData, groups, order)
    if (not groups[key]) then
      groups[key] = groupData;
      groups[key].entries = {};
      groups[key].readyCount = 0;
      tinsert(order, key);
    end

    local g = groups[key];

    for _, entry in ipairs(entries) do
      if (entry.isReady) then
        g.readyCount = g.readyCount + 1;
      end

      tinsert(g.entries, entry);
    end
  end

  ---@param groups table
  ---@param order string[]
  local function InsertGroupsIntoProvider(groups, order)
    for _, key in ipairs(order) do
      local g = groups[key];

      if (#g.entries > 0) then
        local groupNode = dataProvider:Insert({
          group = g.label or key,
          className = g.className,
          readyCount = g.readyCount,
          totalCount = #g.entries,
          nearestEndTime = g.nearestEndTime,
        });

        for _, entry in ipairs(g.entries) do
          groupNode:Insert(MakeEntryData(entry));
        end
      end
    end
  end

  if (groupBy == groupByEnum.CHARACTER) then
    local groups = {};
    local order = {};

    for _, entry in ipairs(allEntries) do
      AddToGroup({ entry }, entry.characterName, { className = entry.className }, groups, order);
    end

    table.sort(order);
    InsertGroupsIntoProvider(groups, order);
  elseif (groupBy == groupByEnum.TYPE) then
    local groups = {};
    local order = {};

    for _, entry in ipairs(allEntries) do
      AddToGroup({ entry }, entry.cooldownName, {}, groups, order);
    end

    table.sort(order);
    InsertGroupsIntoProvider(groups, order);
  elseif (groupBy == groupByEnum.READY_DATE) then
    local groups = {};
    local order = {};

    for _, entry in ipairs(allEntries) do
      local dateKey, dateLabel;

      if (entry.isReady or entry.remaining <= 0) then
        dateKey = "0000-00-00";
        dateLabel = "Ready";
      else
        local readyTimestamp = time() + entry.remaining;
        dateKey = date("%Y-%m-%d", readyTimestamp);
        dateLabel = FormatDateGroupLabel(readyTimestamp);
      end

      AddToGroup({ entry }, dateKey, { label = dateLabel }, groups, order);

      if (not entry.isReady and entry.remaining > 0) then
        local endTime = entry.start + entry.maxCooldown;
        local g = groups[dateKey];

        if (not g.nearestEndTime or endTime < g.nearestEndTime) then
          g.nearestEndTime = endTime;
        end
      end
    end

    table.sort(order);

    for _, key in ipairs(order) do
      table.sort(groups[key].entries, function(a, b)
        return a.remaining < b.remaining;
      end);
    end

    InsertGroupsIntoProvider(groups, order);
  elseif (groupBy == groupByEnum.READY_DATE_PROFESSION) then
    local groups = {};
    local order = {};

    -- Time window: 2 hours in seconds
    local TIME_WINDOW = 2 * 60 * 60;

    -- First, group entries by profession
    local professionEntries = {};
    for _, entry in ipairs(allEntries) do
      local profession = entry.professionName;
      if (not professionEntries[profession]) then
        professionEntries[profession] = {};
      end
      tinsert(professionEntries[profession], entry);
    end

    -- For each profession, apply time window grouping
    local tempGroups = {};

    for profession, entries in pairs(professionEntries) do
      -- Separate ready and non-ready entries
      local readyEntries = {};
      local nonReadyEntries = {};

      for _, entry in ipairs(entries) do
        if (entry.isReady or entry.remaining <= 0) then
          tinsert(readyEntries, entry);
        else
          tinsert(nonReadyEntries, entry);
        end
      end

      -- Process ready entries
      if (#readyEntries > 0) then
        local dateKey = "0000-00-00|" .. profession;
        local dateLabel = "Ready - " .. profession;

        if (not tempGroups[dateKey]) then
          tempGroups[dateKey] = {
            label = dateLabel,
            characters = {},
            nearestEndTime = nil,
          };
          tinsert(order, dateKey);
        end

        for _, entry in ipairs(readyEntries) do
          local charName = entry.characterName;
          if (not tempGroups[dateKey].characters[charName]) then
            tempGroups[dateKey].characters[charName] = {
              className = entry.className,
              characterName = charName,
              count = 0,
              entries = {},
            };
          end
          tempGroups[dateKey].characters[charName].count = tempGroups[dateKey].characters[charName].count + 1;
          tinsert(tempGroups[dateKey].characters[charName].entries, entry);
        end
      end

      -- Process non-ready entries with time window
      if (#nonReadyEntries > 0) then
        -- Sort by ready timestamp
        table.sort(nonReadyEntries, function(a, b)
          local timeA = time() + a.remaining;
          local timeB = time() + b.remaining;
          return timeA < timeB;
        end);

        -- Group entries within time window
        local currentGroupTimestamp = nil;
        local currentDateKey = nil;
        local currentDateLabel = nil;

        for _, entry in ipairs(nonReadyEntries) do
          local readyTimestamp = time() + entry.remaining;

          -- Check if this entry is within time window of current group
          if (not currentGroupTimestamp or (readyTimestamp - currentGroupTimestamp) > TIME_WINDOW) then
            -- Start a new group
            currentGroupTimestamp = readyTimestamp;
            local formattedDate = date("%Y-%m-%d", readyTimestamp);
            currentDateKey = formattedDate .. "|" .. profession;
            currentDateLabel = FormatDateGroupLabel(readyTimestamp) .. " - " .. profession;

            if (not tempGroups[currentDateKey]) then
              tempGroups[currentDateKey] = {
                label = currentDateLabel,
                characters = {},
                nearestEndTime = nil,
              };
              tinsert(order, currentDateKey);
            end
          end

          -- Add entry to current group
          local charName = entry.characterName;

          if (not tempGroups[currentDateKey].characters[charName]) then
            tempGroups[currentDateKey].characters[charName] = {
              className = entry.className,
              characterName = charName,
              count = 0,
              entries = {},
            };
          end
          tempGroups[currentDateKey].characters[charName].count = tempGroups[currentDateKey].characters[charName].count +
              1;
          tinsert(tempGroups[currentDateKey].characters[charName].entries, entry);

          -- Update nearest end time
          local endTime = entry.start + entry.maxCooldown;
          if (not tempGroups[currentDateKey].nearestEndTime or endTime < tempGroups[currentDateKey].nearestEndTime) then
            tempGroups[currentDateKey].nearestEndTime = endTime;
          end
        end
      end
    end

    -- Now convert to final groups structure
    table.sort(order);

    for _, key in ipairs(order) do
      local tempGroup = tempGroups[key];
      groups[key] = {
        label = tempGroup.label,
        entries = {},
        readyCount = 0,
        nearestEndTime = tempGroup.nearestEndTime,
      };

      local charNames = {};
      for charName, _ in pairs(tempGroup.characters) do
        tinsert(charNames, charName);
      end
      table.sort(charNames);

      for _, charName in ipairs(charNames) do
        local charData = tempGroup.characters[charName];
        -- Use the first entry as representative for timing
        local firstEntry = charData.entries[1];

        tinsert(groups[key].entries, {
          characterName = charData.characterName,
          className = charData.className,
          cooldownName = "(" .. charData.count .. ")",
          start = firstEntry.start,
          maxCooldown = firstEntry.maxCooldown,
          isReady = firstEntry.isReady,
          remaining = firstEntry.remaining,
        });

        if (firstEntry.isReady) then
          groups[key].readyCount = groups[key].readyCount + 1;
        end
      end
    end

    InsertGroupsIntoProvider(groups, order);
  end

  -- Apply collapsed state to nodes before rendering
  for _, node in dataProvider:EnumerateEntireRange() do
    local elementData = node:GetData();

    if (elementData.group) then
      if (Module.AllCollapsedOverride) then
        Module.CollapsedGroups[elementData.group] = true;
        node:SetCollapsed(true);
      elseif (Module.CollapsedGroups[elementData.group]) then
        node:SetCollapsed(true);
      end
    end
  end

  Module.AllCollapsedOverride = nil;

  Module.Frame.ScrollBox:SetDataProvider(dataProvider);
end

function Module:ShowFrame()
  if (not Module:IsEnabled()) then
    UtilityHub.Helpers.Notification:ShowNotification(moduleName .. " module is not enabled");
    return;
  end

  if (Module.Frame) then
    -- Reset collapsed state based on user preference
    Module.CollapsedGroups = {};

    if (UtilityHub.Database.global.options.cooldownStartCollapsed) then
      Module.AllCollapsedOverride = true;
    end

    Module.Frame:Show();
    Module:UpdateCooldownsFrameList();

    -- Update button text
    local startCollapsed = UtilityHub.Database.global.options.cooldownStartCollapsed;
    Module.Frame.CollapseButton:SetText(startCollapsed and "Expand" or "Collapse");
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

function Module:TestNotification()
  Module.NotifiedCooldowns = {};
  Module.CountReadyGraceTicks = 0;
  Module:UpdateCountReadyCooldowns();
  UtilityHub.Helpers.Notification:ShowNotification("Triggered cooldown notification test");
end

-- Events
local function skillUpdated(...)
  if (UtilityHub.Flags.addonReady and GetNumSkillLines() > 0) then
    UtilityHub.Events:TriggerEvent("CHARACTER_UPDATE_NEEDED");
  end
end

EventRegistry:RegisterFrameEventAndCallback("SKILL_LINES_CHANGED", skillUpdated);
EventRegistry:RegisterFrameEventAndCallback("TRADE_SKILL_LIST_UPDATE", skillUpdated);
EventRegistry:RegisterFrameEventAndCallback("TRADE_SKILL_UPDATE", skillUpdated);

EventRegistry:RegisterFrameEventAndCallback("LOADING_SCREEN_DISABLED", function()
  Module.NotifiedCooldowns = {};
  Module.CountReadyGraceTicks = 5;
end);

UtilityHub.Events:RegisterCallback("CHARACTER_UPDATED", function(_, name)
  Module:UpdateCooldownsFrameList();
end);

UtilityHub.Events:RegisterCallback("OPEN_COOLDOWNS_FRAME", function(_, name)
  Module:ShowFrame();
end);

UtilityHub.Events:RegisterCallback("HIDE_COOLDOWNS_FRAME", function(_, name)
  Module:HideFrame();
end);

UtilityHub.Events:RegisterCallback("TOGGLE_COOLDOWNS_FRAME", function(_, name)
  Module:ToggleFrame();
end);
