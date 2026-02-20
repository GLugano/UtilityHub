local ADDON_NAME = ...;

---@class MouseRingPage
local MouseRingPage = {};

local SHAPE_OPTIONS = {
  { file = "ring.tga",       label = "Ring"       },
  { file = "ring2.tga",      label = "Ring 2"     },
  { file = "thick_ring.tga", label = "Thick Ring" },
  { file = "thin_ring.tga",  label = "Thin Ring"  },
};

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

---@return table
local function GetDB()
  return UtilityHub.Database.global.options.mouseRing;
end

---@param parent Frame
---@param labelText string
---@param dbKey string
---@param tooltip? string
---@param anchor Frame
---@return CheckButton
local function CreateCheckbox(parent, labelText, dbKey, tooltip, anchor)
  local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate");
  checkbox:SetSize(24, 24);
  checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8);

  local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0);
  label:SetText(labelText);

  checkbox:SetChecked(GetDB()[dbKey]);
  checkbox.UpdateFromDB = function() checkbox:SetChecked(GetDB()[dbKey]) end;
  checkbox:SetScript("OnClick", function(self)
    GetDB()[dbKey] = self:GetChecked();
    UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "mouseRing");
  end);

  if (tooltip) then
    checkbox:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:SetText(labelText, 1, 1, 1);
      GameTooltip:AddLine(tooltip, nil, nil, nil, true);
      GameTooltip:Show();
    end);
    checkbox:SetScript("OnLeave", function(self)
      if (GameTooltip:IsOwned(self)) then GameTooltip:Hide() end
    end);
  end

  return checkbox;
end

---@param parent Frame
---@param labelText string
---@param anchor Frame
---@return FontString
local function CreateSectionHeader(parent, labelText, anchor)
  local header = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  header:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -18);
  header:SetText(labelText);
  return header;
end

---@param parent Frame
---@param labelText string
---@param dbKeyR string
---@param dbKeyG string
---@param dbKeyB string
---@param anchor Frame
---@return Frame
local function CreateColorRow(parent, labelText, dbKeyR, dbKeyG, dbKeyB, anchor)
  local framesHelper = UtilityHub.GameOptions.framesHelper;

  local colorPicker = framesHelper:CreateCustomColorPicker(
    parent,
    labelText,
    function(r, g, b)
      local db = GetDB();
      db[dbKeyR], db[dbKeyG], db[dbKeyB] = r, g, b;
      UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "mouseRing");
    end
  );

  colorPicker:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10);

  local db = GetDB();
  colorPicker:SetColor(db[dbKeyR] or 1, db[dbKeyG] or 1, db[dbKeyB] or 1);
  colorPicker.UpdateFromDB = function()
    local d = GetDB();
    colorPicker:SetColor(d[dbKeyR] or 1, d[dbKeyG] or 1, d[dbKeyB] or 1);
  end;

  return colorPicker;
end

---@param parent Frame
---@param labelText string
---@param dbKey string
---@param minVal number
---@param maxVal number
---@param step number
---@param anchor Frame
---@return Frame
local function CreateSliderRow(parent, labelText, dbKey, minVal, maxVal, step, anchor)
  local container = CreateFrame("Frame", nil, parent);
  container:SetSize(340, 40);
  container:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8);

  local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  label:SetPoint("TOPLEFT", 0, 0);
  label:SetText(labelText);

  local sliderName = "UHMouseRingSlider_" .. dbKey;
  local slider = CreateFrame("Slider", sliderName, container, "OptionsSliderTemplate");
  slider:SetWidth(180);
  slider:SetMinMaxValues(minVal, maxVal);
  slider:SetValueStep(step);
  slider:SetObeyStepOnDrag(true);
  slider:SetPoint("LEFT", label, "RIGHT", 10, -8);

  local low = _G[sliderName .. "Low"];
  local high = _G[sliderName .. "High"];
  local text = _G[sliderName .. "Text"];

  if (low) then low:SetText(tostring(minVal)) end
  if (high) then high:SetText(tostring(maxVal)) end

  local db = GetDB();
  local currentVal = db[dbKey] or minVal;
  slider:SetValue(currentVal);
  if (text) then text:SetText(tostring(currentVal)) end

  slider:SetScript("OnValueChanged", function(self, value)
    local rounded = math.floor(value / step + 0.5) * step;
    GetDB()[dbKey] = rounded;
    if (text) then text:SetText(tostring(rounded)) end
    UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "mouseRing");
  end);

  container.UpdateFromDB = function()
    local val = GetDB()[dbKey] or minVal;
    slider:SetValue(val);
    if (text) then text:SetText(tostring(val)) end
  end;

  return container;
