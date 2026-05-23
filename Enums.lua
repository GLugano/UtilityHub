---@enum EAutoBuyScope
local AUTO_BUY_SCOPE = {
  ACCOUNT = "account",
  CHARACTER = "character",
  CLASS = "class",
};

---@enum EnumCharacterGroup
local CHARACTER_GROUP = {
  UNGROUPED = 0,
  MAIN_ALT = 1,
  BANK = 2,
  CD = 3,
};

---@enum ECooldownGroupBy
local COOLDOWN_GROUP_BY = {
  CHARACTER = 1,
  TYPE = 2,
  -- READY_DATE = 3,
  -- READY_DATE_PROFESSION = 4,
};

---@class Enums
UtilityHub.Enums = {
  ---@type EAutoBuyScope
  AutoBuyScope = AUTO_BUY_SCOPE,
  ---@enum EAutoBuyScopeText
  AutoBuyScopeText = {
    [AUTO_BUY_SCOPE.ACCOUNT] = "Account",
    [AUTO_BUY_SCOPE.CHARACTER] = "Character",
    [AUTO_BUY_SCOPE.CLASS] = "Class",
  },
  CharacterGroup = CHARACTER_GROUP,
  ---@enum ECharacterGroupText
  CharacterGroupText = {
    [CHARACTER_GROUP.UNGROUPED] = "Ungrouped",
    [CHARACTER_GROUP.MAIN_ALT] = "Main/alt",
    [CHARACTER_GROUP.BANK] = "Bank",
    [CHARACTER_GROUP.CD] = "CD",
  },
  ---@enum EQuestType
  QuestType = {
    DUNGEON_NORMAL = 0,
    DUNGEON_HEROIC = 1,
    PROFESSION_COOKING = 2,
    PROFESSION_FISHING = 3,
    CONSORTIUM = 4,
    SHATARI_SKYGUARD = 5,
    OGRILA = 6,
    SHATARI_SKYGUARD_AND_OGRILA = 7,
    NETHERWING = 8,
    PVP = 9,
  },
  ---@enum EExpansion
  Expansions = {
    CLASSIC = 0,
    TBC = 1,
  },
  ---@enum EReputationStanding
  ReputationStanding = {
    HATED = 1,
    HOSTILE = 2,
    UNFRIENDLY = 3,
    NEUTRAL = 4,
    FRIENDLY = 5,
    HONORED = 6,
    REVERED = 7,
    EXALTED = 8,
  },
  ---@enum EPeriodicity
  Periodicity = {
    DAILY = 1,
    WEEKLY = 2,
    MONTHLY = 3,
  },
  ---@enum ESide
  Side = {
    ALLIANCE = "Alliance",
    HORDE = "Horde",
  },
  CooldownGroupBy = COOLDOWN_GROUP_BY,
  ---@enum ECooldownGroupByText
  CooldownGroupByText = {
    [COOLDOWN_GROUP_BY.CHARACTER] = "By Character",
    [COOLDOWN_GROUP_BY.TYPE] = "By Type",
    -- [COOLDOWN_GROUP_BY.READY_DATE] = "By Ready Date",
    -- [COOLDOWN_GROUP_BY.READY_DATE_PROFESSION] = "By Ready Date + Profession",
  },
};
