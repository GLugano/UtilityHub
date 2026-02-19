local moduleName = 'DailyQuests';
---@class DailyQuests
local Module = UtilityHub.Addon:NewModule(moduleName);

---@class Quest
---@field questID number
---@field questName string
---@field type EQuestType
---@field periodicity number
---@field expansion EExpansion
---@field GetRequirements? fun(): QuestRequirements | nil

---@class QuestRequirements
---@field questID? number
---@field profession? string
---@field factions? QuestRequirementFaction[]

---@class QuestRequirementFaction
---@field factionID number
---@field standingID number

---@class QuestDBTable
---@field requirementsOK table<number, boolean>
---@field complete table<number, boolean>
---@field data Quest[]

---@class QuestDBMetatable
---@field GetQuestsByType fun(self: QuestDB, type: EQuestType, expansion: EExpansion): Quest[]
---@field GetQuestByID fun(self: QuestDB, questID: number): Quest|nil
---@field GetQuestRequirements fun(self: QuestDB, questID: number): QuestRequirements|nil, Quest|nil

---@class QuestDB : QuestDBTable & QuestDBMetatable

---@class RequirementValidationError
---@field currentLevel number|nil
---@field currentSide string|nil
---@field currentSkillRank number|nil
---@field factions table|nil
---@field level number|nil
---@field notFound boolean|nil
---@field questID number|nil
---@field side ESide|nil
---@field skillName string|nil
---@field skillRank number|nil

---@class RequirementValidation
---@field pass boolean
---@field error RequirementValidationError[]