end

---@param parent Frame
---@param anchor Frame
---@return Frame
local function CreateShapeSelector(parent, anchor)
  local container = CreateFrame("Frame", nil, parent);
  container:SetSize(280, 26);
  container:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10);

  local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  label:SetPoint("LEFT", 0, 0);
  label:SetText("Shape:");

  local function GetCurrentIndex()
    local current = GetDB().shape or "ring.tga";
    for i, s in ipairs(SHAPE_OPTIONS) do
      if (s.file == current) then return i end
    end
    return 1;
  end

  local valueLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  valueLabel:SetPoint("LEFT", label, "RIGHT", 8, 0);
  valueLabel:SetText(SHAPE_OPTIONS[GetCurrentIndex()].label);

  local btnPrev = CreateFrame("Button", nil, container, "UIPanelButtonTemplate");
  btnPrev:SetSize(24, 22);
  btnPrev:SetText("<");
  btnPrev:SetPoint("RIGHT", valueLabel, "LEFT", -6, 0);

  local btnNext = CreateFrame("Button", nil, container, "UIPanelButtonTemplate");
  btnNext:SetSize(24, 22);
  btnNext:SetText(">");
  btnNext:SetPoint("LEFT", valueLabel, "RIGHT", 6, 0);

  btnNext:SetScript("OnClick", function()
    local idx = (GetCurrentIndex() % #SHAPE_OPTIONS) + 1;
    GetDB().shape = SHAPE_OPTIONS[idx].file;
    valueLabel:SetText(SHAPE_OPTIONS[idx].label);
    UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "mouseRing");
  end);

  btnPrev:SetScript("OnClick", function()
    local idx = ((GetCurrentIndex() - 2) % #SHAPE_OPTIONS) + 1;
    GetDB().shape = SHAPE_OPTIONS[idx].file;
    valueLabel:SetText(SHAPE_OPTIONS[idx].label);
    UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "mouseRing");
  end);

  container.UpdateFromDB = function()
    valueLabel:SetText(SHAPE_OPTIONS[GetCurrentIndex()].label);
  end;

  return container;
end

--------------------------------------------------------------------------------
-- Page creation
--------------------------------------------------------------------------------

