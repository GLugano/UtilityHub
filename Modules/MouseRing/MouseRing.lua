local ASSET_PATH = "Interface\\AddOns\\UtilityHub\\Assets\\MouseRing\\";

local RING_TEXEL = 0.5 / 256;
local TRAIL_TEXEL = 0.5 / 128;
local TRAIL_MAX = 20;
local CAST_SWIPE_DELAY = 0.08;  -- 80ms delay to avoid flicker on failed casts
local GCD_DURATION = 1.5;       -- fixed GCD duration for TBC Classic
local floor = math.floor;
local max = math.max;

-- Register the Ace3 module immediately so it is available before any event fires
local Module = UtilityHub.Addon:NewModule("MouseRing");

---@class MouseRingState
local state = {
  inCombat = false,
  isRightMouseDown = false,
  -- Cast state
  isCasting = false,
  castStart = 0,
  castEnd = 0,
  -- Channel state
  isChanneling = false,
  channelStart = 0,
  channelEnd = 0,
  -- Shared cast/channel delay
  castSwipeAllowed = false,
  castDelayTimer = nil,
  -- GCD state
  gcdReady = true,
  gcdStart = 0,
  gcdDuration = 0,
  gcdTimer = nil,
};

local container, ring, swipeCooldown, gcdCooldown;
local trailContainer, trailPoints = nil, {};

local UpdateMouseWatcher;  -- forward declaration

--------------------------------------------------------------------------------
-- DB
--------------------------------------------------------------------------------

---@return table|nil
local function GetDB()
  local db = UtilityHub.Database
      and UtilityHub.Database.global
      and UtilityHub.Database.global.options
      and UtilityHub.Database.global.options.mouseRing;
  return db;
end

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function IsEnabled()
  return Module and Module:IsEnabled();
end

local function ShouldBeVisible()
  local db = GetDB();
  if (not db or not db.enabled) then return false end
  if (db.hideOnRightClick and state.isRightMouseDown) then return false end
  if (state.inCombat) then return true end
  return db.showOutOfCombat ~= false;
end

local function GetShapeFile()
  local db = GetDB();
  return (db and db.shape) or "ring.tga";
end

---@return number, number, number
local function GetClassColor()
  local _, className = UnitClass("player");
  if (RAID_CLASS_COLORS and RAID_CLASS_COLORS[className]) then
    local c = RAID_CLASS_COLORS[className];
    return c.r, c.g, c.b;
  end
  -- Fallback for clients where RAID_CLASS_COLORS uses a different structure
  if (GetClassColorObj) then
    local c = GetClassColorObj(className);
    if (c) then return c.r, c.g, c.b end
  end
  return 1, 1, 1;
end

---@return number, number, number
local function GetRingColor()
  local db = GetDB();
  if (not db) then return 1, 1, 1 end
  if (db.useClassColor) then
    return GetClassColor();
  end
  return db.colorR or 1, db.colorG or 1, db.colorB or 1;
end

--------------------------------------------------------------------------------
-- Texture setup
--------------------------------------------------------------------------------

---@param tex Texture
---@param shape string
local function SetupTexture(tex, shape)
  tex:SetTexture(ASSET_PATH .. shape);
  tex:SetTexCoord(RING_TEXEL, 1 - RING_TEXEL, RING_TEXEL, 1 - RING_TEXEL);
  if (tex.SetSnapToPixelGrid) then
    tex:SetSnapToPixelGrid(false);
    tex:SetTexelSnappingBias(0);
  end
end

--------------------------------------------------------------------------------
-- Render (single source of truth)
-- Priority: cast > channel > GCD > ready ring
--------------------------------------------------------------------------------

