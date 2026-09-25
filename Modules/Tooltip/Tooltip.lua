local moduleName = "Tooltip";
---@class Tooltip
local Module = UtilityHub.Addon:NewModule(moduleName);

if (not Module) then
  return;
end

local skills = {
  -- Professions
  "Fishing",
  "Mining",
  "Enginnering",
  "Herbalism",
  "Cooking",
  "Enchanting",
  -- Weapons
  "Unharmed",
  "Swords",
  "Two-handed Swords",
  "Maces",
  "Two-handed Maces",
  "Axes",
  "Two-handed Axes",
  "Throwing Weapons",
  "Daggers",
  "Polearms",
  "Staves",
  "Wands",
  "Bows",
  "Crossbows",
  "Guns",
};

---@class PrefixConfig
---@field overrite boolean
---@field value? string

---@class PatternConfig
---@field pattern? string|string[]
---@field IdentifyPattern? fun(self: PatternConfig, text: string): boolean
---@field FormatText fun(self: PatternConfig, text: string, prefix?: string): (string, PrefixConfig?)

---@param text string
---@param format string
---@return string
local function ByFormat(text, format)
  local value = text:match("by (%d+)");
  return string.format(format, value);
end

Module.formats                                        = {};

-- Physical
Module.formats.ATTACK_POWER_CLASSIC                   = {
  pattern = "+(%d+) Attack Power.$",
  FormatText = function(self, text)
    local ap = text:match("(%d+) Attack Power");
    return string.format("+%s Attack Power", ap);
  end
};

Module.formats.ATTACK_POWER                           = {
  pattern = "Increases attack power by (%d+).$",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Attack Power");
  end
};

Module.formats.ATTACK_POWER_SPECIFIC_MOB_TYPE_FOREVER = {
  pattern = "+(%d+) Attack Power against (%a+).$",
  FormatText = function(self, text)
    local ap = text:match("(%d+) Attack Power");
    local mobType = text:match("against (%a+).");

    return string.format("+%s Attack Power against %s", ap, mobType);
  end
};

Module.formats.RANGED_ATTACK_POWER_CLASSIC            = {
  pattern = "+(%d+) ranged Attack Power.$",
  FormatText = function(self, text)
    local ap = text:match("(%d+)");
    return string.format("+%s Ranged Attack Power", ap);
  end
};

Module.formats.RANGED_ATTACK_POWER                    = {
  pattern = "Increases ranged attack power by (%d+).$",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Ranged Attack Power");
  end
};

Module.formats.RANGED_CRITICAL                        = {
  pattern = "Increases your ranged critical strike rating by (%d+)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Ranged Crit Rating");
  end
};

Module.formats.RANGED_ATTACK_SPEED                    = {
  pattern = "Increases ranged attack speed by (%d+)%%",
  FormatText = function(self, text)
    return ByFormat(text, "+%s%% Ranged Attack Speed");
  end
};

Module.formats.MISSILE_CRITICAL                       = {
  pattern = "Improves your chance to get a critical strike with missile weapons by (%d+)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s%% Ranged Crit");
  end
};

Module.formats.PHYSICAL_CRITICAL_CLASSIC              = {
  pattern = "(critical strike by (%d+))",
  FormatText = function(self, text)
    return ByFormat(text, "+%s%% Physical Crit");
  end
};

Module.formats.PHYSICAL_CRITICAL                      = {
  pattern = {
    "Increases your critical strike rating by (%d+)",
    "Improves critical strike rating by (%d+)"
  },
  FormatText = function(self, text)
    return ByFormat(text, "+%s Physical Crit Rating");
  end
};

Module.formats.PHYSICAL_HIT_CLASSIC                   = {
  pattern = "(%Improves your chance to hit by)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s%% Physical Hit");
  end
};