---@type QuestDBTable
local questDBTable = {
  requirementsOK = {},
  complete = {},
  data = {
    ------------------------------------- TBC -------------------------------------
    -- Daily - Normal
    {
      questID = 11389,
      questName = "Wanted: Arcatraz Sentinels",
      type = UtilityHub.Enums.QuestType.DUNGEON_NORMAL,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11371,
      questName = "Wanted: Coilfang Myrmidons",
      type = UtilityHub.Enums.QuestType.DUNGEON_NORMAL,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11376,
      questName = "Wanted: Malicious Instructors",
      type = UtilityHub.Enums.QuestType.DUNGEON_NORMAL,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11383,
      questName = "Wanted: Rift Lords",
      type = UtilityHub.Enums.QuestType.DUNGEON_NORMAL,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11364,
      questName = "Wanted: Shattered Hand Centurions",
      type = UtilityHub.Enums.QuestType.DUNGEON_NORMAL,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11500,
      questName = "Wanted: Sisters of Torment",
      type = UtilityHub.Enums.QuestType.DUNGEON_NORMAL,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11385,
      questName = "Wanted: Sunseeker Channelers",
      type = UtilityHub.Enums.QuestType.DUNGEON_NORMAL,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11387,
      questName = "Wanted: Tempest-Forge Destroyers",
      type = UtilityHub.Enums.QuestType.DUNGEON_NORMAL,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },

    -- Daily - Heroic
    {
      questID = 11369,
      questName = "Wanted: A Black Stalker Egg",
      type = UtilityHub.Enums.QuestType.DUNGEON_HEROIC,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11384,
      questName = "Wanted: A Warp Splinter Clipping",
      type = UtilityHub.Enums.QuestType.DUNGEON_HEROIC,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11382,
      questName = "Wanted: Aeonus's Hourglass",
      type = UtilityHub.Enums.QuestType.DUNGEON_HEROIC,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11363,
      questName = "Wanted: Bladefist's Seal",
      type = UtilityHub.Enums.QuestType.DUNGEON_HEROIC,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11362,
      questName = "Wanted: Keli'dan's Feathered Stave",
      type = UtilityHub.Enums.QuestType.DUNGEON_HEROIC,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11375,
      questName = "Wanted: Murmur's Whisper",
      type = UtilityHub.Enums.QuestType.DUNGEON_HEROIC,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11354,
      questName = "Wanted: Nazan's Riding Crop",
      type = UtilityHub.Enums.QuestType.DUNGEON_HEROIC,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11386,
      questName = "Wanted: Pathaleon's Projector",
      type = UtilityHub.Enums.QuestType.DUNGEON_HEROIC,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11373,
      questName = "Wanted: Shaffar's Wondrous Pendant",
      type = UtilityHub.Enums.QuestType.DUNGEON_HEROIC,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11378,
      questName = "Wanted: The Epoch Hunter's Head",
      type = UtilityHub.Enums.QuestType.DUNGEON_HEROIC,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11374,
      questName = "Wanted: The Exarch's Soul Gem",
      type = UtilityHub.Enums.QuestType.DUNGEON_HEROIC,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11372,
      questName = "Wanted: The Headfeathers of Ikiss",
      type = UtilityHub.Enums.QuestType.DUNGEON_HEROIC,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11368,
      questName = "Wanted: The Heart of Quagmirran",
      type = UtilityHub.Enums.QuestType.DUNGEON_HEROIC,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11388,
      questName = "Wanted: The Scroll of Skyriss",
      type = UtilityHub.Enums.QuestType.DUNGEON_HEROIC,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11499,
      questName = "Wanted: The Signet Ring of Prince Kael'thas",
      type = UtilityHub.Enums.QuestType.DUNGEON_HEROIC,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11370,
      questName = "Wanted: The Warlord's Treatise",
      type = UtilityHub.Enums.QuestType.DUNGEON_HEROIC,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },

    -- Professions - Cooking
    {
      questID = 11380,
      questName = "Manalicious",
      type = UtilityHub.Enums.QuestType.PROFESSION_COOKING,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11377,
      questName = "Revenge is Tasty",
      type = UtilityHub.Enums.QuestType.PROFESSION_COOKING,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11381,
      questName = "Soup for the Soul",
      type = UtilityHub.Enums.QuestType.PROFESSION_COOKING,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11379,
      questName = "Super Hot Stew",
      type = UtilityHub.Enums.QuestType.PROFESSION_COOKING,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },

    -- Professions - Fishing
    {
      questID = 11666,
      questName = "Bait Bandits",
      type = UtilityHub.Enums.QuestType.PROFESSION_FISHING,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11665,
      questName = "Crocolisks in the City",
      type = UtilityHub.Enums.QuestType.PROFESSION_FISHING,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11669,
      questName = "Felblood Fillet",
      type = UtilityHub.Enums.QuestType.PROFESSION_FISHING,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11668,
      questName = "Shrimpin' Ain't Easy",
      type = UtilityHub.Enums.QuestType.PROFESSION_FISHING,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11667,
      questName = "The One That Got Away",
      type = UtilityHub.Enums.QuestType.PROFESSION_FISHING,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },

    -- Consortium
    {
      questID = 9884,
      questName = "Membership Benefits",
      type = UtilityHub.Enums.QuestType.CONSORTIUM,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.MONTHLY,
    },
    {
      questID = 9885,
      questName = "Membership Benefits",
      type = UtilityHub.Enums.QuestType.CONSORTIUM,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.MONTHLY,
    },
    {
      questID = 9886,
      questName = "Membership Benefits",
      type = UtilityHub.Enums.QuestType.CONSORTIUM,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.MONTHLY,
    },
    {
      questID = 9887,
      questName = "Membership Benefits",
      type = UtilityHub.Enums.QuestType.CONSORTIUM,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.MONTHLY,
    },

    -- Sha'tari Skyguard
    {
      questID = 11008,
      questName = "Fires Over Skettis",
      type = UtilityHub.Enums.QuestType.SHATARI_SKYGUARD,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },
    {
      questID = 11085,
      questName = "Escape from Skettis",
      type = UtilityHub.Enums.QuestType.SHATARI_SKYGUARD,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
    },

    -- Ogri'la
    {
      questID = 11080,
      questName = "The Relic's Emanation",
      type = UtilityHub.Enums.QuestType.OGRILA,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
      GetRequirements = function()
        return { questID = 11058 };
      end
    },
    {
      questID = 11051,
      questName = "Banish More Demons",
      type = UtilityHub.Enums.QuestType.OGRILA,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
      GetRequirements = function()
        return { questID = 11026 };
      end
    },

    -- Sha'tari Skyguard and Ogri'la
    {
      questID = 11023,
      questName = "Bomb Them Again!",
      type = UtilityHub.Enums.QuestType.OGRILA,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
      GetRequirements = function()
        return { questID = 11010 };
      end
    },
    {
      questID = 11066,
      questName = "Wrangle More Aether Rays!",
      type = UtilityHub.Enums.QuestType.OGRILA,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
      GetRequirements = function()
        return { questID = 11065 };
      end
    },
    -- NETHERWING
    -- NEUTRAL
    {
      questID = 11020,
      questName = "A Slow Death",
      type = UtilityHub.Enums.QuestType.NETHERWING,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
      GetRequirements = function()
        return {
          factions = {
            { factionID = 1015, standingID = UtilityHub.Enums.ReputationStanding.NEUTRAL },
          },
        };
      end
    },
    {
      questID = 11015,
      questName = "Netherwing Crystals",
      type = UtilityHub.Enums.QuestType.NETHERWING,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
      GetRequirements = function()
        return {
          factions = {
            { factionID = 1015, standingID = UtilityHub.Enums.ReputationStanding.NEUTRAL },
          },
        };
      end
    },
    {
      questID = 11035,
      questName = "The Not-So-Friendly Skies...",
      type = UtilityHub.Enums.QuestType.NETHERWING,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
      GetRequirements = function()
        return {
          factions = {
            { factionID = 1015, standingID = UtilityHub.Enums.ReputationStanding.NEUTRAL },
          },
        };
      end
    },
    {
      questID = 11018,
      questName = "Nethercite Ore",
      type = UtilityHub.Enums.QuestType.NETHERWING,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
      GetRequirements = function()
        return {
          profession = "Mining:350",
          factions = {
            { factionID = 1015, standingID = UtilityHub.Enums.ReputationStanding.NEUTRAL },
          },
        };
      end
    },
    {
      questID = 11017,
      questName = "Netherdust Pollen",
      type = UtilityHub.Enums.QuestType.NETHERWING,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
      GetRequirements = function()
        return {
          profession = "Herbalism:350",
          factions = {
            { factionID = 1015, standingID = UtilityHub.Enums.ReputationStanding.NEUTRAL },
          },
        };
      end
    },
    {
      questID = 11016,
      questName = "Nethermine Flayer Hide",
      type = UtilityHub.Enums.QuestType.NETHERWING,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
      GetRequirements = function()
        return {
          profession = "Skinning:350",
          factions = {
            { factionID = 1015, standingID = UtilityHub.Enums.ReputationStanding.NEUTRAL },
          },
        };
      end
    },

    -- Friendly
    {
      questID = 11076,
      questName = "Picking Up The Pieces...",
      type = UtilityHub.Enums.QuestType.NETHERWING,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
      GetRequirements = function()
        return {
          factions = {
            { factionID = 1015, standingID = UtilityHub.Enums.ReputationStanding.FRIENDLY },
          },
        };
      end
    },
    {
      questID = 11077,
      questName = "Dragons are the Least of Our Problems",
      type = UtilityHub.Enums.QuestType.NETHERWING,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
      GetRequirements = function()
        return {
          factions = {
            { factionID = 1015, standingID = UtilityHub.Enums.ReputationStanding.FRIENDLY },
          },
        };
      end
    },
    {
      questID = 11055,
      questName = "The Booterang: A Cure For The Common Worthless Peon",
      type = UtilityHub.Enums.QuestType.NETHERWING,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
      GetRequirements = function()
        return {
          factions = {
            { factionID = 1015, standingID = UtilityHub.Enums.ReputationStanding.FRIENDLY },
          },
        };
      end
    },

    -- Honored
    {
      questID = 11086,
      questName = "Disrupting the Twilight Portal",
      type = UtilityHub.Enums.QuestType.NETHERWING,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
      GetRequirements = function()
        return {
          factions = {
            { factionID = 1015, standingID = UtilityHub.Enums.ReputationStanding.HONORED },
          },
        };
      end
    },

    -- Revered
    {
      questID = 11101,
      questName = "The Deadliest Trap Ever Laid", -- Aldor
      type = UtilityHub.Enums.QuestType.NETHERWING,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
      GetRequirements = function()
        return {
          factions = {
            { factionID = 1015, standingID = UtilityHub.Enums.ReputationStanding.REVERED },
            { factionID = 932,  standingID = UtilityHub.Enums.ReputationStanding.FRIENDLY },
          },
          questID = 11100, -- Commander Arcus
        };
      end
    },
    {
      questID = 11097,
      questName = "The Deadliest Trap Ever Laid", -- Scryer
      type = UtilityHub.Enums.QuestType.NETHERWING,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
      GetRequirements = function()
        return {
          factions = {
            { factionID = 1015, standingID = UtilityHub.Enums.ReputationStanding.REVERED },
            { factionID = 934,  standingID = UtilityHub.Enums.ReputationStanding.FRIENDLY },
          },
          questID = 11095, -- Commander Hobb
        };
      end
    },

    -- PVP
    {
      questID = 10110,
      questName = "Hellfire Fortifications", -- Horde
      type = UtilityHub.Enums.QuestType.PVP,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
      GetRequirements = function()
        return {
          level = 55,
          side = UtilityHub.Enums.Side.HORDE,
          questID = 10124, -- Forward Base: Reaver's Fall
        };
      end
    },
    {
      questID = 10106,
      questName = "Hellfire Fortifications", -- Alliance
      type = UtilityHub.Enums.QuestType.PVP,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
      GetRequirements = function()
        return {
          level = 55,
          side = UtilityHub.Enums.Side.ALLIANCE,
          questID = 10483, -- Ill Omens
        };
      end
    },
    {
      questID = 11503,
      questName = "Enemies, Old and New", -- Horde
      type = UtilityHub.Enums.QuestType.PVP,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
      GetRequirements = function()
        return {
          side = UtilityHub.Enums.Side.HORDE,
          level = 64,
          factions = {
            { factionID = 941, standingID = UtilityHub.Enums.ReputationStanding.NEUTRAL },
          },
        };
      end,
    },
    {
      questID = 11502,
      questName = "In Defense of Halaa", -- Alliance
      type = UtilityHub.Enums.QuestType.PVP,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
      GetRequirements = function()
        return {
          side = UtilityHub.Enums.Side.ALLIANCE,
          level = 64,
          factions = {
            { factionID = 978, standingID = UtilityHub.Enums.ReputationStanding.NEUTRAL },
          },
        };
      end,
    },
    {
      questID = 11506,
      questName = "Spirits of Auchindoun", -- Horde
      type = UtilityHub.Enums.QuestType.PVP,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
      GetRequirements = function()
        return {
          side = UtilityHub.Enums.Side.HORDE,
          level = 62,
        };
      end,
    },
    {
      questID = 11505,
      questName = "Spirits of Auchindoun", -- Alliance
      type = UtilityHub.Enums.QuestType.PVP,
      expansion = UtilityHub.Enums.Expansions.TBC,
      periodicity = UtilityHub.Enums.Periodicity.DAILY,
      GetRequirements = function()
        return {
          side = UtilityHub.Enums.Side.ALLIANCE,
          level = 62,
        };
      end,
    },
  },
};

