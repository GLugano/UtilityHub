local moduleName = "ReplaceSound";
---@class ReplaceSound
local Module = UtilityHub.Addon:NewModule(moduleName);
local firstHolyStrike = {
  spellID = 679,
  name = nil,
};

UnmuteSoundFile(firstHolyStrike.spellID);

function Module:RegisterEvent()
  if (Module.eventRegistered) then
    return;
  end

  Module.eventRegistered = EventRegistry:RegisterFrameEventAndCallback("UNIT_SPELLCAST_SUCCEEDED",
    function(_, unit, _, spellID)
      if (Module:IsEnabled() and unit == "player" and firstHolyStrike.name) then
        local spellName = C_Spell.GetSpellName(spellID);

        if (firstHolyStrike.name == spellName and UtilityHub.Database.global.options.replaceSoundHolyStrike) then
          PlaySoundFile(UtilityHub.Constants.Path .. "\\Assets\\Sound\\HotR.ogg", "SFX");
        end
      end
    end);
end

function Module:OnEnable()
  if (firstHolyStrike.name == nil) then
    firstHolyStrike.name = C_Spell.GetSpellName(firstHolyStrike.spellID);
  end

  MuteSoundFile(firstHolyStrike.spellID);

  Module:RegisterEvent();
end;

function Module:OnDisable()
  UnmuteSoundFile(firstHolyStrike.spellID);
end;