Module.formats.PHYSICAL_HIT                           = {
  pattern = {
    "Increases your hit rating by (%d+)",
    "Improves hit rating by (%d+)"
  },
  FormatText = function(self, text)
    return ByFormat(text, "+%s Physical Hit Rating");
  end
};

Module.formats.PHYSICAL_EXPERTISE                     = {
  pattern = "Increases your expertise rating by (%d+).$",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Expertise Rating");
  end
};

Module.formats.DRUID_ATTACK_POWER_CLASSIC             = {
  pattern = "Attack Power in Cat, Bear, and Dire Bear forms only",
  FormatText = function(self, text)
    local ap = text:match("%+(%d+)");
    return string.format("+%s Feral Attack Power", ap);
  end
};

Module.formats.DRUID_ATTACK_POWER                     = {
  pattern = "Increases attack power by (%d+) in Cat, Bear, Dire Bear, and Moonkin forms only.",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Feral Attack Power");
  end
};

Module.formats.PHYSICAL_ARMOR_PENETRATION             = {
  pattern = "Your attacks ignore (%d+) of your opponent's armor.",
  FormatText = function(self, text)
    local ap = text:match("(%d+)");
    return string.format("+%s Armor Penetration", ap);
  end
};

Module.formats.PHYSICAL_HASTE                         = {
  pattern = "Improves haste rating by (%d+).",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Haste Rating");
  end
};

-- Spell
Module.formats.SPELL_PENETRATION_CLASSIC              = {
  pattern = "Decreases the magical resistances",
  FormatText = function(self, text)
    local magicResist = text:match("(%d+)");
    return string.format("+%s Spell Penetration", magicResist);
  end
};

Module.formats.SPELL_PENETRATION                      = {
  pattern = "Increases your spell penetration by (%d+)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Spell Penetration");
  end
};

Module.formats.SPELL_PENETRATION_FOREVER              = {
  pattern = "Your spells pierce",
  FormatText = function(self, text)
    local magicResist = text:match("(%d+)");
    return string.format("+%s Spell Penetration", magicResist);
  end
};

Module.formats.SPELL_DAMAGE_SPECIFIC_SCHOOL           = {
  pattern = {
    "Increases damage done by (%a+) spells",
    "Increases the damage done by (%a+) spells",
  },
  FormatText = function(self, text)
    local schoolType = text:match("by (%a+) spells?");
    local spellPower = text:match("(%d+)");

    if (schoolType and schoolType:lower() == "magical") then
      return string.format("+%s Spell Power", spellPower);
    end

    return string.format("+%s %s Spell Power", spellPower, schoolType);
  end
};

Module.formats.SPELL_HIT_CLASSIC                      = {
  pattern = "(%Improves your chance to hit with spells)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s%% Spell Hit");
  end
};

Module.formats.SPELL_HIT                              = {
  pattern = {
    "Increases your spell hit rating by (%d+)",
    "Improves spell hit rating by (%d+)"
  },
  FormatText = function(self, text)
    return ByFormat(text, "+%s Spell Hit Rating");
  end
};

Module.formats.SPELL_DAMAGE_CLASSIC                   = { -- +ATIESH AURA
  pattern = "(%Increases damage and healing)",
  FormatText = function(self, text)
    local spellPower = text:match("by up to (%d+)");
    local source = text:match("by (.-) by");
    ---@type PrefixConfig | nil
    local prefixConfig = nil;

    if (source == "spells and effects" or source == "magical spells and effects") then
      source = "Spell Power";
    elseif (source == "magical spells and effects of all party members within 30 yards") then
      source = "Spell Power (Group, 30y)";
      prefixConfig = {
        overrite = true,
        value = "Aura:",
      };
    else
      source = string.format("%s (%s)", "Spell Power", source);
    end

    return string.format("+%s %s", spellPower, source), prefixConfig;
  end
};

Module.formats.SPELL_DAMAGE                           = {
  pattern = "Increases damage and healing done by magical spells and effects by up to (%d+).",
  FormatText = function(self, text)
    local spellPower = text:match("by up to (%d+)");
    return string.format("+%s Spell Power", spellPower);
  end
};