---@param parent Frame
---@return Frame
function MouseRingPage:Create(parent)
  -- Outer frame fills the content area
  local outerFrame = CreateFrame("Frame", "UtilityHubMouseRingPage", parent);

  -- Scroll frame
  local scrollFrame = CreateFrame("ScrollFrame", nil, outerFrame, "UIPanelScrollFrameTemplate");
  scrollFrame:SetPoint("TOPLEFT", outerFrame, "TOPLEFT", 0, 0);
  scrollFrame:SetPoint("BOTTOMRIGHT", outerFrame, "BOTTOMRIGHT", -22, 0);

  -- Scroll child (content lives here)
  local content = CreateFrame("Frame", nil, scrollFrame);
  content:SetHeight(900);
  scrollFrame:SetScrollChild(content);

  -- Keep content width in sync
  scrollFrame:SetScript("OnSizeChanged", function(self, w)
    content:SetWidth(w);
  end);
  scrollFrame:HookScript("OnShow", function(self)
    content:SetWidth(self:GetWidth());
  end);

  -- Title
  local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
  title:SetPoint("TOPLEFT", 20, -20);
  title:SetText("Mouse Ring");

  -- Restore Defaults button (anchored top-right; OnClick set at end of function)
  local refreshFn;
  local btnRestore = CreateFrame("Button", nil, content, "UIPanelButtonTemplate");
  btnRestore:SetSize(130, 24);
  btnRestore:SetPoint("TOPRIGHT", content, "TOPRIGHT", -20, -18);
  btnRestore:SetText("Restore Defaults");
  btnRestore:SetScript("OnClick", function()
    local defaults = UtilityHub.GameOptions.defaults.mouseRing;
    local db = GetDB();
    for k, v in pairs(defaults) do db[k] = v end;
    if (refreshFn) then refreshFn() end;
    UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "mouseRing");
  end);

  -- Enable
  local cbEnable = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate");
  cbEnable:SetSize(24, 24);
  cbEnable:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10);
  local lblEnable = cbEnable:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  lblEnable:SetPoint("LEFT", cbEnable, "RIGHT", 5, 0);
  lblEnable:SetText("Enable mouse ring");
  cbEnable:SetChecked(GetDB().enabled);
  cbEnable:SetScript("OnClick", function(self)
    GetDB().enabled = self:GetChecked();
    UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "mouseRing");
  end);
  cbEnable:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText("Enable Mouse Ring", 1, 1, 1);
    GameTooltip:AddLine("Show a decorative ring that follows your mouse cursor.", nil, nil, nil, true);
    GameTooltip:Show();
  end);
  cbEnable:SetScript("OnLeave", function(self)
    if (GameTooltip:IsOwned(self)) then GameTooltip:Hide() end
  end);

  -- ── Ring ─────────────────────────────────────────────────────────────────

  local secRing = CreateSectionHeader(content, "Ring", cbEnable);

  local shapeSelector = CreateShapeSelector(content, secRing);

  local sizeSlider = CreateSliderRow(content, "Size:", "size", 24, 96, 2, shapeSelector);

  local cbClassColor = CreateCheckbox(
    content, "Use class color", "useClassColor",
    "Tint the ring with your class color", sizeSlider
  );

  local ringColor = CreateColorRow(
    content, "Ring color:", "colorR", "colorG", "colorB", cbClassColor
  );

  local cbHideBg = CreateCheckbox(
    content, "Hide background ring", "hideBackground",
    "Only show overlays, not the base ring texture", ringColor
  );

  local cbOutOfCombat = CreateCheckbox(
    content, "Show out of combat", "showOutOfCombat",
    "Keep the ring visible when not in combat", cbHideBg
  );

  local cbHideOnClick = CreateCheckbox(
    content, "Hide while right mouse held", "hideOnRightClick",
    "Hide the ring while holding right mouse button (camera rotation)", cbOutOfCombat
  );

  -- ── GCD Swipe ─────────────────────────────────────────────────────────────

  local secGcd = CreateSectionHeader(content, "GCD Swipe", cbHideOnClick);

  local cbGcd = CreateCheckbox(
    content, "Enable GCD swipe", "gcdEnabled",
    "Show a fill animation after casting any spell (tracks the 1.5s GCD)", secGcd
  );

  local cbGcdClassColor = CreateCheckbox(
    content, "Use class color for GCD", "gcdUseClassColor", nil, cbGcd
  );

  local gcdColor = CreateColorRow(
    content, "GCD color:", "gcdR", "gcdG", "gcdB", cbGcdClassColor
  );

  -- ── Cast / Channel Swipe ─────────────────────────────────────────────────

  local secCast = CreateSectionHeader(content, "Cast / Channel Swipe", gcdColor);

  local cbCastSwipe = CreateCheckbox(
    content, "Enable cast/channel swipe", "castSwipeEnabled",
    "Show a fill animation on the ring while casting or channeling", secCast
  );

  local cbCastClassColor = CreateCheckbox(
    content, "Use class color for swipe", "castSwipeUseClassColor", nil, cbCastSwipe
  );

  local castColor = CreateColorRow(
    content, "Swipe color:", "castSwipeR", "castSwipeG", "castSwipeB", cbCastClassColor
  );

  -- ── Trail ────────────────────────────────────────────────────────────────

  local secTrail = CreateSectionHeader(content, "Mouse Trail", castColor);

  local cbTrail = CreateCheckbox(
    content, "Enable mouse trail", "trailEnabled",
    "Show a glowing particle trail following the mouse cursor", secTrail
  );

  local cbTrailClassColor = CreateCheckbox(
    content, "Use class color for trail", "trailUseClassColor", nil, cbTrail
  );

  local trailColor = CreateColorRow(
    content, "Trail color:", "trailR", "trailG", "trailB", cbTrailClassColor
  );

  local trailDurationSlider = CreateSliderRow(content, "Trail duration (s):", "trailDuration", 0.1, 2.0, 0.1, trailColor);

  refreshFn = function()
    local db = GetDB();
    cbEnable:SetChecked(db.enabled);
    shapeSelector:UpdateFromDB();
    sizeSlider:UpdateFromDB();
    cbClassColor:UpdateFromDB();
    ringColor:UpdateFromDB();
    cbHideBg:UpdateFromDB();
    cbOutOfCombat:UpdateFromDB();
    cbHideOnClick:UpdateFromDB();
    cbGcd:UpdateFromDB();
    cbGcdClassColor:UpdateFromDB();
    gcdColor:UpdateFromDB();
    cbCastSwipe:UpdateFromDB();
    cbCastClassColor:UpdateFromDB();
    castColor:UpdateFromDB();
    cbTrail:UpdateFromDB();
    cbTrailClassColor:UpdateFromDB();
    trailColor:UpdateFromDB();
    trailDurationSlider:UpdateFromDB();
  end;

  return outerFrame;
end

-- Register page
UtilityHub.OptionsPages.MouseRing = MouseRingPage;
