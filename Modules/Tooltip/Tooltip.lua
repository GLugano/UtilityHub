local moduleName = 'Tooltip';
---@class Tooltip
local Module     = UtilityHub.Addon:NewModule(moduleName);

local skills     = {
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
---@field IdentifyPattern? fun(self: PatternConfig, text: string): string
---@field FormatText fun(self: PatternConfig, text: string, prefix?: string): (string, PrefixConfig?)

---@param text string
---@param format string
---@return string
local function ByFormat(text, format)
  local value = text:match("by (%d+)");
  return string.format(format, value);
end

-- Physical
local ATTACK_POWER_CLASSIC          = {
  pattern = "+(%d+) Attack Power.$",
  FormatText = function(self, text)
    local ap = text:match("(%d+) Attack Power");
    return string.format("+%s Attack Power", ap);
  end
};

local ATTACK_POWER                  = {
  pattern = "Increases attack power by (%d+).$",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Attack Power");
  end
};

local RANGED_ATTACK_POWER_CLASSIC   = {
  pattern = "+(%d+) ranged Attack Power.$",
  FormatText = function(self, text)
    local ap = text:match("(%d+)");
    return string.format("+%s Ranged Attack Power", ap);
  end
};

local RANGED_ATTACK_POWER           = {
  pattern = "Increases ranged attack power by (%d+).$",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Ranged Attack Power");
  end
};

local RANGED_CRITICAL               = {
  pattern = "Increases your ranged critical strike rating by (%d+)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Ranged Crit Rating");
  end
};

local RANGED_ATTACK_SPEED           = {
  pattern = "Increases ranged attack speed by (%d+)%%",
  FormatText = function(self, text)
    return ByFormat(text, "+%s%% Ranged Attack Speed");
  end
};

local MISSILE_CRITICAL              = {
  pattern = "Improves your chance to get a critical strike with missile weapons by (%d+)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s%% Ranged Crit");
  end
};

local PHYSICAL_CRITICAL_CLASSIC     = {
  pattern = "(critical strike by (%d+))",
  FormatText = function(self, text)
    return ByFormat(text, "+%s%% Physical Crit");
  end
};

local PHYSICAL_CRITICAL             = {
  pattern = {
    "Increases your critical strike rating by (%d+)",
    "Improves critical strike rating by (%d+)"
  },
  FormatText = function(self, text)
    return ByFormat(text, "+%s Physical Crit Rating");
  end
};

local PHYSICAL_HIT_CLASSIC          = {
  pattern = "(%Improves your chance to hit by)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s%% Physical Hit");
  end
};

local PHYSICAL_HIT                  = {
  pattern = {
    "Increases your hit rating by (%d+)",
    "Improves hit rating by (%d+)"
  },
  FormatText = function(self, text)
    return ByFormat(text, "+%s Physical Hit Rating");
  end
};

local PHYSICAL_EXPERTISE            = {
  pattern = "Increases your expertise rating by (%d+).$",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Expertise Rating");
  end
};

local DRUID_ATTACK_POWER_CLASSIC    = {
  pattern = "Attack Power in Cat, Bear, and Dire Bear forms only",
  FormatText = function(self, text)
    local ap = text:match("%+(%d+)");
    return string.format("+%s Feral Attack Power", ap);
  end
};

local DRUID_ATTACK_POWER            = {
  pattern = "Increases attack power by (%d+) in Cat, Bear, Dire Bear, and Moonkin forms only.",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Feral Attack Power");
  end
};

local PHYSICAL_ARMOR_PENETRATION    = {
  pattern = "Your attacks ignore (%d+) of your opponent's armor.",
  FormatText = function(self, text)
    local ap = text:match("(%d+)");
    return string.format("+%s Armor Penetration", ap);
  end
};

local PHYSICAL_HASTE                = {
  pattern = "Improves haste rating by (%d+).",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Haste Rating");
  end
};

-- Spell
local SPELL_PENETRATION_CLASSIC     = {
  pattern = "Decreases the magical resistances",
  FormatText = function(self, text)
    local magicResist = text:match("(%d+)");
    return string.format("+%s Spell Penetration", magicResist);
  end
};

local SPELL_PENETRATION             = {
  pattern = "Increases your spell penetration by (%d+)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Spell Penetration");
  end
};

