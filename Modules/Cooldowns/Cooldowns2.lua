---@class CooldownRow
---@field group string
---@field row string
---@field isReady boolean
---@field endTime number
---@field color BasicRGB
---@class CooldownHeader
---@field groupName string
---@field readyCount number
---@field cooldowns CooldownRow[]
---@field color BasicRGB
---@class PreProcessedRow
---@field characterName string
---@field className string
---@field professionID number
---@field professionName string
---@field cooldownName string
---@field isReady boolean
---@field endTime number
---@field isHidden boolean
---@class CooldownHeaderNode
---@field groupName string
---@field readyCount number
---@field totalCount number
---@field color BasicRGB
---@class CooldownRowNode
---@field group string
---@field rowName string
---@field endTime number
---@field isReady boolean
---@field color BasicRGB
local moduleName = 'Cooldowns';
---@class Cooldowns
local Module = UtilityHub.Addon:NewModule(moduleName);
Module.frame = nil;

Module.CollapsedGroups = {};

---@param cooldown ProfessionCooldownData
---@return boolean
local function IsCooldownReady(cooldown)
  return cooldown.endTime < GetServerTime();
end

---@param professionID number
---@return Profession|nil
local function GetProfessionByID(professionID)
  ---@type Profession[]
  local professions = UtilityHub.Constants.Cooldowns;

  for _, profession in ipairs(professions) do
    if (profession.id == professionID) then
      return profession;
    end
  end

  return nil;
end

---@param internalID number
---@return boolean
local function IsCooldownHidden(internalID)
  ---@type CooldownConfig[]
  local baseData = UtilityHub.Database.global.options.cooldownConfigs;

  for _, cooldownConfig in ipairs(baseData) do
    if (cooldownConfig.internalID == internalID) then
      return not cooldownConfig.enabled;
    end
  end

  return false;
end

---@param str string
---@param numChars number
---@return string
local function Utf8Sub(str, numChars)
  local bytePos = 1;
  local strLen = #str;

  for i = 1, numChars do
    if (bytePos > strLen) then
      break
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

---@param readyTimestamp number
---@return string
local function FormatReadyTime(readyTimestamp)
  local t = date("*t", readyTimestamp);
  return string.format("%02d:%02d", t.hour, t.min);
end

---@param readyTimestamp number
---@return string
local function FormatReadyDate(readyTimestamp)
  local t = date("*t", readyTimestamp);

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

---@param remaining number
---@return string
local function FormatRemainingTimestamp(remaining)
  local days = math.floor(remaining / (24 * 60 * 60));
  local hours = math.floor((remaining % (24 * 60 * 60)) / (60 * 60));
  local minutes = math.floor((remaining % (60 * 60)) / 60);
  local seconds = math.floor(remaining % 60);
  local resultStr;

  if (days > 0) then
    resultStr = string.format("%d %s %02d:%02d:%02d", days, days == 1 and "day" or "days", hours, minutes, seconds);
  else
    resultStr = string.format("%02d:%02d:%02d", hours, minutes, seconds);
  end

  return resultStr;
end

---@param nodeRow CooldownRowNode
---@return string "Converted time"
---@return boolean "If its ready"
---@return table "RGB"
---@return string|nil "Ready date"
---@return string|nil "Ready time (HH:MM)"
local function CooldownToRemainingTime(nodeRow)
  if (not nodeRow.isReady) then
    local finish = nodeRow.endTime;
    local remaining = finish - GetServerTime();

    if (remaining > 0) then
      local r = 0;
      local g = 0;
      local b = 0;

      if (remaining > 60 * 60) then
        r = 191;
        g = 13;
        b = 13;
      else
        r = 212;
        g = 22;
        b = 16;
      end

      local rgb = UtilityHub.Helpers.Color:NormalizeRGB({
        r = r,
        g = g,
        b = b
      });
      local readyDate = FormatReadyDate(finish);
      local readyTime = FormatReadyTime(finish);
      local resultStr = FormatRemainingTimestamp(remaining);

      return resultStr, false, rgb, readyDate, readyTime;
    end
  end

  return "Ready", true, UtilityHub.Helpers.Color:NormalizeRGB({
    r = 16,
    g = 179,
    b = 16
  }), nil, nil;
end

