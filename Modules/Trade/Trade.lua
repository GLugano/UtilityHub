local moduleName = 'Trade';
local module = UtilityHub.Addon:NewModule(moduleName);

---@param spells number[]
---@param items number[]
---@return number|nil
---@return number|nil
local function GetItemIDBy(spells, items)
  for index, spellID in ipairs(spells) do
    ---@diagnostic disable-next-line: deprecated
    if (IsSpellKnown(spellID, false)) then
      return items[index], spellID;
    end
  end

  return nil, nil;
end

local function CreateModule()
  local frameWidth = 200;

  ---@param frame table
  ---@param text string|nil
  ---@param fontSize number|nil
  ---@return table
  local function CreateLabel(frame, text, fontSize)
    local label = UtilityHub.Libs.Utils.AceGUI:Create("Label");
    local fontPath, _, fontFlags = label.label:GetFont();
    label.label:SetFont(fontPath, fontSize or 16, fontFlags);
    label:SetText(text or "");
    label.label:SetWordWrap(true);
    label:SetFullWidth(true);
    frame:AddChild(label);

    return label;
  end

  local function CreateTradeFrame()
    local frame = UtilityHub.Libs.Utils.AceGUI:Create("Frame", TradeFrame);

    frame:Hide();
    frame:SetTitle("Trading with...");
    frame:SetLayout("Flow");
    frame:SetWidth(frameWidth);
    frame:SetHeight(330);
    frame:EnableResize(false);
    frame:ClearAllPoints();
    frame:SetPoint("TOPRIGHT", TradeFrame, "TOPRIGHT", 10 + frameWidth, 0);

    frame.NameLabel = CreateLabel(frame);
    frame.ServerLabel = CreateLabel(frame);
    frame.GuildLabel = CreateLabel(frame);
    frame.LevelLabel = CreateLabel(frame);
    frame.RaceClassLabel = CreateLabel(frame);

    local spacer = CreateLabel(frame);
    spacer:SetText(" ");
    spacer:SetHeight(10);

    local scrollFrameParent = UtilityHub.Libs.Utils.AceGUI:Create("InlineGroup");
    scrollFrameParent:SetTitle("Last whisper:");
    scrollFrameParent:SetFullWidth(true);
    scrollFrameParent:SetFullHeight(true);
    frame:AddChild(scrollFrameParent);

    local scroll = UtilityHub.Libs.Utils.AceGUI:Create("ScrollFrame");
    scroll:SetFullWidth(true);
    scroll:SetLayout("Flow");
    scrollFrameParent:AddChild(scroll);
    frame.LastWhisperScrollableRef = scroll;

    local label = CreateLabel(scroll, "-", 14);
    label:SetWidth(frameWidth - 60);
    label:SetFullHeight(true);

    function frame:GetNameAndServer()
      local name, server = UnitFullName("npc");
      server = server or GetRealmName();

      if (not server) then
        server = "-";
      end

      if (not name) then
        name = "-";
      end

      return name, server;
    end

    function frame:UpdateWhisper()
      local name, server = frame:GetNameAndServer();
      label:SetText(UtilityHub.Database.global.whispers[name .. "-" .. server] or "-");
    end

    function frame:Update()
      local name, server = frame:GetNameAndServer();
      local _, englishClass = UnitClass("npc");
      local level = UnitLevel("npc") or "-";
      local race = UnitRace("npc") or "-";
      local class = UnitClass("npc") or "-";
      local guild = GetGuildInfo("npc") or "-";
      local raceClass = "-";

      if (name) then
        raceClass = race .. " " .. UtilityHub.Libs.Utils:GetClassColoredText(class);
      else
        name = "-";
        server = "-";
        englishClass = "-";
      end

      frame.NameLabel:SetText(name);
      frame.ServerLabel:SetText("|cffffd100Server:|r " .. server);
      frame.GuildLabel:SetText("|cffffd100Guild:|r " .. guild);
      frame.LevelLabel:SetText("|cffffd100Level:|r " .. level);
      frame.RaceClassLabel:SetText(raceClass, englishClass);
    end

    return frame;
  end

  ---@param name string
  ---@param parent table|nil
  ---@return table|Button|UHTradeItemButtonTemplate
  local function CreateItemButton(name, parent)
    local button = CreateFrame("Button", name, TradeFrame, "UHTradeItemButtonTemplate");
    button:RegisterForClicks("AnyUp");
    button:RegisterForClicks("AnyDown");
    button:SetSize(36, 36);
    button:SetAttribute("IsEquipmentset", false);
    button:SetAttribute("IsMount", false);
    button:SetAttribute("shift-type1", "spell");

    if (parent) then
      button:SetPoint("TOPLEFT", parent, "TOPRIGHT", 10, 0);
    else
      button:SetPoint("BOTTOMLEFT", TradeFrame, "BOTTOMRIGHT", 10, 3);
    end

    function button:UpdateItem(itemID, spellID)
      button:SetAttribute("shift-spell1", spellID);
      button:SetAttribute("itemID", itemID);
      button:SetAttribute("spellID", spellID);
      self:UpdateState();
    end

    button:HookScript('OnClick', function()
      if (not IsShiftKeyDown()) then
        button:OnClickNotShift();
      end
    end);

    return button;
  end

  local frame = CreateTradeFrame();
  ---@class MageButtons
  local buttons = {};

  buttons.water = CreateItemButton("UHTradeWaterButton");
  buttons.food = CreateItemButton("UHTradeFoodButton", buttons.water);

  return {
    frame = frame,
    Hide = function()
      frame:Hide();
    end,
    Show = function()
      frame:Update();
      frame:Show();
    end,
    UpdateParent = function()
      frame:ClearAllPoints();
      frame:SetPoint(
        "TOPRIGHT",
        CharacterFrame:IsShown() and CharacterFrame or TradeFrame,
        "TOPRIGHT",
        10 + frameWidth,
        0
      );
    end,
    UpdateLastWhisperInFrame = function()
      frame:UpdateWhisper();
    end,
    UpdateItemFromButtons = function()
      -- All lists are ordered by rank, descending sort
      local waterSpellIDs = { 10140, 10139, 10138, 6127, 5506, 5505, 5504 };
      local foodSpellIDs = { 28612, 10145, 10144, 6129, 990, 597, 587 };
      local waterItemIDs = { 8079, 8078, 8077, 3772, 2136, 2288, 5350 };
      local foodItemIDs = { 22895, 8076, 8075, 1487, 1114, 1113, 5349 };

      ---@param type "Water" | "Food"
      ---@param spellIDs number[]
      ---@param itemIDs number[]
      function UpdateItem(type, spellIDs, itemIDs)
        if (not buttons[type]) then
          return;
        end

        local itemID, spellID = GetItemIDBy(spellIDs, itemIDs);

        if (not itemID or not spellID) then
          return;
        end

        buttons[type]:UpdateItem(itemID, spellID);
      end

      UpdateItem("Water", waterSpellIDs, waterItemIDs);
      UpdateItem("Food", foodSpellIDs, foodItemIDs);
    end,
  };
end

local moduleData = CreateModule();

-- Lifecycle
function module:OnDisable()
  moduleData.Hide();
end

--- Events
UtilityHub.Events:RegisterCallback("WHISPER_LIST_UPDATED", function(_, name, message)
  moduleData.UpdateLastWhisperInFrame();
end);

EventRegistry:RegisterFrameEventAndCallback("TRADE_CLOSED", function()
  moduleData.Hide();
end);

EventRegistry:RegisterFrameEventAndCallback("TRADE_SHOW", function()
  if (module:IsEnabled()) then
    moduleData.Show();
  end
end);

hooksecurefunc(CharacterFrame, "Show", function()
  moduleData.UpdateParent();
end);

hooksecurefunc(CharacterFrame, "Hide", function()
  moduleData.UpdateParent();
end);