local function UpdateRender()
  if (not container) then return end

  UpdateMouseWatcher();

  if (not ShouldBeVisible()) then
    container:Hide();
    if (trailContainer) then trailContainer:Hide() end
    return;
  end

  container:Show();

  local db = GetDB();

  -- Background ring
  if (ring) then
    if (db.hideBackground) then
      ring:Hide();
    else
      local r, g, b = GetRingColor();
      ring:SetVertexColor(r, g, b, 1);
      ring:Show();
    end
  end

  -- Cast / channel swipe (larger, wraps outside the ring)
  if (swipeCooldown) then
    local showed = false;

    -- 1. Cast swipe
    if (db.castSwipeEnabled and state.castSwipeAllowed and state.isCasting and state.castStart > 0) then
      local r, g, b;
      if (db.castSwipeUseClassColor) then
        r, g, b = GetClassColor();
      else
        r, g, b = db.castSwipeR or 1, db.castSwipeG or 0.5, db.castSwipeB or 0;
      end
      swipeCooldown:SetSwipeColor(r, g, b, 0.8);
      swipeCooldown:SetCooldown(state.castStart, state.castEnd - state.castStart);
      swipeCooldown:Show();
      showed = true;

    -- 2. Channel swipe
    elseif (db.castSwipeEnabled and state.castSwipeAllowed and state.isChanneling and state.channelStart > 0) then
      local r, g, b;
      if (db.castSwipeUseClassColor) then
        r, g, b = GetClassColor();
      else
        r, g, b = db.castSwipeR or 1, db.castSwipeG or 0.5, db.castSwipeB or 0;
      end
      swipeCooldown:SetSwipeColor(r, g, b, 0.8);
      swipeCooldown:SetCooldown(state.channelStart, state.channelEnd - state.channelStart);
      swipeCooldown:Show();
      showed = true;
    end

    if (not showed) then
      swipeCooldown:Hide();
    end
  end

  -- GCD swipe (smaller, sits inside the ring)
  if (gcdCooldown) then
    if (db.gcdEnabled and not state.gcdReady and state.gcdStart > 0) then
      local r, g, b;
      if (db.gcdUseClassColor) then
        r, g, b = GetClassColor();
      else
        r, g, b = db.gcdR or 0.004, db.gcdG or 0.56, db.gcdB or 0.91;
      end
      gcdCooldown:SetSwipeColor(r, g, b, 0.8);
      gcdCooldown:SetCooldown(state.gcdStart, state.gcdDuration);
      gcdCooldown:Show();
    else
      gcdCooldown:Hide();
    end
  end

  -- Trail
  if (trailContainer) then
    if (db.trailEnabled) then
      trailContainer:Show();
    else
      trailContainer:Hide();
    end
  end
end

--------------------------------------------------------------------------------
-- Frame creation
--------------------------------------------------------------------------------

local function CreateRing()
  if (container) then return end

  local db = GetDB();
  if (not db) then return end

  local size = db.size or 48;
  if (size % 2 == 1) then size = size + 1 end

  local shape = GetShapeFile();

  container = CreateFrame("Frame", "UtilityHubMouseRingContainer", UIParent);
  container:SetSize(size, size);
  container:SetFrameStrata("TOOLTIP");
  container:EnableMouse(false);

  -- Ring texture sits below the swipe so the swipe renders on top
  local ringFrame = CreateFrame("Frame", nil, container);
  ringFrame:SetAllPoints();
  ringFrame:SetFrameLevel(container:GetFrameLevel() + 5);
  ring = ringFrame:CreateTexture(nil, "OVERLAY");
  ring:SetAllPoints();
  SetupTexture(ring, shape);

  -- Cast/channel swipe: slightly larger than the ring, wraps around the outside
  local castSize = floor(size * 1.3);
  if (castSize % 2 == 1) then castSize = castSize + 1 end

  swipeCooldown = CreateFrame("Cooldown", nil, container, "CooldownFrameTemplate");
  swipeCooldown:ClearAllPoints();
  swipeCooldown:SetSize(castSize, castSize);
  swipeCooldown:SetPoint("CENTER", container, "CENTER");
  swipeCooldown:SetDrawSwipe(true);
  swipeCooldown:SetDrawEdge(false);
  swipeCooldown:SetHideCountdownNumbers(true);
  swipeCooldown:SetReverse(true);
  if (swipeCooldown.SetSwipeTexture) then
    swipeCooldown:SetSwipeTexture(ASSET_PATH .. shape);
  end
  if (swipeCooldown.SetDrawBling) then swipeCooldown:SetDrawBling(false) end
  if (swipeCooldown.SetUseCircularEdge) then swipeCooldown:SetUseCircularEdge(true) end
  swipeCooldown:SetFrameLevel(container:GetFrameLevel() + 10);
  swipeCooldown:Hide();

  -- GCD swipe: smaller than the ring, sits inside
  local gcdSize = floor(size * 0.65);
  if (gcdSize % 2 == 1) then gcdSize = gcdSize + 1 end

  gcdCooldown = CreateFrame("Cooldown", nil, container, "CooldownFrameTemplate");
  gcdCooldown:ClearAllPoints();
  gcdCooldown:SetSize(gcdSize, gcdSize);
  gcdCooldown:SetPoint("CENTER", container, "CENTER");
  gcdCooldown:SetDrawSwipe(true);
  gcdCooldown:SetDrawEdge(false);
  gcdCooldown:SetHideCountdownNumbers(true);
  gcdCooldown:SetReverse(true);
  if (gcdCooldown.SetSwipeTexture) then
    gcdCooldown:SetSwipeTexture(ASSET_PATH .. shape);
  end
  if (gcdCooldown.SetDrawBling) then gcdCooldown:SetDrawBling(false) end
  if (gcdCooldown.SetUseCircularEdge) then gcdCooldown:SetUseCircularEdge(true) end
  gcdCooldown:SetFrameLevel(container:GetFrameLevel() + 3);
  gcdCooldown:Hide();

  -- Cursor following
  local lastX, lastY = 0, 0;
  container:SetScript("OnUpdate", function(self)
    if (not ShouldBeVisible()) then return end

    local x, y = GetCursorPosition();
    local scale = UIParent:GetEffectiveScale();
    x = floor(x / scale + 0.5);
    y = floor(y / scale + 0.5);

    if (x ~= lastX or y ~= lastY) then
      lastX, lastY = x, y;
      self:ClearAllPoints();
      self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y);
    end
  end);