---@type QuestDB
Module.QuestDB = setmetatable(
  questDBTable,
  {
    ---@type QuestDBMetatable
    __index = {
      GetQuestsByType = function(self, type, expansion)
        local quests = {};

        for _, quest in ipairs(self.data) do
          if (quest.type == type and quest.expansion == expansion) then
            tinsert(quests, quest);
          end
        end

        return quests;
      end,
      GetQuestByID = function(self, questID)
        for _, quest in ipairs(self.data) do
          if (quest.questID == questID) then
            return quest;
          end
        end

        return nil;
      end,
      GetQuestRequirements = function(self, questID)
        local quest = self:GetQuestByID(questID);

        if (not quest) then
          return nil, nil;
        end

        if (quest.GetRequirements) then
          return quest:GetRequirements(), quest;
        end

        if (quest.expansion == UtilityHub.Enums.Expansions.TBC) then
          if (quest.type == UtilityHub.Enums.QuestType.DUNGEON_HEROIC or quest.type == UtilityHub.Enums.QuestType.DUNGEON_NORMAL) then
            return { level = 70 }, quest;
          elseif (quest.type == UtilityHub.Enums.QuestType.PROFESSION_COOKING) then
            return { level = 70, profession = "Cooking:275" }, quest;
          elseif (quest.type == UtilityHub.Enums.QuestType.PROFESSION_FISHING) then
            return { level = 70, profession = "Fishing:1" }, quest;
          elseif (quest.type == UtilityHub.Enums.QuestType.SHATARI_SKYGUARD) then
            return { level = 70, questID = 11098 }, quest;
          end
        end

        return nil, quest;
      end
    }
  }
);

