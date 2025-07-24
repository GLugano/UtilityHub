local ADDON_NAME, ADDON = ...
MDH = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceComm-3.0");
local version = GetBuildInfo();
local LDB = LibStub:GetLibrary("LibDataBroker-1.1");
MDH.LDBIcon = LibStub("LibDBIcon-1.0");
MDH.realmName = GetRealmName();
MDH.playerName = UnitName("player");
MDH.UTILS = LibStub("Utils-1.0");
MDH.UTILS.prefix = "MDH";
MDH.IsTBC = version == "2.5.2";

function MDH:InitVariables()
    self.db = LibStub("AceDB-3.0"):New("MDHdatabase", {
        global = {
            debugMode = false,
            minimapIcon = {
                hide = false
            },
            presets = {},
            whispers = {}
        }
    }, "Default");

    if (MDH.db.global.debugMode) then
        MDH.UTILS:ShowChatNotification("Executing InitVariables");
    end

    if (#MDH.db.global.presets > 0) then
        for i, preset in pairs(MDH.db.global.presets) do
            local shouldFixEssenceElemental = false;

            for j, value in pairs(preset.itemGroups) do
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
end

function MDH:SetupSlashCommands()
    SLASH_MailDistributionHelper1 = "/mdh"
    SlashCmdList.MailDistributionHelper = function(strParam)
        local fragments = {}
        for word in string.gmatch(strParam, "%S+") do
            table.insert(fragments, word)
        end

        local command = (fragments[1] or ""):trim();

        if (command == "") then
            MDH.UTILS:ShowChatNotification("Type /bh help for commands");
        elseif (command == "help") then
            MDH.UTILS:ShowChatNotification("Use the following parameters with /bh");
            print("- |cffddff00goldPerRun or gpr|r:");
            print("  If a value is informed, it will change the gold per run. If not, will show the current value.");
            print("- |cffddff00debug|r");
            print("  Toggle the debug mode");
        elseif (command == "goldPerRun" or command == "gpr") then
            local gpr = fragments[2];

            if (gpr == nil) then
                MDH.UTILS:ShowChatNotification("Current GoldPerRun: " .. MDH.db.global.goldPerRun .. "g");
                return;
            end

            MDH:UpdateGoldPerRun(gpr);
        elseif (command == "debug") then
            MDH.db.global.debugMode = (not MDH.db.global.debugMode);
            local debugText = MDH.db.global.debugMode and "ON" or "OFF";
            MDH.UTILS:ShowChatNotification("Debug mode " .. debugText);
        elseif (command == "item") then
            MDH.UTILS:PrintGetItemInfo(fragments[2]);
        else
            MDH.UTILS:ShowChatNotification("Command not found");
        end
    end
end

function MDH:CreateBroker()
    local data = {
        type = "data source",
        label = "BH",
        text = "Ready",
        icon = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Media\\Icons\\minimap-icon.blp",
        OnClick = function(self, button)
            if (button == "LeftButton") then
                if (IsShiftKeyDown()) then
                    MDH:ToggleHistoryFrame();
                else
                    MDH:ToggleMonitorFrame();
                end
            elseif (button == "RightButton") then
                if (IsShiftKeyDown()) then
                    MDH:ShowOptionsFrame();
                else
                    MDH:TogglePartyMemberFrames();
                    MDH.UTILS:ShowChatNotification((MDH.db.global.isPartyMemberVisible and "Showing" or "Hiding") ..
                                                       " Party Member Count Frames");
                end
            end
        end,
        OnEnter = function(self, button)
            -- GameTooltip:SetOwner(self, "ANCHOR_NONE")
            -- GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
            -- doUpdateMinimapButton = true;
            -- NIT:updateMinimapButton(GameTooltip, self);
            -- GameTooltip:Show()
        end,
        OnLeave = function(self, button)
            -- GameTooltip:Hide()
            -- if (GameTooltip.NITSeparator) then
            -- 	GameTooltip.NITSeparator:Hide();
            -- end
            -- if (GameTooltip.NITSeparator2) then
            -- 	GameTooltip.NITSeparator2:Hide();
            -- end
        end,
        OnTooltipShow = function(self)
            self:AddLine(ADDON_NAME);
            -- self:AddLine("|cFF9CD6DELeftClick|r |cffddff00to open/close the Reset Window|r");
        end
    };
    MDHLDB = LDB:NewDataObject("MDH", data);
    MDH.LDBIcon:Register(ADDON_NAME, MDHLDB, MDH.db.global.minimapIcon);
    -- Raise the frame level so users can see if it clashes with an existing icon and they can drag it.
    local frame = MDH.LDBIcon:GetMinimapButton(ADDON_NAME);
    if (frame) then
        frame:SetFrameLevel(9);
    end
end

-- Globals
-- Convert seconds to a readable format.
L = LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "enUS", true, true);
L["second"] = "second"; -- Second (singular).
L["seconds"] = "seconds"; -- Seconds (plural).
L["minute"] = "minute"; -- Minute (singular).
L["minutes"] = "minutes"; -- Minutes (plural).
L["hour"] = "hour"; -- Hour (singular).
L["hours"] = "hours"; -- Hours (plural).
L["day"] = "day"; -- Day (singular).
L["days"] = "days"; -- Days (plural).
L["year"] = "year"; -- Year (singular).
L["years"] = "years"; -- Years (plural).
L["secondMedium"] = "sec"; -- Second (singular).
L["secondsMedium"] = "secs"; -- Seconds (plural).
L["minuteMedium"] = "min"; -- Minute (singular).
L["minutesMedium"] = "mins"; -- Minutes (plural).
L["hourMedium"] = "hour"; -- Hour (singular).
L["hoursMedium"] = "hours"; -- Hours (plural).
L["dayMedium"] = "day"; -- Day (singular).
L["daysMedium"] = "days"; -- Days (plural).
L["yearMedium"] = "year"; -- Day (singular).
L["yearsMedium"] = "years"; -- Days (plural).
L["secondShort"] = "s"; -- Used in short timers like 1m30s (single letter only, usually the first letter of seconds).
L["minuteShort"] = "m"; -- Used in short timers like 1m30s (single letter only, usually the first letter of minutes).
L["hourShort"] = "h"; -- Used in short timers like 1h30m (single letter only, usually the first letter of hours).
L["dayShort"] = "d"; -- Used in short timers like 1d8h (single letter only, usually the first letter of days).
L["yearShort"] = "y"; -- Used in short timers like 1d8h (single letter only, usually the first letter of days).
L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME);

