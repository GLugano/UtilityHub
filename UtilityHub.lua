local addonName, addonTable = ...;
---@class UtilityHub
local UH = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceComm-3.0");
UH:SetDefaultModuleState(false);
UH.UTILS = LibStub("Utils-1.0");
UH.Compatibility = {};
UH.Helpers = {};
UH.prefix = "UH";

function UH.Helpers:Benchmark(label, func, level)
    if level == nil or type(level) ~= 'number' then level = 1; end
    -- level = level or 1;
    if level < 1 then
        local firstStr = string.format('|cffffd100-----Start Bench: |r|cff8080ff%s|r-----', label)
        UH.Helpers:ShowNotification(firstStr);
    end
    local startTime = GetTimePreciseSec();
    local results = { func() };
    local endTime = GetTimePreciseSec();
    local duration = endTime - startTime;

    local levelStr = '';
    if level > 0 then levelStr = string.rep("~", level) .. '>'; end

    local str = string.format("|cffffd100%sBench: |r|cff8080ff%s|r took |cffffd100%.4f|r ms", levelStr, label,
        duration * 1000)
    -- print(str)
    UH.Helpers:ShowNotification(str);
    return results, duration, startTime, endTime;
end

function UH:InitVariables()
    local version = C_AddOns.GetAddOnMetadata(addonName, "Version");

    self.db = LibStub("AceDB-3.0"):New("UHdatabase", {
        global = {
            version = version,
            debugMode = false,
            minimapIcon = {
                hide = false
            },
            presets = {},
            whispers = {},
            characters = {}
        }
    }, "Default");

    local name = UnitName("player");

    if (not UH.UTILS:ValueInTable(UH.db.global.characters, name)) then
        tinsert(UH.db.global.characters, name);
    end

    if (version ~= self.db.global.version) then
        UH:MigrateDB();
    end
end

function UH:MigrateDB()
    if (#UH.db.global.presets <= 0) then
        return;
    end

    for _, preset in pairs(UH.db.global.presets) do
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
    end
end

function UH:SetupSlashCommands()
    SLASH_UtilityHub1 = "/UH"
    SlashCmdList.UtilityHub = function(strParam)
        local fragments = {}
        for word in string.gmatch(strParam, "%S+") do
            table.insert(fragments, word)
        end

        local command = (fragments[1] or ""):trim();

        if (command == "") then
            UH.Helpers:ShowNotification("Type /UH help for commands");
        elseif (command == "help") then
            UH.Helpers:ShowNotification("Use the following parameters with /UH");
            print("- |cffddff00debug|r");
            print("  Toggle the debug mode");
        elseif (command == "debug") then
            UH.db.global.debugMode = (not UH.db.global.debugMode);
            local debugText = UH.db.global.debugMode and "ON" or "OFF";
            UH.Helpers:ShowNotification("Debug mode " .. debugText);
        else
            UH.Helpers:ShowNotification("Command not found");
        end
    end
end

function UH:OnInitialize()
    -- Migration code from the old name, should be
    if (MDHdatabase) then
        UHdatabase = MDHdatabase;
        MDHdatabase = nil;
    end

    UH:InitVariables();
    UH:SetupSlashCommands();

    UH.Compatibility.Baganator();
end
