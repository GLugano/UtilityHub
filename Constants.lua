local ADDON_NAME = ...;
local interfaceVersion = select(4, GetBuildInfo());

---@class Constants
UtilityHub.Constants = {
  --- Addon
  AddonName = ADDON_NAME,
  AddonPrefix = "UH",
  AddonVersion = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version"),
  AddonColorHex = "F5566EFF",

  --- Version
  IsClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) and (interfaceVersion < 20000),
  IsTBC = (interfaceVersion >= 20505) and (interfaceVersion < 30000),
  IsTBCorLater = interfaceVersion >= 20505,

  ---@type number[]
  AuctionHouseItemClass = {},

  ---@class AuctionHouseItemClassStructureSubClass
  ---@field subClassID number
  ---@field name string

  ---@class AuctionHouseItemClassStructureClass
  ---@field classID number
  ---@field name string
  ---@field subClasses AuctionHouseItemClassStructureSubClass[]

  ---@type AuctionHouseItemClassStructureClass[]
  AuctionHouseItemClassStructure = {},

  SlotValueToCraftSlotMap = {
    INVTYPE_CHEST = "CHESTSLOT",
    INVTYPE_ROBE = "CHESTSLOT",
    INVTYPE_FEET = "FEETSLOT",
    INVTYPE_WRIST = "WRISTSLOT",
    INVTYPE_HAND = "HANDSSLOT",
    INVTYPE_FINGER = "FINGER0SLOT",
    INVTYPE_CLOAK = "BACKSLOT",
    INVTYPE_WEAPON = "ENCHSLOT_WEAPON",
    INVTYPE_SHIELD = "SHIELDSLOT",
    INVTYPE_2HWEAPON = "ENCHSLOT_2HWEAPON",
    INVTYPE_WEAPONMAINHAND = "ENCHSLOT_WEAPON",
    INVTYPE_WEAPONOFFHAND = "SHIELDSLOT",
    INVTYPE_HOLDABLE = "SHIELDSLOT",
  },

  -- Bags
  BagIDs = {
    BACKPACK = 0,
    BAG_1 = 1,
    BAG_2 = 2,
    BAG_3 = 3,
    BAG_4 = 4,
    KEYRING = -2,
  },
};

--- AH
if (UtilityHub.Constants.IsClassic) then
  UtilityHub.Constants.AuctionHouseItemClass = {
    Enum.ItemClass.Weapon,
    Enum.ItemClass.Armor,
    Enum.ItemClass.Container,
    Enum.ItemClass.Consumable,
    Enum.ItemClass.Tradegoods,
    Enum.ItemClass.Projectile,
    Enum.ItemClass.Quiver,
    Enum.ItemClass.Recipe,
    Enum.ItemClass.Reagent,
    Enum.ItemClass.Miscellaneous,
    Enum.ItemClass.Questitem,
    Enum.ItemClass.Key,
  };
else
  UtilityHub.Constants.AuctionHouseItemClass = {
    Enum.ItemClass.Weapon,
    Enum.ItemClass.Armor,
    Enum.ItemClass.Container,
    Enum.ItemClass.Consumable,
    Enum.ItemClass.Tradegoods,
    Enum.ItemClass.Projectile,
    Enum.ItemClass.Quiver,
    Enum.ItemClass.Recipe,
    Enum.ItemClass.Gem,
    Enum.ItemClass.Miscellaneous,
    Enum.ItemClass.Questitem,
  };
end