end

local function CreateTrail()
  if (trailContainer) then return end

  trailContainer = CreateFrame("Frame", nil, UIParent);
  trailContainer:SetFrameStrata("TOOLTIP");
  trailContainer:SetFrameLevel(1);
  trailContainer:SetPoint("BOTTOMLEFT");
  trailContainer:SetSize(1, 1);

  for i = 1, TRAIL_MAX do
    local tex = trailContainer:CreateTexture(nil, "BACKGROUND");
    tex:SetTexture(ASSET_PATH .. "trail_glow.tga");
    tex:SetTexCoord(TRAIL_TEXEL, 1 - TRAIL_TEXEL, TRAIL_TEXEL, 1 - TRAIL_TEXEL);
    tex:SetBlendMode("ADD");
    tex:SetSize(24, 24);
    tex:Hide();
    trailPoints[i] = { tex = tex, x = 0, y = 0, time = 0, active = false };
  end

  local head = 0;
  local lastX, lastY = 0, 0;
  local updateTimer = 0;
  local activeCount = 0;

  local function TrailOnUpdate(self, elapsed)
    local db = GetDB();
    local shouldTrack = db and db.trailEnabled and ShouldBeVisible();

    updateTimer = updateTimer + elapsed;
    if (updateTimer < 0.025) then return end
    updateTimer = 0;

    local now = GetTime();

    if (shouldTrack) then
      local x, y = GetCursorPosition();
      local scale = UIParent:GetEffectiveScale();
      x = floor(x / scale + 0.5);
      y = floor(y / scale + 0.5);

      local dx, dy = x - lastX, y - lastY;
      if ((dx * dx + dy * dy) >= 4) then
        lastX, lastY = x, y;
        head = (head % TRAIL_MAX) + 1;
        local pt = trailPoints[head];
        if (not pt.active) then
          activeCount = activeCount + 1;
        end
        pt.x, pt.y, pt.time, pt.active = x, y, now, true;
      end
    end

    if (activeCount > 0) then
      local duration = max((db and db.trailDuration) or 0.6, 0.1);
      local tr, tg, tb = 1, 0.8, 0.2;
      if (db) then
        if (db.trailUseClassColor) then
          tr, tg, tb = GetClassColor();
        else
          tr, tg, tb = db.trailR or 1, db.trailG or 0.8, db.trailB or 0.2;
        end
      end

      for i = 1, TRAIL_MAX do
        local pt = trailPoints[i];
        if (pt.active) then
          local fade = 1 - (now - pt.time) / duration;
          if (fade <= 0) then
            pt.active = false;
            pt.tex:Hide();
            activeCount = activeCount - 1;
          else
            pt.tex:ClearAllPoints();
            pt.tex:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pt.x, pt.y);
            pt.tex:SetVertexColor(tr, tg, tb, fade * 0.8);
            pt.tex:SetSize(24 * fade, 24 * fade);
            pt.tex:Show();
          end
        end
      end
    end

    -- Keep OnUpdate running; it will idle cheaply when nothing is active
  end

  -- Start immediately; frames are shown by default in WoW so OnShow would never fire
  trailContainer:SetScript("OnUpdate", TrailOnUpdate);