local SPELL_DAMAGE_SPECIFIC_SCHOOL  = {
  pattern = {
    "Increases damage done by (%a+) spells",
    "Increases the damage done by (%a+) spells",
  },
  FormatText = function(self, text)
    local schoolType = text:match("by (%a+) spells?");
    local spellPower = text:match("(%d+)");
    return string.format("+%s %s Spell Power", spellPower, schoolType);
  end
};

local SPELL_HIT_CLASSIC             = {
  pattern = "(%Improves your chance to hit with spells)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s%% Spell Hit");
  end
};

local SPELL_HIT                     = {
  pattern = {
    "Increases your spell hit rating by (%d+)",
    "Improves spell hit rating by (%d+)"
  },
  FormatText = function(self, text)
    return ByFormat(text, "+%s Spell Hit Rating");
  end
};

local SPELL_DAMAGE_CLASSIC          = { -- +ATIESH AURA
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

local SPELL_DAMAGE                  = {
  pattern = "Increases damage and healing done by magical spells and effects by up to (%d+).",
  FormatText = function(self, text)
    local spellPower = text:match("by up to (%d+)");
    return string.format("+%s Spell Power", spellPower);
  end
};

local SPELL_CRITICAL_CLASSIC        = { -- Spell/Healing
  pattern = "(critical strike with spells by (%d+))",
  FormatText = function(self, text)
    return ByFormat(text, "+%s%% Spell Crit");
  end
};

local SPELL_CRITICAL                = { -- Spell/Healing
  pattern = {
    "Increases your spell critical strike rating by (%d+)",
    "Improves spell critical strike rating by (%d+)"
  },
  FormatText = function(self, text)
    return ByFormat(text, "+%s Spell Crit Rating");
  end
};

local SPELL_HASTE                   = {
  pattern = {
    "Increases your spell haste rating by (%d+)",
    "Improves spell haste rating by (%d+)"
  },
  FormatText = function(self, text)
    return ByFormat(text, "+%s Spell Haste Rating");
  end
};

-- Healing
local HEALING_CLASSIC               = { -- + ATIESH AURA
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

local HEALING                       = {
  pattern = "Increases healing done by up to (%d+) and damage done by up to (%d+) for all magical spells and effects",
  FormatText = function(self, text, prefix)
    local healing = text:match("healing done by up to (%d+)");
    local damage = text:match("damage done by up to (%d+)");

    return string.format("+%s Healing Power\n%s +%s Spell Power", healing, prefix, damage);
  end
};

-- Resources
local MANA_REGEN                    = {
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

local HEALTH_REGEN                  = {
  pattern = "(%d+) health per",
  FormatText = function(self, text)
    local regen = text:match("(%d+) health per");
    return string.format("+%s HP5", regen);
  end
};

-- Fixed
local MINOR_SPEED                   = {
  pattern = {
    "Minor Speed Increase",
    "Run speed increased slightly",
  },
  FormatText = function(self, text)
    return "+8% Movement Speed";
  end
};

-- Atiesh
local ATIESH_AURA_CRIT              = {
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

local ATIESH_SPELL_HEALING          = {
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
local TEMP_STAT_INCREASE_CLASSIC    = {
  pattern = "Increases (.-) by (%d+) for (%d+) sec.",
  FormatText = function(self, text)
    local statName, value, duration = text:match("Increases (.-) by (%d+) for (%d+) sec%.$");

    statName = Module.statNameConversionMap[statName] or statName;

    return string.format("+%s %s for %s seconds", value, statName, duration);
  end
};

local ATTACK_SPEED_INCREASE_CLASSIC = {
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
local GENERIC_ENCHANT               = {
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
local SKILL_INCREASE_CLASSIC        = {
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

local SKILL_INCREASE_ENDSWITH       = {
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
local DEFENSE_CLASSIC               = {
  pattern = "(%Increased Defense)",
  FormatText = function(self, text)
    local defense = text:match("(%d+)");
    return string.format("+%s Defense Skill", defense);
  end
};

local DEFENSE                       = {
  pattern = "Increases defense rating by (%d+)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Defense Rating");
  end
};

local DODGE_CLASSIC                 = {
  pattern = "(%Increases your chance to dodge)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s%% Dodge");
  end
};

local DODGE                         = {
  pattern = "Increases your dodge rating by (%d+)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Dodge Rating");
  end
};

local PARRY_CLASSIC                 = {
  pattern = "(%Increases your chance to parry)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s%% Parry");
  end
};

local PARRY                         = {
  pattern = "Increases your parry rating by (%d+)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Parry Rating");
  end
};

local BLOCK_CLASSIC                 = {
  pattern = "(%Increases your chance to block)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s%% Block");
  end
};

local BLOCK                         = {
  pattern = {
    "Increases your shield block rating by (%d+)",
    "Increases your block rating by (%d+)"
  },
  FormatText = function(self, text)
    return ByFormat(text, "+%s Block Rating");
  end
};

local BLOCK_VALUE_CLASSIC           = {
  pattern = "(%Increases the block value)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Block Value");
  end
};

local BLOCK_VALUE                   = {
  pattern = "Increases the block value of your shield by (%d+)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Block Value");
  end
};

local RESILIENCE                    = {
  pattern = "Improves your resilience rating by (%d+)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Resilience Rating");
  end
};