function Module:CreateCooldownsFrame()
  local MIN_WIDTH = 320;
  local MIN_HEIGHT = 200;
  local DEFAULT_WIDTH = 400;
  local DEFAULT_HEIGHT = 450;

  local frame = CreateFrame("Frame", "UHCooldowns", UIParent, "SettingsFrameTemplate");
  Module.Frame = frame;
  tinsert(UISpecialFrames, frame:GetName());
  frame:SetResizable(true);
  frame:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT);
  frame:Hide();

  do -- Size/positioning
    local savedSize = UtilityHub.Database.global.cooldownFrameSize;
    local savedPosition = UtilityHub.Database.global.cooldownFramePosition;

    if (savedSize) then
      frame:SetSize(savedSize.width, savedSize.height);
    else
      frame:SetSize(DEFAULT_WIDTH, DEFAULT_HEIGHT);
    end

    if (UtilityHub.Database.global.cooldownFramePosition) then
      frame:SetPoint(savedPosition.point, frame:GetParent(), savedPosition.relativePoint, savedPosition.x,
        savedPosition.y);
    else
      frame:SetPoint("CENTER");
    end

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
      UtilityHub.Database.global.cooldownFrameSize = {
        width = math.floor(w),
        height = math.floor(h)
      };
      Module:UpdateCooldownsFrameList();
    end);
  end

  frame.NineSlice.Text:SetText("Cooldowns");

  local content = CreateFrame("Frame", nil, frame);
  frame.Content = content;
  content:SetWidth(frame:GetSize());
  content:SetPoint("TOPLEFT", 15, -37);
  content:SetPoint("BOTTOMRIGHT", -5, 7);

  do -- Top actions
    local dropdown = CreateFrame("Frame", "UHCooldownGroupByDropdown", content, "UIDropDownMenuTemplate");
    frame.GroupByDropdown = dropdown;
    dropdown:SetPoint("TOPLEFT", content, "TOPLEFT", -15, 2);
    UIDropDownMenu_SetWidth(dropdown, 140);

    local currentGroupBy = UtilityHub.Database.global.cooldownGroupBy or UtilityHub.Enums.CooldownGroupBy.CHARACTER;
    UIDropDownMenu_SetText(dropdown, UtilityHub.Enums.CooldownGroupByText[currentGroupBy]);

    UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
      local current = UtilityHub.Database.global.cooldownGroupBy or UtilityHub.Enums.CooldownGroupBy.CHARACTER;
      local options = {
        UtilityHub.Enums.CooldownGroupBy.CHARACTER,
        UtilityHub.Enums.CooldownGroupBy.TYPE
      };

      for _, value in ipairs(options) do
        local info = UIDropDownMenu_CreateInfo();
        info.text = UtilityHub.Enums.CooldownGroupByText[value];
        info.value = value;
        info.checked = (current == value);
        info.func = function(btn)
          UtilityHub.Database.global.cooldownGroupBy = btn.value;
          UIDropDownMenu_SetText(dropdown, UtilityHub.Enums.CooldownGroupByText[btn.value]);
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
            break
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
  end

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
    ---@type CooldownRowNode|CooldownHeaderNode
    local elementData = node:GetData();

    if (elementData.groupName) then
      local function Initializer(button, node)
        if (Module.CollapsedGroups[elementData.groupName] == nil) then
          Module.CollapsedGroups[elementData.groupName] = node:IsCollapsed();
        end

        button.Label:SetText(elementData.groupName);
        button.Label:SetTextColor(elementData.color.r, elementData.color.g, elementData.color.b);

        local readySuffix = elementData.readyCount .. "/" .. elementData.totalCount .. " ready";
        button.LabelRight:SetText(readySuffix);
        button:SetCollapseState(Module.CollapsedGroups[elementData.groupName]);

        button:SetScript("OnClick", function(button)
          node:ToggleCollapsed();
          Module.CollapsedGroups[elementData.groupName] = node:IsCollapsed();
          button:SetCollapseState(node:IsCollapsed());
          PlaySound(SOUNDKIT.IG_MAINMENU_OPTION);
        end);
      end

      factory("TreeGroupButtonTemplate", Initializer);
    elseif (elementData.rowName) then
      local function Initializer(button, node)
        local width = button:GetWidth();
        local timerWidth = 130;

        button:SetPushedTextOffset(0, 0);
        button:SetHighlightAtlas("search-highlight");
        button:SetNormalFontObject(GameFontHighlight);
        button:SetText(elementData.rowName);
        button.elementData = elementData;
        button:GetFontString():SetTextColor(elementData.color.r, elementData.color.g, elementData.color.b);
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
        button.Timer:SetPoint("TOPRIGHT", -6, -10);
        button.Timer:SetPoint("LEFT", width - timerWidth - 6, 0);

        if (not button.ReadyDate) then
          button.ReadyDate = button:CreateFontString(nil, "OVERLAY");
          local font, size, flags = GameFontNormal:GetFont();
          button.ReadyDate:SetFont(font, size - 2, flags);
          button.ReadyDate:SetJustifyH("RIGHT");
          button.ReadyDate:SetTextColor(0.7, 0.7, 0.7);
        end
        button.ReadyDate:ClearAllPoints();
        button.ReadyDate:SetPoint("BOTTOMRIGHT", -6, 0);
        button.ReadyDate:SetPoint("LEFT", width - timerWidth - 6, 10);

        function button.Timer:Update()
          local parent = self:GetParent();
          local text, ready, rgb, readyDate, readyTime = CooldownToRemainingTime(parent.elementData);

          self:SetText(text);
          self:SetTextColor(rgb.r, rgb.g, rgb.b);
        end

        button.Timer:Update();
      end
      factory("Button", Initializer);
    else
      factory("Frame");
    end
  end);

  view:SetElementExtentCalculator(function(dataIndex, node)
    ---@type CooldownRowNode|CooldownHeaderNode
    local elementData = node:GetData();

    if (elementData.rowName) then
      return 30;
    end

    if (elementData.groupName) then
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
  ---@type LinearizedTreeDataProviderMixin
  local dataProvider = Module.Frame.ScrollBox:GetDataProvider();
  Module.Frame.ScrollBox:RemoveDataProvider();
  Module.AllCollapsedOverride = nil;

  if (dataProvider) then
    dataProvider:Flush();
  else
    ---@type LinearizedTreeDataProviderMixin
    dataProvider = CreateTreeDataProvider();
    Module.Frame.ScrollBox:SetDataProvider(dataProvider);
  end

  ---@type PreProcessedRow[]
  local preProcessedCooldowns = {};

  do -- Pre process data
    local characters = UtilityHub.Database.global.characters;

    --- Create a flat list with all data that can be grouped after
    for _, character in ipairs(characters) do
      for professionID, cooldownList in pairs(character.professionsData) do
        for _, cooldown in ipairs(cooldownList) do
          local isReady = IsCooldownReady(cooldown);
          local isHidden = IsCooldownHidden(cooldown.internalID);
          local profession = GetProfessionByID(professionID);

          tinsert(preProcessedCooldowns, {
            characterName = character.name,
            className = character.className,
            professionID = professionID,
            professionName = profession.name,
            cooldownName = cooldown.name,
            isReady = isReady,
            isHidden = isHidden,
            endTime = cooldown.endTime
          });
        end
      end
    end
  end

  ---@type CooldownHeader[]
  local processedGroups = {};

  do -- Process groups/rows
    local groupKey;
    local rowKey;
    local defaultColor = {
      r = 1,
      g = 1,
      b = 1
    };

    if (groupBy == groupByEnum.CHARACTER) then
      groupKey = "characterName";
      rowKey = "cooldownName";
    else
      groupKey = "cooldownName";
      rowKey = "characterName";
    end

    for _, preProcessedCooldown in ipairs(preProcessedCooldowns) do
      ---@type CooldownHeader|nil
      local currentProcessedGroup = nil;
      local groupName = preProcessedCooldown[groupKey];
      local rowName = preProcessedCooldown[rowKey];
      local isReady = preProcessedCooldown.isReady;
      local isHidden = preProcessedCooldown.isHidden;
      local classColor = UtilityHub.Helpers.Color:GetRGBFromClassName(preProcessedCooldown.className);
      local rowColor = defaultColor;

      if (not isHidden) then
        if (groupBy == groupByEnum.TYPE) then
          rowColor = classColor;
        end

        do -- Find or create the group
          for _, proccessedRow in ipairs(processedGroups) do
            if (proccessedRow.groupName == groupName) then
              currentProcessedGroup = proccessedRow;
              break
            end
          end

          if (currentProcessedGroup == nil) then
            local groupColor = defaultColor;

            if (groupBy == groupByEnum.CHARACTER) then
              groupColor = classColor;
            end

            currentProcessedGroup = {
              groupName = groupName,
              cooldowns = {},
              readyCount = 0,
              color = groupColor
            };
            tinsert(processedGroups, currentProcessedGroup);
          end
        end

        tinsert(currentProcessedGroup.cooldowns, {
          group = groupName,
          row = rowName,
          endTime = preProcessedCooldown.endTime,
          isReady = isReady,
          color = rowColor
        });

        if (isReady) then
          currentProcessedGroup.readyCount = currentProcessedGroup.readyCount + 1;
        end
      end
    end
  end

  do -- Sorting
    table.sort(processedGroups, function(a, b)
      return a.groupName < b.groupName;
    end);

    for _, proccessedRow in ipairs(processedGroups) do
      table.sort(proccessedRow.cooldowns, function(a, b)
        return a.row < b.row;
      end);
    end
  end

  do -- Update dataProvider
    for _, processedGroup in ipairs(processedGroups) do
      ---@type CooldownHeaderNode
      local headerNode = {
        groupName = processedGroup.groupName,
        totalCount = #processedGroup.cooldowns,
        readyCount = processedGroup.readyCount,
        color = processedGroup.color
      };

      local groupNode = dataProvider:Insert(headerNode);

      for _, cooldownRow in ipairs(processedGroup.cooldowns) do
        ---@type CooldownRowNode
        local rowNode = {
          group = processedGroup.groupName,
          rowName = cooldownRow.row,
          endTime = cooldownRow.endTime,
          isReady = cooldownRow.isReady,
          color = cooldownRow.color
        };

        groupNode:Insert(rowNode);
      end
    end
  end

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

function Module:OnInitialize()
  if (not Module.Frame) then
    Module:CreateCooldownsFrame();
  end
end

Module.Ticker = C_Timer.NewTicker(1, function()
  -- Only update if its visible
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

UtilityHub.Events:RegisterCallback("COOLDOWNS_UPDATED", function(_, name)
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
