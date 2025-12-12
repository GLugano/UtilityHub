local ADDON_NAME = ...;
---@type UtilityHub
local UH = LibStub('AceAddon-3.0'):GetAddon(ADDON_NAME);
local moduleName = 'Tooltip';
---@class Tooltip
---@diagnostic disable-next-line: undefined-field
local Module = UH:NewModule(moduleName);

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
---@field pattern? string
---@field IdentifyPattern? fun(self: PatternConfig, text: string): boolean
---@field FormatText fun(self: PatternConfig, text: string, prefix?: string): (string, PrefixConfig?)

---@type PatternConfig[]
Module.patternConfigList = {
  -- Skill
  {
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
  },
  {
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
  },
  -- Generic enchant stat
  {
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
  },
  -- Temp stat increase
  {
    pattern = "Increases (.-) by (%d+) for (%d+) sec.",
    FormatText = function(self, text)
      local statName, value, duration = text:match("Increases (.-) by (%d+) for (%d+) sec%.$");

      statName = Module.statNameConversionMap[statName] or statName;

      return string.format("+%s %s for %s seconds", value, statName, duration);
    end
  },
  -- Spell/Healing
  {
    pattern = "(critical strike with spells by (%d+))",
    FormatText = function(self, text)
      local crit = text:match("(%d+)");
      return string.format("+%s%% Spell Crit", crit);
    end
  },
  {
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
  },
  {
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
  },
  {
    pattern = "(%Improves your chance to hit with spells)",
    FormatText = function(self, text)
      local hit = text:match("(%d+)");
      return string.format("+%s%% Spell Hit", hit);
    end
  },
  {
    pattern = "Increases damage done by (%a+) spells",
    FormatText = function(self, text)
      local schoolType = text:match("by (%a+) spells?");
      local spellPower = text:match("(%d+)");
      return string.format("+%s %s Spell Power", spellPower, schoolType);
    end
  },
  {
    pattern = "Decreases the magical resistances",
    FormatText = function(self, text)
      local magicResist = text:match("(%d+)");
      return string.format("+%s Spell Penetration", magicResist);
    end
  },
  {
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
  },
  {
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
  },
  -- Physical
  {
    pattern = "(%Improves your chance to hit by)",
    FormatText = function(self, text)
      local hit = text:match("(%d+)");
      return string.format("+%s%% Physical Hit", hit);
    end
  },
  {
    pattern = "(critical strike by (%d+))",
    FormatText = function(self, text)
      local crit = text:match("(%d+)");
      return string.format("+%s%% Physical Crit", crit);
    end
  },
  {
    pattern = "+(%d+) Attack Power.$",
    FormatText = function(self, text)
      local ap = text:match("(%d+)");
      return string.format("+%s Attack Power", ap);
    end
  },
  {
    pattern = "+(%d+) ranged Attack Power.$",
    FormatText = function(self, text)
      local ap = text:match("(%d+)");
      return string.format("+%s Ranged Attack Power", ap);
    end
  },
  {
    pattern = "Attack Power in Cat, Bear, and Dire Bear forms only",
    FormatText = function(self, text)
      local ap = text:match("%+(%d+)");
      return string.format("+%s Feral Attack Power", ap);
    end
  },
  -- Defenses
  {
    pattern = "(%Increased Defense)",
    FormatText = function(self, text)
      local defense = text:match("(%d+)");
      return string.format("+%s Defense Skill", defense);
    end
  },
  {
    pattern = "(%Increases your chance to dodge)",
    FormatText = function(self, text)
      local dodge = text:match("(%d+)");
      return string.format("+%s%% Dodge", dodge);
    end
  },
  {
    pattern = "(%Increases your chance to parry)",
    FormatText = function(self, text)
      local parry = text:match("(%d+)");
      return string.format("+%s%% Parry", parry);
    end
  },
  {
    pattern = "(%Increases your chance to block)",
    FormatText = function(self, text)
      local block = text:match("(%d+)");
      return string.format("+%s%% Block", block);
    end
  },
  {
    pattern = "(%Increases the block value)",
    FormatText = function(self, text)
      local blockValue = text:match("(%d+)");
      return string.format("+%s Block Value", blockValue);
    end
  },
  -- Resources
  {
    pattern = "(%d+) mana per",
    FormatText = function(self, text)
      local regen = text:match("(%d+) mana per");
      return string.format("+%s MP5", regen);
    end
  },
  {
    pattern = "(%d+) health per",
    FormatText = function(self, text)
      local regen = text:match("(%d+) health per");
      return string.format("+%s HP5", regen);
    end
  },
  -- Procs
  {
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
  },
  -- Fixed
  {
    IdentifyPattern = function(self, text)
      return text == "Minor Speed Increase";
    end,
    FormatText = function(self, text)
      return "+8% Movement Speed";
    end
  },
};
Module.statNameConversionMap = {
  Health = "HP",
  Mana = "MP",
};

Module.itemRefTooltipHooked = false;
Module.gameTooltipHooked = false;

local function IdentifyPattern(patternConfig, text)
  if (not text or #text == 0) then
    return nil;
  end

  if (patternConfig.IdentifyPattern) then
    return patternConfig:IdentifyPattern(text);
  else
    return text:match(patternConfig.pattern);
  end
end

local function ExtractPrefix(text)
  local prefixes = {
    "^%(%d%) Set:",    -- Set bonus
    "^Equip:",         -- Equip
    "^Chance on hit:", -- Equip
    "^Use:",           -- Equip
  };

  for _, prefix in ipairs(prefixes) do
    local result = text:match(prefix);

    if (result) then
      return result;
    end
  end

  return nil;
end

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

function Module:OnEnable()
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