local SWIM_SPEED                    = {
  pattern = "Increases swim speed by (%d+)",
  FormatText = function(self, text)
    return ByFormat(text, "+%s%% Swim Speed");
  end
};

local STEALTH_DETECTION_SLIGHTLY    = {
  pattern = "Slightly increases your stealth detection",
  FormatText = function(self, text)
    return "+10 Stealth Detection";
  end
};

local STEALTH_DETECTION_MODERATELY  = {
  pattern = {
    "Increases your stealth detection.",
    "Moderately increases your stealth detection."
  },
  FormatText = function(self, text)
    return "+18 Stealth Detection";
  end
};

local STEALTH                       = {
  pattern = "Increases your effective stealth level by 1",
  FormatText = function(self, text)
    return ByFormat(text, "+%s Stealth");
  end
};

local LOCKPICKING                   = {
  pattern = "Increases your lockpicking skill slightly",
  FormatText = function(self, text)
    return "+5 Lockpicking";
  end
};

-- Strange things
local NEGATIVE_PARRY                = {
  pattern = "Decreases your chance to parry an attack by (%d+)",
  FormatText = function(self, text)
    return ByFormat(text, "-%s%% Parry");
  end
};

local FLAT_SPELL_DAMAGE_REDUCTION   = {
  pattern = "Spell Damage received is reduced by (%d+)",
  FormatText = function(self, text)
    return ByFormat(text, "-%s Spell Damage Taken");
  end
};

local DISARM_DURATION               = {
  pattern = "Disarm duration reduced by (%d+)%%",
  FormatText = function(self, text)
    return ByFormat(text, "-%s%% Disarm Duration");
  end
};

local INTERRUPT_DURATION            = {
  pattern = {
    "Reduces the duration of any Silence or Interrupt effects used against the wearer by (%d+)%%",
    "Increases your resistance to silence effects by (%d+)%%",
  },
  FormatText = function(self, text)
    return ByFormat(text, "-%s%% Silence/Interrupt Duration");
  end
};

---@type PatternConfig[]
Module.patternConfigList            = {};
Module.statNameConversionMap        = {
  Health = "HP",
  Mana = "MP",
};

---@type boolean
Module.itemRefTooltipHooked         = false;
---@type boolean
Module.gameTooltipHooked            = false;