Module.CollapsedGroups = {};

local DAY_IN_SECONDS = 24 * 60 * 60;
local WEEK_IN_SECONDS = 24 * 60 * 60 * 7;
---@return string "Converted time"
---@return boolean "If its ready"
---@return table "RGB"
local function GetRemainingTime(quest)
  ---@param rgb BasicRGB
  ---@return BasicRGB
  function NormalizeRGB(rgb)
    return { r = rgb.r / 255, g = rgb.g / 255, b = rgb.b / 255 };
  end

  local isQuestComplete = false;

  if (quest.isQuestVariationGroup) then
    isQuestComplete = Module.QuestDB.complete[quest.quests[1].questID];
  else
    isQuestComplete = Module.QuestDB.complete[quest.questID];
  end

  if (not isQuestComplete) then
    return "Ready", true, NormalizeRGB({ r = 16, g = 179, b = 16 });
  end

  local seconds = nil;

  if (quest.type == UtilityHub.Enums.QuestType.CONSORTIUM) then
    local now   = GetServerTime();
    local month = tonumber(date("%m", now)) or 0;
    local year  = tonumber(date("%Y", now));
    local t     = {
      year = year,
      month = month + 1,
      day = 1,
      hour = 0,
      min = 0,
      sec = 0,
      isdst = false,
    };

    seconds     = time(t) - GetServerTime();
  else
    seconds = C_DateAndTime.GetSecondsUntilDailyReset();
  end

  if (seconds >= DAY_IN_SECONDS) then
    local days = math.floor(seconds / DAY_IN_SECONDS);
    return days .. (days == 1 and " day" or " days"), false, NormalizeRGB({ r = 255, g = 255, b = 255 });
  end

  local hours = math.floor(seconds / 3600);
  local minutes = math.floor((seconds % 3600) / 60);
  local seconds = seconds % 60;
  local rgb = { r = 252, g = 186, b = 3 };

  if (hours < 12) then
    rgb = { r = 255, g = 71, b = 71 };
  end

  return string.format("%02d:%02d:%02d", hours, minutes, seconds), false, NormalizeRGB(rgb);
end