end

--------------------------------------------------------------------------------
-- Mouse watcher (right-click hide)
--------------------------------------------------------------------------------

local mouseWatcher = CreateFrame("Frame");
local mouseWatcherActive = false;

local function MouseWatcherOnUpdate()
  local wasDown = state.isRightMouseDown;
  state.isRightMouseDown = IsMouseButtonDown("RightButton");
  if (wasDown ~= state.isRightMouseDown) then
    UpdateRender();
  end
end

UpdateMouseWatcher = function()
  local db = GetDB();
  local shouldRun = db and db.enabled and db.hideOnRightClick;

  if (shouldRun and not mouseWatcherActive) then
    mouseWatcher:SetScript("OnUpdate", MouseWatcherOnUpdate);
    mouseWatcherActive = true;
  elseif (not shouldRun and mouseWatcherActive) then
    mouseWatcher:SetScript("OnUpdate", nil);
    state.isRightMouseDown = false;
    mouseWatcherActive = false;
  end
end

--------------------------------------------------------------------------------
-- GCD tracking
--------------------------------------------------------------------------------

local function StartGCD()
  local db = GetDB();
  if (not db or not db.gcdEnabled) then return end

  if (state.gcdTimer) then
    state.gcdTimer:Cancel();
  end

  state.gcdReady = false;
  state.gcdStart = GetTime();
  state.gcdDuration = GCD_DURATION;
  state.gcdTimer = C_Timer.NewTimer(GCD_DURATION, function()
    state.gcdReady = true;
    state.gcdTimer = nil;
    UpdateRender();
  end);
end

--------------------------------------------------------------------------------
-- Event handling (always-active frame, gated by IsEnabled)
--------------------------------------------------------------------------------

local events = CreateFrame("Frame");
events:RegisterEvent("PLAYER_LOGIN");
events:RegisterEvent("PLAYER_ENTERING_WORLD");
events:RegisterEvent("PLAYER_REGEN_DISABLED");
events:RegisterEvent("PLAYER_REGEN_ENABLED");
events:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
events:RegisterEvent("UNIT_SPELLCAST_START");
events:RegisterEvent("UNIT_SPELLCAST_STOP");
events:RegisterEvent("UNIT_SPELLCAST_FAILED");
events:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED");
events:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START");
events:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP");

