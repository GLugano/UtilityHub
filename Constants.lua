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
    INVTYPE_HAND = "HANDSLOT",
    INVTYPE_FINGER = "FINGER0SLOT",
    INVTYPE_CLOAK = "BACKSLOT",
    INVTYPE_WEAPON = "ENCHSLOT_WEAPON",
    INVTYPE_SHIELD = "SHIELDSLOT",
    INVTYPE_2HWEAPON = "ENCHSLOT_2HWEAPON",
    INVTYPE_WEAPONMAINHAND = "ENCHSLOT_WEAPON",
    INVTYPE_WEAPONOFFHAND = "SHIELDSLOT",
    INVTYPE_HOLDABLE = "SHIELDSLOT",
  },
};

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