---@param requirements QuestRequirements|nil
---@return boolean
---@return RequirementValidation[]|nil
function ValidateRequirements(requirements)
  local validators = {
    quest = function(requirements)
      if (not requirements.questID) then
        return true;
      end

      if (requirements.questID and not C_QuestLog.IsQuestFlaggedCompleted(requirements.questID)) then
        return false, { questID = requirements.questID };
      end

      return true;
    end,
    profession = function(requirements)
      if (not requirements.profession) then
        return true;
      end

      local skillName = requirements.profession:match("(%a+)");
      local skillRank = tonumber(requirements.profession:match("(%d+)"));
      local professionFound = false;

      for i = 1, GetNumSkillLines() do
        local skillNameLoop, _, _, skillRankLoop = GetSkillLineInfo(i);

        if (skillName == skillNameLoop) then
          professionFound = true;

          if (skillRankLoop < skillRank) then
            return false,
                {
                  skillName = skillName,
                  skillRank = skillRank,
                  notFound = false,
                  currentSkillRank = skillRankLoop,
                };
          end
        end
      end

      -- Didnt find the profession
      if (not professionFound) then
        return false,
            {
              skillName = skillName,
              skillRank = skillRank,
              notFound = true,
              currentSkillRank = nil,
            };
      end

      return true;
    end,
    reputation = function(requirements)
      function GetFactionStandingID(factionID)
        for i = 1, GetNumFactions() do
          local _, _, standingID, _, _, _, _, _, _, _, _, _, _, factionIDLoop = GetFactionInfo(i);

          if (factionID == factionIDLoop) then
            return standingID;
          end
        end

        return nil;
      end

      if (not requirements.factions or #requirements.factions == 0) then
        return true;
      end

      local errors = {};

      for _, faction in ipairs(requirements.factions) do
        local standingID = GetFactionStandingID(faction.factionID);

        if (standingID) then
          if (faction.standingID < standingID) then
            tinsert(errors, {
              factionID = faction.factionID,
              standingID = faction.standingID,
              currentStandingID = standingID,
              notFound = false,
            });
          end
        else
          tinsert(errors, {
            factionID = faction.factionID,
            standingID = faction.standingID,
            notFound = true,
          });
        end
      end

      -- Didnt find the faction
      if (#errors > 0) then
        return false, { factions = errors };
      end

      return true;
    end,
    side = function(requirements)
      if (not requirements.side) then
        return true;
      end

      local currentSide = UnitFactionGroup("player");

      if (requirements.side ~= UnitFactionGroup("player")) then
        return false, { side = requirements.side, currentSide = currentSide };
      end

      return true;
    end,
    level = function(requirements)
      if (not requirements.level) then
        return true;
      end

      local currentLevel = UnitLevel("player");

      if (requirements.level > currentLevel) then
        return false, { level = requirements.level, currentLevel = currentLevel };
      end

      return true;
    end
  };

  -- No requirements, so pass
  if (not requirements) then
    return true;
  end

  local errors = {};
  local errorCount = 0;

  for _, fn in pairs(validators) do
    local pass, validationResult = fn(requirements);
    tinsert(errors, { pass = pass, error = validationResult });

    if (not pass) then
      errorCount = errorCount + 1;
    end
  end

  return errorCount == 0, errors;
end

Module.Ticker = C_Timer.NewTicker(1, function()
  if (not Module.Frame or not Module.Frame:IsShown()) then
    return;
  end

  local dataProvider = Module.Frame.ScrollBox:GetDataProvider();

  if (not dataProvider) then
    return;
  end

  for _, frame in ipairs(Module.Frame.ScrollBox:GetFrames()) do
    if (frame.Timer) then
      frame.Timer:Update();
    end
  end
end);

function Module:SaveFlagChanges()
  UtilityHub.Database.char.complete = Module.QuestDB.complete or {};
  UtilityHub.Database.char.requirementsOK = Module.QuestDB.requirementsOK or {};
end

function Module:LoadFlags()
  Module.QuestDB.complete = UtilityHub.Database.char.complete or {};
  Module.QuestDB.requirementsOK = UtilityHub.Database.char.requirementsOK or {};
end

function Module:UpdateFlags()
  UtilityHub.Database.char.lastDailyQuestCheck = GetServerTime();

  for _, value in ipairs(Module.QuestDB.data) do
    Module:UpdateFlagsByID(value.questID);
  end
end

---@param questID number
---@return Quest|nil
function Module:UpdateFlagsByID(questID)
  ---@type QuestRequirements | nil
  local requirements, quest = Module.QuestDB:GetQuestRequirements(questID);

  if (quest) then
    local pass, errors = ValidateRequirements(requirements);

    Module.QuestDB.complete[questID] = C_QuestLog.IsQuestFlaggedCompleted(questID);
    Module.QuestDB.requirementsOK[questID] = pass;
  end

  Module:SaveFlagChanges();

  return quest;
end;

---@param questID number
---@return number
function Module:UpdateFlagsByNonDaily(questID)
  local updatedQuestsCount = 0;

  for _, quest in ipairs(Module.QuestDB.data) do
    local requirements = Module.QuestDB:GetQuestRequirements(quest.questID);

    if (requirements and requirements.questID == questID) then
      Module:UpdateFlagsByID(quest.questID);
      updatedQuestsCount = updatedQuestsCount + 1;
    end
  end

  return updatedQuestsCount;
end

---@param factionID number
function Module:UpdateFlagsByFaction(factionID)
  ---@param requirements QuestRequirements
  ---@return boolean
  function RequirementsIncludeFaction(requirements)
    if (requirements.factions and #requirements.factions > 0) then
      for _, faction in ipairs(requirements.factions) do
        if (faction.factionID == factionID) then
          return true;
        end
      end
    end

    return false;
  end

  for _, quest in ipairs(Module.QuestDB.data) do
    local requirements = Module.QuestDB:GetQuestRequirements(quest.questID);

    if (requirements) then
      if (RequirementsIncludeFaction(requirements)) then
        Module:UpdateFlagsByID(quest.questID);
      end
    end
  end
end

function Module:CheckIfRefreshIsNeeded()
  local lastCheck = UtilityHub.Database.char.lastDailyQuestCheck;

  if (not lastCheck) then
    return true;
  end

  local lastReset = GetServerTime() + C_DateAndTime.GetSecondsUntilDailyReset() - DAY_IN_SECONDS;

  if (lastReset > lastCheck) then
    return true;
  end

  lastReset = GetServerTime() + C_DateAndTime.GetSecondsUntilWeeklyReset() - WEEK_IN_SECONDS;

  if (lastReset > lastCheck) then
    return true;
  end

  local now   = GetServerTime();
  local month = tonumber(date("%m", now));
  local year  = tonumber(date("%Y", now));

  local t     = {
    year = year,
    month = month,
    day = 1,
    hour = 0,
    min = 0,
    sec = 0,
    isdst = false,
  };

  -- Considering that reset is always day 1
  lastReset   = time(t);

  if (lastReset > lastCheck) then
    return true;
  end

  return false;
end

-- Frames
function Module:CreateDailyQuestsFrame()
  local MIN_WIDTH = 220;
  local MIN_HEIGHT = 180;
  local DEFAULT_WIDTH = 350;
  local DEFAULT_HEIGHT = 350;

  local frame = CreateFrame("Frame", nil, UIParent, "SettingsFrameTemplate");
  Module.Frame = frame;
  frame:SetResizable(true);
  frame:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT);
  frame:Hide();

  local savedSize = UtilityHub.Database.global.dailyQuestsFrameSize;
  if (savedSize) then
    frame:SetSize(savedSize.width, savedSize.height);
  else
    frame:SetSize(DEFAULT_WIDTH, DEFAULT_HEIGHT);
  end
  local savedPosition = UtilityHub.Database.global.dailyQuestsFramePosition;

  if (UtilityHub.Database.global.dailyQuestsFramePosition) then
    frame:SetPoint(
      savedPosition.point,
      frame:GetParent(),
      savedPosition.relativePoint,
      savedPosition.x,
      savedPosition.y
    );
  else
    frame:SetPoint("CENTER");
  end

  frame.NineSlice.Text:SetText("Repetable Quests");
  UtilityHub.Libs.Utils:AddMovableToFrame(frame, function(pos)
    UtilityHub.Database.global.dailyQuestsFramePosition = pos;
  end);

  local resizeHandle = CreateFrame("Button", nil, frame);
  resizeHandle:SetSize(16, 16);
  resizeHandle:SetPoint("BOTTOMRIGHT", -4, 4);
  resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");
  resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight");
  resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down");
  resizeHandle:SetScript("OnMouseDown", function(self, button)
    if (button == "LeftButton") then
      frame:StartSizing("BOTTOMRIGHT");
    end
  end);
  resizeHandle:SetScript("OnMouseUp", function(self, button)
    frame:StopMovingOrSizing();
    local w, h = frame:GetSize();
    UtilityHub.Database.global.dailyQuestsFrameSize = { width = math.floor(w), height = math.floor(h) };
    Module:UpdateDailyQuestsFrameList();
  end);

  local content = CreateFrame("Frame", nil, frame);
  frame.Content = content;
  content:SetWidth(frame:GetSize());
  content:SetPoint("TOPLEFT", 15, -25);
  content:SetPoint("BOTTOMRIGHT", -5, 7);

  frame.ScrollBar = CreateFrame("EventFrame", nil, content, "MinimalScrollBar");
  frame.ScrollBar:SetPoint("TOPRIGHT", -10, -5);
  frame.ScrollBar:SetPoint("BOTTOMRIGHT", 0, 5);

  frame.ScrollBox = CreateFrame("Frame", nil, content, "WowScrollBoxList");
  frame.ScrollBox:SetPoint("TOPLEFT", 2, -4);
  frame.ScrollBox:SetPoint("BOTTOMRIGHT", frame.ScrollBar, "BOTTOMLEFT", -3, 0);

  local function UpdateScrollBoxAnchor()
    frame.ScrollBox:ClearAllPoints();
    frame.ScrollBox:SetPoint("TOPLEFT", 2, -4);
    if (frame.ScrollBar:IsShown()) then
      frame.ScrollBox:SetPoint("BOTTOMRIGHT", frame.ScrollBar, "BOTTOMLEFT", -3, 0);
    else
      frame.ScrollBox:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -3, 0);
    end
  end

  frame.ScrollBar:HookScript("OnShow", UpdateScrollBoxAnchor);
  frame.ScrollBar:HookScript("OnHide", UpdateScrollBoxAnchor);

  local indent = 10;
  local padLeft = 0;
  local pad = 5;
  local spacing = 1;
  local view = CreateScrollBoxListTreeListView(indent, pad, pad, padLeft, pad, spacing);
  Module.View = view;

  view:SetElementFactory(function(factory, node)
    local elementData = node:GetData();

    if (elementData.group) then
      local function Initializer(button, node)
        if (not Module.CollapsedGroups[elementData.group]) then
          Module.CollapsedGroups[elementData.group] = node:IsCollapsed();
        end
        button.Label:SetText(elementData.group);
        button:SetCollapseState(Module.CollapsedGroups[elementData.group]);

        button:SetScript("OnClick", function(button)
          node:ToggleCollapsed();
          Module.CollapsedGroups[elementData.group] = node:IsCollapsed();
          button:SetCollapseState(node:IsCollapsed());
          PlaySound(SOUNDKIT.IG_MAINMENU_OPTION);
        end);
      end

      factory("TreeGroupButtonTemplate", Initializer);
    elseif (elementData.questName) then
      local function Initializer(button, node)
        button:SetPushedTextOffset(0, 0);
        button:SetHighlightAtlas("search-highlight");
        button:SetNormalFontObject(GameFontHighlight);
        button:SetText(elementData.questName);
        button.elementData = elementData;
        button:GetFontString():SetWordWrap(false);
        button:GetFontString():SetPoint("LEFT", 12, 0);
        button:GetFontString():SetPoint("RIGHT", -75, 0);
        button:GetFontString():SetJustifyH("LEFT");

        if (not button.Timer) then
          button.Timer = button:CreateFontString(nil, "OVERLAY", "GameFontNormal");
          button.Timer:SetPoint("LEFT", 50, 0);
          button.Timer:SetPoint("RIGHT", -6, 0);
          button.Timer:SetJustifyH("RIGHT");

          function button.Timer:Update()
            local parent = self:GetParent();
            local text, ready, rgb = GetRemainingTime(parent.elementData);
            self:SetText(text);
            self:SetTextColor(rgb.r, rgb.g, rgb.b);
          end
        end

        button.Timer:Update();

        node:SetCollapsed(Module.CollapsedGroups[elementData.group]);
      end
      factory("Button", Initializer);
    else
      factory("Frame");
    end
  end);

  view:SetElementExtentCalculator(function(dataIndex, node)
    local elementData = node:GetData();
    local baseElementHeight = 20;
    local categoryPadding = 5;

    if (elementData.questName) then
      return baseElementHeight;
    end

    if (elementData.group) then
      return baseElementHeight + categoryPadding;
    end

    return 0;
  end);

  ScrollUtil.InitScrollBoxListWithScrollBar(frame.ScrollBox, frame.ScrollBar, view);
  ScrollUtil.AddManagedScrollBarVisibilityBehavior(frame.ScrollBox, frame.ScrollBar);
end

function Module:UpdateDailyQuestsFrameList()
  ---@class DailyQuest
  ---@field groupName string
  ---@field questName string
  ---@field questID number
  ---@field type EQuestType

  ---@class DailyQuestGroup
  ---@field group string
  ---@field isQuestVariationGroup boolean
  ---@field type EQuestType
  ---@field quests DailyQuest[]

  ---@class DailyQuestsTable
  ---@field data DailyQuestGroup[]

  ---@class DailyQuestMetatable
  ---@field InsertOrGetGroup fun(self: DailyQuestList, group: DailyQuestGroup): DailyQuestGroup
  ---@field ToTreeDataProvider fun(self: DailyQuestList): table

  ---@type DailyQuestsTable
  local groupsTable = {
    data = {},
  };
  ---@class DailyQuestList : DailyQuestsTable & DailyQuestMetatable
  local groups = setmetatable(groupsTable, {
    ---@type DailyQuestMetatable
    __index = {
      InsertOrGetGroup = function(self, group)
        for _, loopGroup in ipairs(self.data) do
          if (loopGroup.group == group.group) then
            return loopGroup;
          end
        end

        tinsert(self.data, group);

        return group;
      end,
      ToTreeDataProvider = function(self)
        local dataProvider = CreateTreeDataProvider();

        for _, groupOrNode in pairs(self.data) do
          if (groupOrNode.isQuestVariationGroup and groupOrNode.quests[1]) then
            -- As it is a QuestVariationGroup, just by checking the first requirement should be enough
            if (Module.QuestDB.requirementsOK[groupOrNode.quests[1].questID]) then
              dataProvider:Insert({
                groupName = nil,
                questName = groupOrNode.group,
                type = groupOrNode.type,
                quests = groupOrNode.quests,
                isQuestVariationGroup = groupOrNode.isQuestVariationGroup,
              });
            end
          else
            local quests = {};

            for _, quest in pairs(groupOrNode.quests) do
              if (Module.QuestDB.requirementsOK[quest.questID]) then
                tinsert(quests, quest);
              end
            end

            -- Only creates the parent node if there at least 1 valid child
            if (#quests > 0) then
              local groupDataNode = dataProvider:Insert({ group = groupOrNode.group });

              for _, quest in ipairs(quests) do
                groupDataNode:Insert(quest);
              end
            end
          end
        end

        return dataProvider;
      end,
    },
  });

  for _, quest in pairs(Module.QuestDB.data) do
    ---@type string|nil
    local groupName = nil;
    local questName = "";
    local isQuestVariationGroup = false;

    if (quest.type == UtilityHub.Enums.QuestType.DUNGEON_HEROIC) then
      questName = "Heroic Dungeon";
      isQuestVariationGroup = true;
    elseif (quest.type == UtilityHub.Enums.QuestType.DUNGEON_NORMAL) then
      questName = "Normal Dungeon";
      isQuestVariationGroup = true;
    elseif (quest.type == UtilityHub.Enums.QuestType.PROFESSION_COOKING) then
      questName = "Cooking";
      isQuestVariationGroup = true;
    elseif (quest.type == UtilityHub.Enums.QuestType.PROFESSION_FISHING) then
      questName = "Fishing";
      isQuestVariationGroup = true;
    elseif (quest.type == UtilityHub.Enums.QuestType.CONSORTIUM) then
      questName = quest.questName .. " (monthly)";
      isQuestVariationGroup = true;
    elseif (quest.type == UtilityHub.Enums.QuestType.SHATARI_SKYGUARD) then
      groupName = "Sha'tari Skyguard";
      questName = quest.questName;
    elseif (quest.type == UtilityHub.Enums.QuestType.OGRILA) then
      groupName = "Ogri'la";
      questName = quest.questName;
    elseif (quest.type == UtilityHub.Enums.QuestType.SHATARI_SKYGUARD_AND_OGRILA) then
      groupName = "Sha'tari Skyguard and Ogri'la";
      questName = quest.questName;
    elseif (quest.type == UtilityHub.Enums.QuestType.NETHERWING) then
      groupName = "Netherwing";
      questName = quest.questName;
    elseif (quest.type == UtilityHub.Enums.QuestType.PVP) then
      groupName = "PvP";
      questName = quest.questName;
    end

    if (groupName or isQuestVariationGroup) then
      local group = groups:InsertOrGetGroup({
        group = groupName or questName,
        isQuestVariationGroup = isQuestVariationGroup,
        type = quest.type,
        quests = {},
      });

      tinsert(group.quests, {
        groupName = groupName,
        questName = questName,
        questID = quest.questID,
        type = quest.type,
      });
    end
  end

  Module.Frame.ScrollBox:SetDataProvider(groups:ToTreeDataProvider());
end

function Module:ShowFrame()
  if (not Module:IsEnabled()) then
    UtilityHub.Helpers.Notification:ShowNotification(moduleName .. " module is not enabled");
    return;
  end

  if (Module:CheckIfRefreshIsNeeded() or true) then
    Module:UpdateFlags();
  end

  if (Module.Frame) then
    Module:UpdateDailyQuestsFrameList();
    Module.Frame:Show();
  end
end

function Module:HideFrame()
  if (Module.Frame) then
    Module.Frame:Hide();
  end
end

function Module:ToggleFrame()
  if (not Module.Frame) then
    return;
  end

  if (Module.Frame:IsShown()) then
    Module:HideFrame();
  else
    Module:ShowFrame();
  end
end

-- Life cycle
function Module:OnInitialize()
  Module:LoadFlags();

  if (not Module.Frame) then
    Module:CreateDailyQuestsFrame();
  end
end

-- Events
---@param questID number|string|nil
function Module:OnQuestTurnedIn(questID)
  if (type(questID) == "string") then
    questID = tonumber(questID);
  end

  if (not questID) then
    return;
  end

  local updatedQuestCount = 0;
  local questFound = Module:UpdateFlagsByID(questID);

  if (questFound) then
    updatedQuestCount = 1;
  else
    updatedQuestCount = Module:UpdateFlagsByNonDaily(questID);
  end

  if (updatedQuestCount > 0) then
    Module:UpdateDailyQuestsFrameList();
  end
end

EventRegistry:RegisterFrameEventAndCallback("QUEST_TURNED_IN", function(_, questID, ...)
  Module:OnQuestTurnedIn(questID);
end);

EventRegistry:RegisterFrameEventAndCallback("CHAT_MSG_COMBAT_FACTION_CHANGE", function(_, _, msg)
  local faction = msg:match("Reputation with (.+) increased by (%d+)");

  if (faction) then
    for i = 1, GetNumFactions() do
      local name, _, _, _, _, _, _, _, _, _, _, _, _, factionID = GetFactionInfo(i);

      if (name == faction) then
        Module:UpdateFlagsByFaction(factionID);
        return;
      end
    end
  end

  Module:UpdateDailyQuestsFrameList();
end);

EventRegistry:RegisterFrameEventAndCallback("PLAYER_LEVEL_UP", function()
  Module:UpdateFlags();
  Module:UpdateDailyQuestsFrameList();
end);

UtilityHub.Events:RegisterCallback("TOGGLE_DAILY_FRAME", function(_, name)
  Module:ToggleFrame();
end);

UtilityHub.Events:RegisterCallback("FORCE_DAILY_QUESTS_FLAG_UPDATE", function(_, questID, ...)
  questID = questID and tonumber(questID) or nil;

  if (questID) then
    Module:UpdateFlagsByID(questID);
  else
    Module:UpdateFlags();
  end

  Module:UpdateDailyQuestsFrameList();
end);