Module.formats.SPELL_CRITICAL_CLASSIC                 = { -- Spell/Healing
  pattern = "(critical strike with spells by (%d+))",
  FormatText = function(self, text)
    return ByFormat(text, "+%s%% Spell Crit");
  end
};

Module.formats.SPELL_CRITICAL                         = { -- Spell/Healing
  pattern = {
    "Increases your spell critical strike rating by (%d+)",
    "Improves spell critical strike rating by (%d+)"
  },
  FormatText = function(self, text)
    return ByFormat(text, "+%s Spell Crit Rating");
  end
};

Module.formats.SPELL_HASTE                            = {
  pattern = {
    "Increases your spell haste rating by (%d+)",
    "Improves spell haste rating by (%d+)"
  },
  FormatText = function(self, text)
    return ByFormat(text, "+%s Spell Haste Rating");
  end
};

Module.formats.SPELL_DAMAGE_SPECIFIC_MOB_TYPE_FOREVER = {
  pattern = "Increases damage done to (%a+) by magical spells and effects by up to (%d+).",
  FormatText = function(self, text)
    local spellPower = text:match("by up to (%d+)");
    local mobType = text:match("to (%a+) by");
    return string.format("+%s Spell Power against %s", spellPower, mobType);
  end
};

-- Healing
Module.formats.HEALING_CLASSIC                        = { -- + ATIESH AURA
  pattern = "Increases healing done by",
  FormatText = function(self, text)
    local healingPower = text:match("by up to (%d+)");
    local source = text:match("by (.-) by");
    ---@type PrefixConfig | nil
    local prefixConfig = nil;

    if (source == "spells and effects") then
      source = "Spell Healing";
    elseif (source == "magical spells and effects of all party members within 30 yards") then
      source = "Spell Healing (Group, 30y)";
      prefixConfig = {
        overrite = true,
        value = "Aura:",
      };
    else
      source = string.format("%s (%s)", "Healing Power", source);
    end

    return string.format("+%s %s", healingPower, source), prefixConfig;
  end
};

Module.formats.HEALING                                = {
  pattern = "Increases healing done by up to (%d+) and damage done by up to (%d+) for all magical spells and effects",
  FormatText = function(self, text, prefix)
    local healing = text:match("healing done by up to (%d+)");
    local damage = text:match("damage done by up to (%d+)");

    return string.format("+%s Healing Power\n%s +%s Spell Power", healing, prefix, damage);
  end
};

Module.formats.HEALING_FOREVER                        = {
  pattern = {
    "Increases healing done by up to (%d+) and damage done by up to (%d+) for all magical spells and effects",
    "Increases healing done by magical spells and effects by up to (%d+)",
  },
  FormatText = function(self, text, prefix)
    local damage = text:match("damage done by up to (%d+)");

    if (damage) then
      return string.format("+%s Healing Power\n%s +%s Spell Power", text:match("healing done by up to (%d+)"), prefix,
        damage);
    end

    return string.format("+%s Healing Power", text:match("by up to (%d+)"), prefix);
  end
};

-- Resources
Module.formats.MANA_REGEN                             = {
  pattern = "(%d+) mana per",
  FormatText = function(self, text, prefix)
    if (prefix) then
      text = text:gsub(prefix, "");
      text = text:gsub(" Restores ", "+");
    end

    text = text:gsub("mana per 5 sec.", "MP5");

    return text;
  end
};

Module.formats.MANA_REGEN_FOREVER                     = {
  pattern = "Restores (%d+) Mana per",
  FormatText = function(self, text, prefix)
    local regen = text:lower():match("restores (%d+)");
    return string.format("+%s MP5", regen);
  end
};

Module.formats.HEALTH_REGEN                           = {
  pattern = {
    "(%d+) health per",
    "(%d+) Health per",
  },
  FormatText = function(self, text)
    local regen = text:lower():match("(%d+) health per");
    return string.format("+%s HP5", regen);
  end
};

