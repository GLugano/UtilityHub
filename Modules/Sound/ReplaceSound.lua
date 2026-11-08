local moduleName = "ReplaceSound";
---@class ReplaceSound
local Module = UtilityHub.Addon:NewModule(moduleName);
local firstHolyStrike = {
  spellID = 679,
  sound = nil,
  name = nil,
};

local function ToggleSound()
  if (not firstHolyStrike.sound) then
    return;
  end

  if (UtilityHub.Database.global.options.replaceSoundHolyStrike) then
    MuteSoundFile(firstHolyStrike.sound);
  else
    UnmuteSoundFile(firstHolyStrike.sound);
  end
end

ToggleSound();

function Module:RegisterEvent()
  if (Module.eventRegistered) then
    return;
  end

  Module.eventRegistered = EventRegistry:RegisterFrameEventAndCallback("UNIT_SPELLCAST_SUCCEEDED",
    function(_, unit, _, spellID)
      if (Module:IsEnabled() and unit == "player" and firstHolyStrike.name) then
        local spellName = C_Spell.GetSpellName(spellID);

        if (firstHolyStrike.name == spellName and UtilityHub.Database.global.options.replaceSoundHolyStrike) then
          PlaySoundFile(UtilityHub.Constants.Path .. "\\Assets\\Sounds\\HotR.ogg", "SFX");
        end
      end
    end);
end

function Module:OnEnable()
  if (firstHolyStrike.name == nil) then
    firstHolyStrike.name = C_Spell.GetSpellName(firstHolyStrike.spellID);
  end

  ToggleSound();

  Module:RegisterEvent();
end;

function Module:OnDisable()
  ToggleSound();
end;

UtilityHub.Events:RegisterCallback("OPTIONS_CHANGED", function(_, name)
  if (name == "replaceSoundHolyStrike") then
    ToggleSound();
  end
end);