for _, classID in ipairs(UtilityHub.Constants.AuctionHouseItemClass) do
  local className = C_Item.GetItemClassInfo(classID);
  local subclasses = { GetAuctionItemSubClasses(classID) };

  if (subclasses and #subclasses > 0) then
    local class = { name = className, classID = classID, subClasses = {} }
    tinsert(UtilityHub.Constants.AuctionHouseItemClassStructure, class);

    for _, subClassID in ipairs(subclasses) do
      local name = C_Item.GetItemSubClassInfo(classID, subClassID);

      tinsert(class.subClasses, { name = name, subClassID = subClassID });
    end
  end
end

--- Cooldowns/Professions
---@type Profession[]
UtilityHub.Constants.Cooldowns = {
  {
    id = 197,
    name = "Tailoring",
    spellIDs = { 3908, 3909, 3910, 12180, 26790 },
    cooldowns = {},
  },
  {
    id = 171,
    name = "Alchemy",
    spellIDs = { 2259, 3101, 3464, 11611, 28596 },
    cooldowns = {
      { internalID = 1, name = "Transmutes", spellList = {} },
    },
  },
  {
    id = 165,
    name = "Leatherworking",
    spellIDs = { 2108, 3104, 3811, 10662, 32549 },
    cooldowns = {},
  },
};

local professionTailoring = UtilityHub.Constants.Cooldowns[1];
local professionAlchemy = UtilityHub.Constants.Cooldowns[2];
local professionLeatherworking = UtilityHub.Constants.Cooldowns[3];

-- Still a cooldown in the tbc pre patch
tinsert(professionLeatherworking.cooldowns,
  {
    internalID = 2,
    name = "Refined Deeprock Salt",
    itemID = 15846,
    spellID = 19566,
  }
);

if (UtilityHub.Constants.IsClassic) then
  tinsert(professionTailoring.cooldowns, { internalID = 3, name = "Mooncloth", spellID = 18560 });

  local transmutes = professionAlchemy.cooldowns[1];

  if (transmutes) then
    tinsert(transmutes.spellList, { internalID = 4, name = "Arcanite Bar", spellID = 17187 });
    tinsert(transmutes.spellList, { internalID = 5, name = "Water to Air", spellID = 17562 });
    tinsert(transmutes.spellList, { internalID = 6, name = "Water to Undeath", spellID = 17564 });
    tinsert(transmutes.spellList, { internalID = 7, name = "Earth to Life", spellID = 17566 });
    tinsert(transmutes.spellList, { internalID = 8, name = "Earth to Water", spellID = 17561 });
    tinsert(transmutes.spellList, { internalID = 9, name = "Air to Fire", spellID = 17559 });
    tinsert(transmutes.spellList, { internalID = 10, name = "Life to Earth", spellID = 17565 });
    tinsert(transmutes.spellList, { internalID = 11, name = "Undeath to Water", spellID = 17563 });
    tinsert(transmutes.spellList, { internalID = 12, name = "Elemental Fire", spellID = 20761 });
    tinsert(transmutes.spellList, { internalID = 13, name = "Mithril to Truesilver", spellID = 11480 });
    tinsert(transmutes.spellList, { internalID = 14, name = "Iron to Gold", spellID = 11479 });
  end
elseif (UtilityHub.Constants.IsTBC) then
  tinsert(professionTailoring.cooldowns, { internalID = 15, name = "Shadowcloth", spellID = 36686 });
  tinsert(professionTailoring.cooldowns, { internalID = 16, name = "Spellcloth", spellID = 31373 });
  tinsert(professionTailoring.cooldowns, { internalID = 17, name = "Primal Mooncloth", spellID = 26751 });

  local transmutes = professionAlchemy.cooldowns[1];

  if (transmutes) then
    tinsert(transmutes.spellList, { internalID = 18, name = "Transmute: Primal Might", spellID = 29688 });
    tinsert(transmutes.spellList, { internalID = 19, name = "Transmute: Earthstorm Diamond", spellID = 32765 });
    tinsert(transmutes.spellList, { internalID = 20, name = "Transmute: Skyfire Diamond", spellID = 32766 });
    -- Air to
    tinsert(transmutes.spellList, { internalID = 21, name = "Transmute: Primal Air to Fire", spellID = 28566 });
    -- Earth to
    tinsert(transmutes.spellList, { internalID = 22, name = "Transmute: Primal Earth to Water", spellID = 28567 });
    tinsert(transmutes.spellList, { internalID = 23, name = "Transmute: Primal Earth to Life", spellID = 28585 });
    -- Fire to
    tinsert(transmutes.spellList, { internalID = 24, name = "Transmute: Primal Fire to Mana", spellID = 28583 });
    tinsert(transmutes.spellList, { internalID = 25, name = "Transmute: Primal Fire to Earth", spellID = 28568 });
    -- Life to
    tinsert(transmutes.spellList, { internalID = 26, name = "Transmute: Primal Life to Earth", spellID = 28584 });
    -- Mana to
    tinsert(transmutes.spellList, { internalID = 27, name = "Transmute: Primal Mana to Fire", spellID = 28582 });
    -- Shadow to
    tinsert(transmutes.spellList, { internalID = 28, name = "Transmute: Primal Shadow to Water", spellID = 28580 });
    -- Water to
    tinsert(transmutes.spellList, { internalID = 29, name = "Transmute: Primal Water to Air", spellID = 28569 });
    tinsert(transmutes.spellList, { internalID = 30, name = "Transmute: Primal Water to Shadow", spellID = 28581 });
  end
end