-- Fixed
Module.formats.MINOR_SPEED                            = {
  pattern = {
    "Minor Speed Increase",
    "Run speed increased slightly",
  },
  FormatText = function(self, text)
    return "+8% Movement Speed";
  end
};

-- Atiesh
Module.formats.ATIESH_AURA_CRIT                       = {
  pattern = "Increases the spell critical chance of all",
  FormatText = function(self, text)
    local spellPower = text:match("by (%d+)%%.");
    ---@type PrefixConfig
    local prefixConfig = {
      overrite = true,
      value = "Aura:",
    };

    return string.format("+%s%% Spell Crit (Group, 30y)", spellPower), prefixConfig;
  end
};

Module.formats.ATIESH_SPELL_HEALING                   = {
  pattern = "Increases your spell damage by up to (%d+) and your healing by up to (%d+)",
  FormatText = function(self, text, prefix)
    -- [1] = spellPower
    -- [2] = healingPower
    local tokens = {};

    for v in text:gmatch("(%d+)") do
      tinsert(tokens, v);
    end

    return string.format("+%s Healing Power\n%s +%s Spell Power", tokens[2], prefix, tokens[1]);
  end
};

-- Temp stat Increase
Module.formats.TEMP_STAT_INCREASE_CLASSIC             = {
  pattern = "Increases (.-) by (%d+) for (%d+) sec.",
  FormatText = function(self, text)
    local statName, value, duration = text:match("Increases (.-) by (%d+) for (%d+) sec%.$");

    statName = Module.statNameConversionMap[statName] or statName;

    return string.format("+%s %s for %s seconds", value, statName, duration);
  end
};

Module.formats.ATTACK_SPEED_INCREASE_CLASSIC          = {
  pattern = "Increases your attack speed",
  FormatText = function(self, text)
    -- [1] = atkSpeed
    -- [2] = seconds
    local tokens = {};

    for v in text:gmatch("(%d+)") do
      tinsert(tokens, v);
    end

    return string.format("+%s%% Attack Speed for %s seconds", tokens[1], tokens[2]);
  end
};

-- Enchants
Module.formats.GENERIC_ENCHANT                        = {
  -- Rules:
  -- 1. Need to start with any string
  -- 2. Then have a [ +]
  -- 3. Then have a digit
  pattern = "^(.-) %+(%d+)$",
  FormatText = function(self, text)
    local statName, value = text:match("^(.-) %+(%d+)$");

    statName = Module.statNameConversionMap[statName] or statName;

    if (statName == "Reinforced Armor") then
      statName = "Armor";
    end

    return string.format("+%s %s", value, statName);
  end
};

-- Skill
Module.formats.SKILL_INCREASE_CLASSIC                 = {
  IdentifyPattern = function(self, text)
    for _, skill in ipairs(skills) do
      if (text:match(skill)) then
        if (text:match("(.-) %+(%d)$")) then
          return true;
        else
          return false;
        end
      end
    end

    return false;
  end,
  FormatText = function(self, text)
    local skillName, skill = text:match("(.-) %+(%d)$");
    return string.format("+%s %s Skill", skill, skillName);
  end
};

Module.formats.SKILL_INCREASE_ENDSWITH                = {
  IdentifyPattern = function(self, text)
    for _, skill in ipairs(skills) do
      if (text:match(skill)) then
        -- If ends with [digit].
        if (text:match("(%d)%.$")) then
          return true;
        else
          return false;
        end
      end
    end

    return false;
  end,
  FormatText = function(self, text)
    local skillName, skill = text:match("Increased%s+(.-)%s+%+(%d+)%.$");
    return string.format("+%s %s Skill", skill, skillName);
  end
};