WHISPERS = {};

local eventsFrame = CreateFrame("Frame");
eventsFrame:RegisterEvent("ADDON_LOADED");
eventsFrame:RegisterEvent("MAIL_SHOW");
eventsFrame:RegisterEvent("TRADE_SHOW");
eventsFrame:RegisterEvent("TRADE_CLOSED");
eventsFrame:RegisterEvent("CHAT_MSG_WHISPER");
eventsFrame:RegisterEvent("MERCHANT_SHOW");
eventsFrame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE");
eventsFrame:SetScript('OnEvent', function(self, event, ...)
    local arg1, arg2 = ...;

    if (event == "ADDON_LOADED" and arg1 == ADDON_NAME) then
        eventsFrame:UnregisterEvent("ADDON_LOADED");

        MDH:InitVariables();
        MDH:SetupSlashCommands();
        -- MDH:CreateBroker();
        return;
    end

    if (event == "MAIL_SHOW") then
        MDH:CreateMailIconButtons();
        return;
    end

    if (event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" or event == "MAIL_CLOSED") then
        if (arg1 == 17) then
            MDH:CloseNewPresetFrame();
        end
        return;
    end

    if (event == "TRADE_SHOW") then
        C_Timer.After(0.5, function()
            MDH:CreateTradeDataFrame();
        end);
        return;
    end

    if (event == "TRADE_CLOSED") then
        MDH:CloseTradeDataFrame();
        return;
    end

    if (event == "CHAT_MSG_WHISPER") then
        MDH:SaveLastWhisper(arg1, arg2);
        return;
    end

    if (event == "MERCHANT_SHOW") then
        MDH:SearchAndBuyRares();
        return;
    end
end);

function MDH:SaveLastWhisper(message, sender)
    MDH.db.global.whispers[sender] = message;
    MDH:UpdateLastWhisperInFrame();
end