---@param patternConfig PatternConfig
---@param text string|nil
---@return string|nil
local function IdentifyPattern(patternConfig, text)
  if (not text or #text == 0) then
    return nil;
  end

  if (patternConfig.IdentifyPattern) then
    return patternConfig:IdentifyPattern(text);
  else
    local patternList = (type(patternConfig.pattern) == "string" and { patternConfig.pattern })
        or patternConfig.pattern
        or {};

    for _, pattern in ipairs(patternList) do
      local result = text:match(pattern)

      if (result) then
        return result;
      end
    end

    return nil;
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
  for _, patternConfig in pairs(Module.patternConfigList) do
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
  if (UtilityHub.Constants.IsClassic) then
    tinsert(Module.patternConfigList, ATTACK_POWER_CLASSIC);
    tinsert(Module.patternConfigList, ATTACK_SPEED_INCREASE_CLASSIC);
    tinsert(Module.patternConfigList, PHYSICAL_HIT_CLASSIC);
    tinsert(Module.patternConfigList, DRUID_ATTACK_POWER_CLASSIC);
    tinsert(Module.patternConfigList, RANGED_ATTACK_POWER_CLASSIC);
    tinsert(Module.patternConfigList, PHYSICAL_CRITICAL_CLASSIC);

    tinsert(Module.patternConfigList, DEFENSE_CLASSIC);
    tinsert(Module.patternConfigList, BLOCK_CLASSIC);
    tinsert(Module.patternConfigList, DODGE_CLASSIC);
    tinsert(Module.patternConfigList, PARRY_CLASSIC);
    tinsert(Module.patternConfigList, BLOCK_VALUE_CLASSIC);

    tinsert(Module.patternConfigList, SPELL_DAMAGE_CLASSIC);
    tinsert(Module.patternConfigList, SPELL_CRITICAL_CLASSIC);
    tinsert(Module.patternConfigList, SPELL_HIT_CLASSIC);
    tinsert(Module.patternConfigList, SPELL_PENETRATION_CLASSIC);

    tinsert(Module.patternConfigList, HEALING_CLASSIC);

    tinsert(Module.patternConfigList, SKILL_INCREASE_CLASSIC);

    tinsert(Module.patternConfigList, TEMP_STAT_INCREASE_CLASSIC);
  else
    tinsert(Module.patternConfigList, ATTACK_POWER);
    tinsert(Module.patternConfigList, PHYSICAL_HIT);
    tinsert(Module.patternConfigList, DRUID_ATTACK_POWER);
    tinsert(Module.patternConfigList, PHYSICAL_CRITICAL);
    tinsert(Module.patternConfigList, PHYSICAL_EXPERTISE);
    tinsert(Module.patternConfigList, PHYSICAL_ARMOR_PENETRATION);
    tinsert(Module.patternConfigList, PHYSICAL_HASTE);
    tinsert(Module.patternConfigList, RANGED_ATTACK_POWER);
    tinsert(Module.patternConfigList, RANGED_CRITICAL);

    tinsert(Module.patternConfigList, SPELL_HIT);
    tinsert(Module.patternConfigList, SPELL_DAMAGE);
    tinsert(Module.patternConfigList, SPELL_CRITICAL);
    tinsert(Module.patternConfigList, SPELL_HASTE);
    tinsert(Module.patternConfigList, SPELL_PENETRATION);

    tinsert(Module.patternConfigList, HEALING);

    tinsert(Module.patternConfigList, DEFENSE);
    tinsert(Module.patternConfigList, DODGE);
    tinsert(Module.patternConfigList, PARRY);
    tinsert(Module.patternConfigList, BLOCK);
    tinsert(Module.patternConfigList, BLOCK_VALUE);
    tinsert(Module.patternConfigList, RESILIENCE);
  end

  tinsert(Module.patternConfigList, SPELL_DAMAGE_SPECIFIC_SCHOOL);

  tinsert(Module.patternConfigList, GENERIC_ENCHANT);
  tinsert(Module.patternConfigList, MINOR_SPEED);

  tinsert(Module.patternConfigList, ATIESH_AURA_CRIT);
  tinsert(Module.patternConfigList, ATIESH_SPELL_HEALING);

  tinsert(Module.patternConfigList, HEALTH_REGEN);
  tinsert(Module.patternConfigList, MANA_REGEN);
  tinsert(Module.patternConfigList, NEGATIVE_PARRY);
  tinsert(Module.patternConfigList, MISSILE_CRITICAL);
  tinsert(Module.patternConfigList, RANGED_ATTACK_SPEED);
  tinsert(Module.patternConfigList, SWIM_SPEED);
  tinsert(Module.patternConfigList, FLAT_SPELL_DAMAGE_REDUCTION);
  tinsert(Module.patternConfigList, STEALTH_DETECTION_SLIGHTLY);
  tinsert(Module.patternConfigList, STEALTH_DETECTION_MODERATELY);
  tinsert(Module.patternConfigList, STEALTH);
  tinsert(Module.patternConfigList, LOCKPICKING);
  tinsert(Module.patternConfigList, SKILL_INCREASE_ENDSWITH);
  tinsert(Module.patternConfigList, DISARM_DURATION);
  tinsert(Module.patternConfigList, INTERRUPT_DURATION);
end

function Module:OnEnable()
  UpdatePatternConfig();

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