-- Defensive stats
Module.formats.DEFENSE_CLASSIC                        = {
  pattern = "(%Increased Defense)",
  FormatText = function(self, text)
    local defense = text:match("(%d+)");
    return string.format("+%s Defense Skill", defense);
  end
};

Module.formats.DEFENSE                                = {
  pattern = "Increases defense rating by (%d+)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Defense Rating");
  end
};

Module.formats.DODGE_CLASSIC                          = {
  pattern = "(%Increases your chance to dodge)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s%% Dodge");
  end
};

Module.formats.DODGE                                  = {
  pattern = "Increases your dodge rating by (%d+)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Dodge Rating");
  end
};

Module.formats.PARRY_CLASSIC                          = {
  pattern = "(%Increases your chance to parry)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s%% Parry");
  end
};

Module.formats.PARRY                                  = {
  pattern = "Increases your parry rating by (%d+)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Parry Rating");
  end
};

Module.formats.BLOCK_CLASSIC                          = {
  pattern = "(%Increases your chance to block)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s%% Block");
  end
};

Module.formats.BLOCK                                  = {
  pattern = {
    "Increases your shield block rating by (%d+)",
    "Increases your block rating by (%d+)"
  },
  FormatText = function(self, text)
    return ByFormat(text, "+%s Block Rating");
  end
};

Module.formats.BLOCK_VALUE_CLASSIC                    = {
  pattern = "(%Increases the block value)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Block Value");
  end
};

Module.formats.BLOCK_VALUE                            = {
  pattern = "Increases the block value of your shield by (%d+)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Block Value");
  end
};

Module.formats.RESILIENCE                             = {
  pattern = "Improves your resilience rating by (%d+)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Resilience Rating");
  end
};

Module.formats.SWIM_SPEED                             = {
  pattern = "Increases swim speed by (%d+)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s%% Swim Speed");
  end
};

Module.formats.STEALTH_DETECTION_SLIGHTLY             = {
  pattern = "Slightly increases your stealth detection",
  FormatText = function(self, text)
    return "+10 Stealth Detection";
  end
};

Module.formats.STEALTH_DETECTION_MODERATELY           = {
  pattern = {
    "Increases your stealth detection.",
    "Moderately increases your stealth detection."
  },
  FormatText = function(self, text)
    return "+18 Stealth Detection";
  end
};

Module.formats.STEALTH_DETECTION                      = {
  pattern = "Increases your effective stealth detection level by (%d+)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Stealth Detection");
  end
};

Module.formats.STEALTH                                = {
  pattern = "Increases your effective stealth level by 1",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Stealth");
  end
};

Module.formats.LOCKPICKING                            = {
  pattern = "Increases your lockpicking skill slightly",
  FormatText = function(self, text)
    return "+5 Lockpicking";
  end
};

-- Strange things
Module.formats.NEGATIVE_PARRY                         = {
  pattern = "Decreases your chance to parry an attack by (%d+)",
  FormatText = function(self, text)
    return ByFormat(text, "-%s%% Parry");
  end
};

Module.formats.FLAT_SPELL_DAMAGE_REDUCTION            = {
  pattern = "Spell Damage received is reduced by (%d+)",
  FormatText = function(self, text)
    return ByFormat(text, "-%s Spell Damage Taken");
  end
};

Module.formats.DISARM_DURATION                        = {
  pattern = "Disarm duration reduced by (%d+)%%",
  FormatText = function(self, text)
    return ByFormat(text, "-%s%% Disarm Duration");
  end
};

Module.formats.INTERRUPT_DURATION                     = {
  pattern = {
    "Reduces the duration of any Silence or Interrupt effects used against the wearer by (%d+)%%",
    "Increases your resistance to silence effects by (%d+)%%",
  },
  FormatText = function(self, text)
    return ByFormat(text, "-%s%% Silence/Interrupt Duration");
  end
};

---@type PatternConfig[]
Module.patternConfigList                              = {};
Module.statNameConversionMap                          = {
  Health = "HP",
  Mana = "MP",
};

