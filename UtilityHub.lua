local ADDON_NAME, addonTable = ...;

---@class UtilityHub
UtilityHub = {
  Addon = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceComm-3.0"),
  Libs = {
    LDBIcon = LibStub("LibDBIcon-1.0"),
    AceDB = LibStub("AceDB-3.0"),
    AceConfigDialog = LibStub("AceConfigDialog-3.0"),
    AceConfig = LibStub("AceConfig-3.0"),
    LDB = LibStub:GetLibrary("LibDataBroker-1.1"),
    Utils = LibStub("Utils-1.0"),
  },
  ---@type Constants
  ---@diagnostic disable-next-line: missing-fields
  Constants = {},
  GameOptions = {
    defaults = {
      -- Tooltip
      simpleStatsTooltip = true,
      -- AutoBuy
      autoBuy = false,
      ---@type AutoBuyItem[]
      autoBuyList = {},
      -- Profession
      automaticEnchantFilter = true,
      -- Cooldowns
      cooldowns = true,
      cooldowsList = {},
      cooldownPlaySound = true,
      cooldownStartCollapsed = false,
      cooldownSync = false,
      cooldownSyncChannel = "",
      -- DailyQuests
      dailyQuests = false,
      -- Trade
      tradeExtraInfo = false,
      -- GraphicsSettings
      graphicsSettings = {
        originalValues = {},
        presetApplied = nil,
      },
      -- MouseRing
      mouseRing = {
        enabled = false,
        size = 34,
        shape = "thick_ring.tga",
        colorR = 1,
        colorG = 1,
        colorB = 1,
        useClassColor = true,
        hideBackground = false,
        showOutOfCombat = true,
        hideOnRightClick = false,
        -- Cast swipe
        castSwipeEnabled = true,
        castSwipeR = 1,
        castSwipeG = 1,
        castSwipeB = 1,
        castSwipeUseClassColor = false,
        -- GCD swipe
        gcdEnabled = true,
        gcdR = 1,
        gcdG = 1,
        gcdB = 1,
        gcdUseClassColor = false,
        -- Trail
        trailEnabled = false,
        trailR = 1,
        trailG = 0.8,
        trailB = 0.2,
        trailUseClassColor = false,
        trailDuration = 0.6,
      },
    },
    ---@type Option[]
    options = {},
    category = nil,
    subcategories = {},
    Register = function() end,
    OpenConfig = function(categoryOrPage)
      ---@type table|nil
      local category;
      ---@type string|nil
      local page;

      if (not categoryOrPage) then
        categoryOrPage = UtilityHub.GameOptions.category;
      end

      if (type(categoryOrPage) == "string") then
        page = categoryOrPage;
        category = UtilityHub.GameOptions.category;
      else
        category = categoryOrPage;
      end

      -- Invalid category
      if (not category or not category.GetID) then
        return;
      end

      Settings.OpenToCategory(category:GetID());

      if (page) then
        C_Timer.After(0.1, function()
          if (UtilityHub.OptionsCanvas) then
            local mainFrame = _G["UtilityHubCanvasFrame"];

            if (mainFrame and mainFrame.content) then
              UtilityHub.OptionsCanvas:ShowPage(mainFrame.content, page);
            end
          end
        end);
      end
    end,
  },
  Integration = {},
  ---@type Helpers
  ---@diagnostic disable-next-line: missing-fields
  Helpers = {},
  Flags = {
    ---@type boolean
    addonReady = false,
  },
  Textures = {
    ---@param nameOrTable string|TextureData
    ---@param texture Texture
    ApplyTexture = function(self, nameOrTable, texture)
      ---@type TextureData|nil
      local textureData = nil;

      if (type(nameOrTable) == "string") then
        textureData = self.list[nameOrTable];
      else
        textureData = nameOrTable;
      end

      if (not textureData) then
        return;
      end

      local parent = texture:GetParent();

      texture:SetTexture(textureData.texture);
      texture:SetSize(unpack(textureData.size));
      texture:SetTexCoord(unpack(textureData.coords));
      texture:SetPoint("TOPLEFT", parent, "TOPLEFT");
      texture:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT");
    end,
    ---@type TextureData[]
    list = {
      OrangeCogs = {
        texture = "Interface/Glues/CharacterSelect/UICharacterSelectGlues",
        size = { 16, 16 },
        coords = { 0.884, 0.913, 0.627, 0.654 },
      },
    },
  },
  Database = {},
  Events = CreateFromMixins(CallbackRegistryMixin),
  ---@param version string|nil
  ---@param oldVersion string|nil
  MigrateDB = function(self, version, oldVersion)
    if (version and oldVersion) then
      UtilityHub.Helpers.Notification:ShowNotification("Migrating DB version from " .. oldVersion .. " to " .. version);
    else
      UtilityHub.Helpers.Notification:ShowNotification("Migrating DB version - Forced action without any version change");
    end

    ---@type Preset
    local presetModule = UtilityHub.Addon:GetModule("Preset");

    ---@type MailPreset[]
    local presets = UtilityHub.Database.global.presets;

    if (#presets > 0) then
      for _, preset in pairs(presets) do
        local shouldFixEssenceElemental = false;

        for j, _ in pairs(preset.itemGroups) do
          if (j == "Essence") then
            shouldFixEssenceElemental = true;
          end
        end

        if (shouldFixEssenceElemental) then
          local newItemGroups = {};

          for key, value in pairs(preset.itemGroups) do
            if (key == "Essence") then
              newItemGroups["EssenceElemental"] = value;
            else
              newItemGroups[key] = value;
            end
          end

          preset.itemGroups = newItemGroups;
        end

        if (not preset.id) then
          preset.id = presetModule:GetNextID();
        end

        if (not preset.itemType) then
          preset.itemType = {};
        end
      end
    end

    if (not UtilityHub.Database.global.options) then
      UtilityHub.Database.global.options = UtilityHub.GameOptions.defaults;
    end

    if (UtilityHub.Database.global.options.autoBuyList) then
      local needsMigration = false;

      -- Check if old format (array of strings)
      if (#UtilityHub.Database.global.options.autoBuyList > 0 and type(UtilityHub.Database.global.options.autoBuyList[1]) == "string") then
        needsMigration = true;
      end

      if (needsMigration) then
        local newList = {};

        -- Convert old autoBuyList strings to new format
        for _, itemLink in ipairs(UtilityHub.Database.global.options.autoBuyList) do
          tinsert(newList, {
            itemLink = itemLink,
            quantity = 1,
          });
        end

        UtilityHub.Database.global.options.autoBuyList = newList;
        UtilityHub.Helpers.Notification:ShowNotification("Migrated AutoBuy list to new format");
      end
    else
      UtilityHub.Database.global.options.autoBuyList = UtilityHub.GameOptions.defaults.autoBuyList or {};
    end

    -- Migrate autoRestockList to unified autoBuyList
    if (UtilityHub.Database.global.options.autoRestockList and #UtilityHub.Database.global.options.autoRestockList > 0) then
      for _, restockItem in ipairs(UtilityHub.Database.global.options.autoRestockList) do
        -- Check if item already exists in autoBuyList
        local itemID = tonumber(string.match(restockItem.itemLink, "item:(%d+):"));
        local exists = false;

        for _, buyItem in ipairs(UtilityHub.Database.global.options.autoBuyList) do
          local buyItemID = tonumber(string.match(buyItem.itemLink, "item:(%d+):"));
          if (buyItemID == itemID) then
            exists = true;
            break;
          end
        end

        if (not exists) then
          tinsert(UtilityHub.Database.global.options.autoBuyList, {
            itemLink = restockItem.itemLink,
            quantity = restockItem.targetQuantity or 20,
          });
        end
      end

      -- Clear autoRestockList after migration
      UtilityHub.Database.global.options.autoRestockList = nil;
      UtilityHub.Helpers.Notification:ShowNotification("Merged Auto-Restock items into AutoBuy list");
    end

    if (UtilityHub.Database.global.characters) then
      for index, value in ipairs(UtilityHub.Database.global.characters) do
        if (type(value) == "string") then
          local name = UtilityHub.Database.global.characters[index];

          if (name == UnitName("player")) then
            local race = select(2, UnitRace("player"));
            local className = select(2, UnitClass("player"));

            UtilityHub.Database.global.characters[index] = {
              name = name,
              race = race,
              className = className,
              group = nil,
            };
          else
            UtilityHub.Database.global.characters[index] = {
              name = name,
              race = nil,
              className = nil,
              group = nil,
            };
          end
        end
      end
    end

    if (UtilityHub.Database.global.options.cooldowns == nil) then
      UtilityHub.Database.global.options.cooldowns = UtilityHub.GameOptions.defaults.cooldowns;
    end

    if (not UtilityHub.Database.global.options.cooldowsList) then
      UtilityHub.Database.global.options.cooldowsList = {};
    end

    if (not UtilityHub.Database.global.options.mouseRing) then
      local defaults = UtilityHub.GameOptions.defaults.mouseRing;
      UtilityHub.Database.global.options.mouseRing = CopyTable(defaults);
    end

    if (UtilityHub.Database.global.options.automaticEnchantFilter == nil) then
      UtilityHub.Database.global.options.automaticEnchantFilter = UtilityHub.GameOptions.defaults.automaticEnchantFilter;
    end

    UtilityHub.Helpers.Notification:ShowNotification("Migration complete");
  end
};

UtilityHub.Addon:SetDefaultModuleState(false);