events:SetScript("OnEvent", function(self, event, unitID)
  -- Unit spell events: ignore non-player units
  if (event:find("UNIT_SPELLCAST") and unitID ~= "player") then return end

  -- Always process login/world events regardless of module state
  if (event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD") then
    state.inCombat = InCombatLockdown() or UnitAffectingCombat("player");
    CreateRing();
    CreateTrail();
    UpdateRender();
    return;
  end

  -- All other events require module to be enabled
  if (not IsEnabled()) then return end

  if (event == "PLAYER_REGEN_DISABLED") then
    state.inCombat = true;
    UpdateRender();

  elseif (event == "PLAYER_REGEN_ENABLED") then
    state.inCombat = false;
    UpdateRender();

  elseif (event == "UNIT_SPELLCAST_SUCCEEDED") then
    -- Fires for instants and completed casts — use for GCD
    StartGCD();
    UpdateRender();

  elseif (event == "UNIT_SPELLCAST_START") then
    local _, _, _, startTimeMS, endTimeMS = UnitCastingInfo("player");
    if (startTimeMS and endTimeMS) then
      state.isCasting = true;
      state.castStart = startTimeMS / 1000;
      state.castEnd = endTimeMS / 1000;
      state.castSwipeAllowed = false;
      if (state.castDelayTimer) then
        state.castDelayTimer:Cancel();
      end
      state.castDelayTimer = C_Timer.NewTimer(CAST_SWIPE_DELAY, function()
        state.castSwipeAllowed = true;
        state.castDelayTimer = nil;
        UpdateRender();
      end);
    end
    UpdateRender();

  elseif (event == "UNIT_SPELLCAST_CHANNEL_START") then
    local _, _, _, startTimeMS, endTimeMS = UnitChannelInfo("player");
    if (startTimeMS and endTimeMS) then
      state.isChanneling = true;
      state.channelStart = startTimeMS / 1000;
      state.channelEnd = endTimeMS / 1000;
      state.castSwipeAllowed = false;
      if (state.castDelayTimer) then
        state.castDelayTimer:Cancel();
      end
      state.castDelayTimer = C_Timer.NewTimer(CAST_SWIPE_DELAY, function()
        state.castSwipeAllowed = true;
        state.castDelayTimer = nil;
        UpdateRender();
      end);
    end
    UpdateRender();

  elseif (event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED") then
    if (state.isCasting) then
      state.isCasting = false;
      state.castStart = 0;
      state.castEnd = 0;
      if (state.castDelayTimer) then
        state.castDelayTimer:Cancel();
        state.castDelayTimer = nil;
      end
      state.castSwipeAllowed = false;
    end
    -- Check if still channeling
    local _, _, _, startTimeMS, endTimeMS = UnitChannelInfo("player");
    if (startTimeMS and endTimeMS) then
      state.isChanneling = true;
      state.channelStart = startTimeMS / 1000;
      state.channelEnd = endTimeMS / 1000;
    end
    UpdateRender();

  elseif (event == "UNIT_SPELLCAST_CHANNEL_STOP") then
    state.isChanneling = false;
    state.channelStart = 0;
    state.channelEnd = 0;
    if (state.castDelayTimer) then
      state.castDelayTimer:Cancel();
      state.castDelayTimer = nil;
    end
    state.castSwipeAllowed = false;
    UpdateRender();
  end
end);

--------------------------------------------------------------------------------
-- Module lifecycle
--------------------------------------------------------------------------------

function Module:OnEnable()
  state.inCombat = InCombatLockdown() or UnitAffectingCombat("player");
  CreateRing();
  CreateTrail();
  -- Refresh applies size, shape and all visual settings from DB
  Module:Refresh();
end

function Module:OnDisable()
  -- Cancel pending timers
  if (state.castDelayTimer) then
    state.castDelayTimer:Cancel();
    state.castDelayTimer = nil;
  end
  if (state.gcdTimer) then
    state.gcdTimer:Cancel();
    state.gcdTimer = nil;
  end
  -- Reset transient state
  state.isCasting = false;
  state.isChanneling = false;
  state.gcdReady = true;
  state.castSwipeAllowed = false;
  -- Hide frames
  if (container) then container:Hide() end
  if (gcdCooldown) then gcdCooldown:Hide() end
  if (trailContainer) then trailContainer:Hide() end
end

function Module:Refresh()
  if (not Module:IsEnabled()) then return end

  local db = GetDB();
  if (not db) then return end

  local shape = GetShapeFile();
  local size = db.size or 48;
  if (size % 2 == 1) then size = size + 1 end

  local castSize = floor(size * 1.3);
  if (castSize % 2 == 1) then castSize = castSize + 1 end

  local gcdSize = floor(size * 0.65);
  if (gcdSize % 2 == 1) then gcdSize = gcdSize + 1 end

  if (container) then container:SetSize(size, size) end
  if (ring) then SetupTexture(ring, shape) end
  if (swipeCooldown) then
    swipeCooldown:ClearAllPoints();
    swipeCooldown:SetSize(castSize, castSize);
    swipeCooldown:SetPoint("CENTER", container, "CENTER");
    if (swipeCooldown.SetSwipeTexture) then
      swipeCooldown:SetSwipeTexture(ASSET_PATH .. shape);
    end
  end
  if (gcdCooldown) then
    gcdCooldown:ClearAllPoints();
    gcdCooldown:SetSize(gcdSize, gcdSize);
    gcdCooldown:SetPoint("CENTER", container, "CENTER");
    if (gcdCooldown.SetSwipeTexture) then
      gcdCooldown:SetSwipeTexture(ASSET_PATH .. shape);
    end
  end

  UpdateRender();
end


UtilityHub.Events:RegisterCallback("OPTIONS_CHANGED", function(_, name)
  if (name == "mouseRing") then
    if (Module:IsEnabled()) then
      Module:Refresh();
    else
      -- Even when disabled, re-evaluate visibility (e.g., user toggled enabled off)
      UpdateRender();
    end
  end
end);