---@type boolean
Module.itemRefTooltipHooked                           = false;
---@type boolean
Module.gameTooltipHooked                              = false;

---@param patternConfig PatternConfig
---@param text string|nil
---@return boolean
---@return string|nil matchedPattern
local function IdentifyPattern(patternConfig, text)
  if (not text or #text == 0) then
    return false;
  end

  if (patternConfig.IdentifyPattern) then
    return patternConfig:IdentifyPattern(text);
  else
    local patternList = (type(patternConfig.pattern) == "string" and { patternConfig.pattern })
        or patternConfig.pattern
        or {};

    for _, pattern in ipairs(patternList) do
      local result = text:match(pattern);

      if (result) then
        return true, pattern;
      end
    end

    return false, nil;
  end
end

local function ExtractPrefix(text)
  local prefixes = {
    "^%(%d%) Set:",    -- Set bonus active
    "Set:",            -- Set bonus inactive
    "^Equip:",         -- Equip
    "^Chance on hit:", -- Equip
    "^Use:",           -- Equip
    "^Socket Bonus:",  -- Equip
    "Enchanted:",
  };

  for _, prefix in ipairs(prefixes) do
    local result = text:match(prefix);

    if (result) then
      return result;
    end
  end

  return nil;
end

---@param text string
---@param prefix string
---@param tooltipLineRef any
local function SearchAndApplyPattern(text, prefix, tooltipLineRef)
  local clearText = prefix and string.gsub(text, prefix .. " ", "");

  if (clearText == nil or #clearText == 0) then
    return;
  end

  for _, patternConfig in pairs(Module.patternConfigList) do
    if (UtilityHub.Constants.IsForever) then
      local matched, patternMatched = IdentifyPattern(patternConfig, clearText);

      if (prefix ~= "Use:" and prefix ~= "Change on hit:" and matched) then
        local newString, prefixConfig = patternConfig:FormatText(clearText, prefix);
        local newPrefix = prefix;

        if (prefixConfig and prefixConfig.overrite and prefixConfig.value) then
          newPrefix = prefixConfig.value;
        end

        if (prefixConfig and prefixConfig.overrite and prefixConfig.value) then
          newPrefix = prefixConfig.value;
        end

        if (newPrefix) then
          newString = string.format("%s %s", newPrefix, newString);
        end

        if (newString) then
          tooltipLineRef:SetText(newString);
          return;
        end
      end
    else
      if (prefix ~= "Use:" and IdentifyPattern(patternConfig, text)) then
        local newString, prefixConfig = patternConfig:FormatText(text, prefix);
        local newPrefix = prefix;

        if (prefixConfig and prefixConfig.overrite and prefixConfig.value) then
          newPrefix = prefixConfig.value;
        end

        if (newPrefix) then
          newString = string.format("%s %s", newPrefix, newString);
        end

        if (newString) then
          tooltipLineRef:SetText(newString);
          return;
        end
      end
    end
  end
end

local function OnTooltipSetItemEvent(tooltip)
  -- If some weird shit happens, why not
  if (not tooltip or not Module:IsEnabled()) then
    return;
  end

  local tooltipName = tooltip:GetName();

  for i = 1, tooltip:NumLines() do
    local tooltipLineRef = _G[string.format("%sTextLeft%s", tooltipName, i)];

    if (tooltipLineRef) then
      local text = tooltipLineRef:GetText();
      local prefix = ExtractPrefix(text);

      SearchAndApplyPattern(text, prefix, tooltipLineRef);
    end
  end
end

local function UpdatePatternConfig()
  Module.patternConfigList = {};
  local formats = Module.formats;

  if (UtilityHub.Constants.IsClassic) then
    tinsert(Module.patternConfigList, formats.ATTACK_POWER_CLASSIC);
    tinsert(Module.patternConfigList, formats.ATTACK_SPEED_INCREASE_CLASSIC);
    tinsert(Module.patternConfigList, formats.PHYSICAL_HIT_CLASSIC);
    tinsert(Module.patternConfigList, formats.DRUID_ATTACK_POWER_CLASSIC);
    tinsert(Module.patternConfigList, formats.RANGED_ATTACK_POWER_CLASSIC);
    tinsert(Module.patternConfigList, formats.PHYSICAL_CRITICAL_CLASSIC);

    tinsert(Module.patternConfigList, formats.DEFENSE_CLASSIC);
    tinsert(Module.patternConfigList, formats.BLOCK_CLASSIC);
    tinsert(Module.patternConfigList, formats.DODGE_CLASSIC);
    tinsert(Module.patternConfigList, formats.PARRY_CLASSIC);
    tinsert(Module.patternConfigList, formats.BLOCK_VALUE_CLASSIC);

    tinsert(Module.patternConfigList, formats.SPELL_DAMAGE_CLASSIC);
    tinsert(Module.patternConfigList, formats.SPELL_CRITICAL_CLASSIC);
    tinsert(Module.patternConfigList, formats.SPELL_HIT_CLASSIC);
    tinsert(Module.patternConfigList, formats.SPELL_PENETRATION_CLASSIC);

    tinsert(Module.patternConfigList, formats.HEALING_CLASSIC);

    tinsert(Module.patternConfigList, formats.SKILL_INCREASE_CLASSIC);

    tinsert(Module.patternConfigList, formats.TEMP_STAT_INCREASE_CLASSIC);
  elseif (UtilityHub.Constants.IsForever) then
    tinsert(Module.patternConfigList, formats.ATTACK_POWER_CLASSIC);
    tinsert(Module.patternConfigList, formats.ATTACK_POWER_SPECIFIC_MOB_TYPE_FOREVER);

    tinsert(Module.patternConfigList, formats.DEFENSE_CLASSIC);
    tinsert(Module.patternConfigList, formats.BLOCK_CLASSIC);
    tinsert(Module.patternConfigList, formats.DODGE_CLASSIC);
    tinsert(Module.patternConfigList, formats.PARRY_CLASSIC);
    tinsert(Module.patternConfigList, formats.BLOCK_VALUE_CLASSIC);

    tinsert(Module.patternConfigList, formats.MANA_REGEN_FOREVER);

    tinsert(Module.patternConfigList, formats.SPELL_DAMAGE);
    tinsert(Module.patternConfigList, formats.HEALING_FOREVER);
    tinsert(Module.patternConfigList, formats.SPELL_PENETRATION_FOREVER);
    tinsert(Module.patternConfigList, formats.SPELL_DAMAGE_SPECIFIC_MOB_TYPE_FOREVER);

    tinsert(Module.patternConfigList, formats.TEMP_STAT_INCREASE_CLASSIC);
    tinsert(Module.patternConfigList, formats.STEALTH_DETECTION);
  else
    tinsert(Module.patternConfigList, formats.ATTACK_POWER);
    tinsert(Module.patternConfigList, formats.PHYSICAL_HIT);
    tinsert(Module.patternConfigList, formats.DRUID_ATTACK_POWER);
    tinsert(Module.patternConfigList, formats.PHYSICAL_CRITICAL);
    tinsert(Module.patternConfigList, formats.PHYSICAL_EXPERTISE);
    tinsert(Module.patternConfigList, formats.PHYSICAL_ARMOR_PENETRATION);
    tinsert(Module.patternConfigList, formats.PHYSICAL_HASTE);
    tinsert(Module.patternConfigList, formats.RANGED_ATTACK_POWER);
    tinsert(Module.patternConfigList, formats.RANGED_CRITICAL);

    tinsert(Module.patternConfigList, formats.SPELL_HIT);
    tinsert(Module.patternConfigList, formats.SPELL_DAMAGE);
    tinsert(Module.patternConfigList, formats.SPELL_CRITICAL);
    tinsert(Module.patternConfigList, formats.SPELL_HASTE);
    tinsert(Module.patternConfigList, formats.SPELL_PENETRATION);

    tinsert(Module.patternConfigList, formats.HEALING);

    tinsert(Module.patternConfigList, formats.DEFENSE);
    tinsert(Module.patternConfigList, formats.DODGE);
    tinsert(Module.patternConfigList, formats.PARRY);
    tinsert(Module.patternConfigList, formats.BLOCK);
    tinsert(Module.patternConfigList, formats.BLOCK_VALUE);
    tinsert(Module.patternConfigList, formats.RESILIENCE);
  end

  tinsert(Module.patternConfigList, formats.SPELL_DAMAGE_SPECIFIC_SCHOOL);

  if (not UtilityHub.Constants.IsForever) then
    tinsert(Module.patternConfigList, formats.GENERIC_ENCHANT);
    tinsert(Module.patternConfigList, formats.MANA_REGEN);
  end

  tinsert(Module.patternConfigList, formats.MINOR_SPEED);

  tinsert(Module.patternConfigList, formats.ATIESH_AURA_CRIT);
  tinsert(Module.patternConfigList, formats.ATIESH_SPELL_HEALING);

  tinsert(Module.patternConfigList, formats.HEALTH_REGEN);
  tinsert(Module.patternConfigList, formats.NEGATIVE_PARRY);
  tinsert(Module.patternConfigList, formats.MISSILE_CRITICAL);
  tinsert(Module.patternConfigList, formats.RANGED_ATTACK_SPEED);
  tinsert(Module.patternConfigList, formats.SWIM_SPEED);
  tinsert(Module.patternConfigList, formats.FLAT_SPELL_DAMAGE_REDUCTION);
  tinsert(Module.patternConfigList, formats.STEALTH_DETECTION_SLIGHTLY);
  tinsert(Module.patternConfigList, formats.STEALTH_DETECTION_MODERATELY);
  tinsert(Module.patternConfigList, formats.STEALTH);
  tinsert(Module.patternConfigList, formats.LOCKPICKING);
  tinsert(Module.patternConfigList, formats.SKILL_INCREASE_ENDSWITH);
  tinsert(Module.patternConfigList, formats.DISARM_DURATION);
  tinsert(Module.patternConfigList, formats.INTERRUPT_DURATION);
end

function Module:OnEnable()
  UpdatePatternConfig();

  if (UtilityHub.Constants.IsForever) then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnTooltipSetItemEvent);
  else
    if (not Module.itemRefTooltipHooked) then
      Module.itemRefTooltipHooked = ItemRefTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItemEvent);
    end

    if (not Module.gameTooltipHooked) then
      Module.gameTooltipHooked = GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItemEvent);
    end

    if (not Module.shopping1TooltipHooked) then
      Module.shopping1TooltipHooked = ShoppingTooltip1:HookScript("OnTooltipSetItem", OnTooltipSetItemEvent);
    end

    if (not Module.shopping2TooltipHooked) then
      Module.shopping2TooltipHooked = ShoppingTooltip2:HookScript("OnTooltipSetItem", OnTooltipSetItemEvent);
    end

    hooksecurefunc("ItemSocketingFrame_LoadUI", function()
      if (not Module.itemSocketingDescriptionHooked) then
        Module.itemSocketingDescriptionHooked = ItemSocketingDescription:HookScript("OnTooltipSetItem",
          OnTooltipSetItemEvent);
      end
    end);
  end
end

-- Events
UtilityHub.Events:RegisterCallback("OPTIONS_CHANGED", function(_, name)
  if (name ~= "simpleStatsTooltip") then
    return;
  end

  if (UtilityHub.Database.global.options.simpleStatsTooltip) then
    UtilityHub.Addon:EnableModule("Tooltip");
  else
    UtilityHub.Addon:DisableModule("Tooltip");
  end
end);
