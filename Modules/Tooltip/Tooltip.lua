local ADDON_NAME                      = ...;
---@type UtilityHub
local UH                              = LibStub('AceAddon-3.0'):GetAddon(ADDON_NAME);
local moduleName                      = 'Tooltip';
---@class Tooltip
---@diagnostic disable-next-line: undefined-field
local Module                          = UH:NewModule(moduleName);

local skills                          = {
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

-- Physical
local ATTACK_POWER_CLASSIC            = {
  pattern = "+(%d+) Attack Power.$",
  FormatText = function(self, text)
    local ap = text:match("(%d+)");
    return string.format("+%s Attack Power", ap);
  end
};

local ATTACK_POWER                    = {
  pattern = "Increases attack power by (%d+).$",
  FormatText = function(self, text)
    local ap = text:match("(%d+)");
    return string.format("+%s Attack Power", ap);
  end
};

local RANGED_ATTACK_POWER_CLASSIC     = {
  pattern = "+(%d+) ranged Attack Power.$",
  FormatText = function(self, text)
    local ap = text:match("(%d+)");
    return string.format("+%s Ranged Attack Power", ap);
  end
};

local PHYSICAL_CRITICAL_CLASSIC       = {
  pattern = "(critical strike by (%d+))",
  FormatText = function(self, text)
    local crit = text:match("(%d+)");
    return string.format("+%s%% Physical Crit", crit);
  end
};

local PHYSICAL_CRITICAL               = {
  pattern = {
    "Increases your critical strike rating by (%d+)",
    "Improves critical strike rating by (%d+)"
  },
  FormatText = function(self, text)
    local ap = text:match("(%d+)");
    return string.format("+%s Physical Crit Rating", ap);
  end
};

local PHYSICAL_HIT_CLASSIC            = {
  pattern = "(%Improves your chance to hit by)",
  FormatText = function(self, text)
    local hit = text:match("(%d+)");
    return string.format("+%s%% Physical Hit", hit);
  end
};

local PHYSICAL_HIT                    = {
  pattern = {
    "Increases your hit rating by (%d+)",
    "Improves hit rating by (%d+)"
  },
  FormatText = function(self, text)
    local ap = text:match("(%d+)");
    return string.format("+%s Physical Hit Rating", ap);
  end
};

local PHYSICAL_EXPERTISE              = {
  pattern = "Increases your expertise rating by (%d+).$",
  FormatText = function(self, text)
    local ap = text:match("(%d+)");
    return string.format("+%s Expertise Rating", ap);
  end
};

local DRUID_ATTACK_POWER_CLASSIC      = {
  pattern = "Attack Power in Cat, Bear, and Dire Bear forms only",
  FormatText = function(self, text)
    local ap = text:match("%+(%d+)");
    return string.format("+%s Feral Attack Power", ap);
  end
};

local DRUID_ATTACK_POWER              = {
  pattern = "Increases attack power by (%d+) in Cat, Bear, Dire Bear, and Moonkin forms only.",
  FormatText = function(self, text)
    local ap = text:match("(%d+)");
    return string.format("+%s Feral Attack Power", ap);
  end
};

-- Spell
local SPELL_PENETRATION_CLASSIC       = {
  pattern = "Decreases the magical resistances",
  FormatText = function(self, text)
    local magicResist = text:match("(%d+)");
    return string.format("+%s Spell Penetration", magicResist);
  end
};

local SPELL_PENETRATION               = {
  pattern = "Increases your spell penetration by (%d+)",
  FormatText = function(self, text)
    local magicResist = text:match("(%d+)");
    return string.format("+%s Spell Penetration", magicResist);
  end
};

local SPELL_DAMAGE_SPECIFIC_SCHOOL    = {
  pattern = "Increases damage done by (%a+) spells",
  FormatText = function(self, text)
    local schoolType = text:match("by (%a+) spells?");
    local spellPower = text:match("(%d+)");
    return string.format("+%s %s Spell Power", spellPower, schoolType);
  end
};

local SPELL_HIT_CLASSIC               = {
  pattern = "(%Improves your chance to hit with spells)",
  FormatText = function(self, text)
    local hit = text:match("(%d+)");
    return string.format("+%s%% Spell Hit", hit);
  end
};

local SPELL_HIT                       = {
  pattern = {
    "Increases your spell hit rating by (%d+)",
    "Improves spell hit rating by (%d+)"
  },
  FormatText = function(self, text)
    local hit = text:match("(%d+)");
    return string.format("+%s Spell Hit Rating", hit);
  end
};

local SPELL_DAMAGE_CLASSIC            = { -- +ATIESH AURA
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

local SPELL_DAMAGE                    = {
  pattern = "Increases damage and healing done by magical spells and effects by up to (%d+).",
  FormatText = function(self, text)
    local spellPower = text:match("by up to (%d+)");
    return string.format("+%s Spell Power", spellPower);
  end
};

local SPELL_CRITICAL_CLASSIC          = { -- Spell/Healing
  pattern = "(critical strike with spells by (%d+))",
  FormatText = function(self, text)
    local crit = text:match("spells by (%d+)");
    return string.format("+%s%% Spell Crit", crit);
  end
};

local SPELL_CRITICAL                  = { -- Spell/Healing
  pattern = {
    "Increases your spell critical strike rating by (%d+)",
    "Improves spell critical strike rating by (%d+)"
  },
  FormatText = function(self, text)
    local crit = text:match("by (%d+)");
    return string.format("+%s Spell Crit Rating", crit);
  end
};

-- Healing
local HEALING_CLASSIC                 = { -- + ATIESH AURA
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

local HEALING                         = {
  pattern = "Increases healing done by up to (%d+) and damage done by up to (%d+) for all magical spells and effects",
  FormatText = function(self, text, prefix)
    local healing = text:match("healing done by up to (%d+)");
    local damage = text:match("damage done by up to (%d+)");

    return string.format("+%s Healing Power\n%s +%s Spell Power", healing, prefix, damage);
  end
};

-- Resources
local MANA_REGEN                      = {
  pattern = "(%d+) mana per",
  FormatText = function(self, text)
    local regen = text:match("(%d+) mana per");
    return string.format("+%s MP5", regen);
  end
};

local HEALTH_REGEN                    = {
  pattern = "(%d+) health per",
  FormatText = function(self, text)
    local regen = text:match("(%d+) health per");
    return string.format("+%s HP5", regen);
  end
};

-- Fixed
local MINOR_SPEED                     = {
  IdentifyPattern = function(self, text)
    return text == "Minor Speed Increase";
  end,
  FormatText = function(self, text)
    return "+8% Movement Speed";
  end
};

-- Atiesh
local ATIESH_AURA_CRIT                = {
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

local ATIESH_SPELL_HEALING            = {
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
local TEMP_STAT_INCREASE_CLASSIC      = {
  pattern = "Increases (.-) by (%d+) for (%d+) sec.",
  FormatText = function(self, text)
    local statName, value, duration = text:match("Increases (.-) by (%d+) for (%d+) sec%.$");

    statName = Module.statNameConversionMap[statName] or statName;

    return string.format("+%s %s for %s seconds", value, statName, duration);
  end
};

local ATTACK_SPEED_INCREASE_CLASSIC   = {
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
local GENERIC_ENCHANT                 = {
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
local SKILL_INCREASE_CLASSIC          = {
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

local SKILL_INCREASE_ENDSWITH_CLASSIC = {
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
local DEFENSE_CLASSIC                 = {
  pattern = "(%Increased Defense)",
  FormatText = function(self, text)
    local defense = text:match("(%d+)");
    return string.format("+%s Defense Skill", defense);
  end
};

local DEFENSE                         = {
  pattern = "Increases defense rating by (%d+)",
  FormatText = function(self, text)
    local defense = text:match("by (%d+)");
    return string.format("+%s Defense Rating", defense);
  end
};

local DODGE_CLASSIC                   = {
  pattern = "(%Increases your chance to dodge)",
  FormatText = function(self, text)
    local dodge = text:match("(%d+)");
    return string.format("+%s%% Dodge", dodge);
  end
};

local DODGE                           = {
  pattern = "Increases your dodge rating by (%d+)",
  FormatText = function(self, text)
    local defense = text:match("by (%d+)");
    return string.format("+%s Dodge Rating", defense);
  end
};

local PARRY_CLASSIC                   = {
  pattern = "(%Increases your chance to parry)",
  FormatText = function(self, text)
    local parry = text:match("(%d+)");
    return string.format("+%s%% Parry", parry);
  end
};

local PARRY                           = {
  pattern = "Increases your parry rating by (%d+)",
  FormatText = function(self, text)
    local defense = text:match("by (%d+)");
    return string.format("+%s Parry Rating", defense);
  end
};

local BLOCK_CLASSIC                   = {
  pattern = "(%Increases your chance to block)",
  FormatText = function(self, text)
    local block = text:match("(%d+)");
    return string.format("+%s%% Block", block);
  end
};

local BLOCK                           = {
  pattern = "Increases your shield block rating by (%d+)",
  FormatText = function(self, text)
    local defense = text:match("by (%d+)");
    return string.format("+%s Block Rating", defense);
  end
};

local BLOCK_VALUE_CLASSIC             = {
  pattern = "(%Increases the block value)",
  FormatText = function(self, text)
    local blockValue = text:match("(%d+)");
    return string.format("+%s Block Value", blockValue);
  end
};

local BLOCK_VALUE                     = {
  pattern = "Increases the block value of your shield by (%d+)",
  FormatText = function(self, text)
    local defense = text:match("by (%d+)");
    return string.format("+%s Block Value", defense);
  end
};

local RESILIENCE                      = {
  pattern = "Improves your resilience rating by (%d+)",
  FormatText = function(self, text)
    local defense = text:match("by (%d+)");
    return string.format("+%s Resilience Rating", defense);
  end
};

---@type PatternConfig[]
Module.patternConfigList              = {};
Module.statNameConversionMap          = {
  Health = "HP",
  Mana = "MP",
};

---@type boolean
Module.itemRefTooltipHooked           = false;
---@type boolean
Module.gameTooltipHooked              = false;

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
    "^%(%d%) Set:",    -- Set bonus
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
  if (UH.IsClassic) then
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
    tinsert(Module.patternConfigList, SKILL_INCREASE_ENDSWITH_CLASSIC);

    tinsert(Module.patternConfigList, TEMP_STAT_INCREASE_CLASSIC);
  else
    tinsert(Module.patternConfigList, ATTACK_POWER);
    tinsert(Module.patternConfigList, PHYSICAL_HIT);
    tinsert(Module.patternConfigList, DRUID_ATTACK_POWER);
    tinsert(Module.patternConfigList, PHYSICAL_CRITICAL);
    tinsert(Module.patternConfigList, PHYSICAL_EXPERTISE);

    tinsert(Module.patternConfigList, SPELL_HIT);
    tinsert(Module.patternConfigList, SPELL_DAMAGE);
    tinsert(Module.patternConfigList, SPELL_CRITICAL);
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
end

function Module:OnEnable()
  UpdatePatternConfig();

  if (not Module.itemRefTooltipHooked) then
    Module.itemRefTooltipHooked = ItemRefTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItemEvent);
  end

  if (not Module.gameTooltipHooked) then
    Module.gameTooltipHooked = GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItemEvent);
  end
end

-- Events
UH.Events:RegisterCallback("OPTIONS_CHANGED", function(_, name)
  if (name ~= "simpleStatsTooltip") then
    return;
  end

  if (UH.db.global.options.simpleStatsTooltip) then
    UH:EnableModule("Tooltip");
  else
    UH:DisableModule("Tooltip");
  end
end);
