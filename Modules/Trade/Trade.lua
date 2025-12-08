local ADDON_NAME = ...;
---@type UtilityHub
local UH = LibStub('AceAddon-3.0'):GetAddon(ADDON_NAME);
local moduleName = 'Trade';
---@class Trade
---@diagnostic disable-next-line: undefined-field
local Module = UH:NewModule(moduleName);
Module.whispers = {};
Module.TradeDataFrameRef = nil;
Module.Buttons = { Water = nil, Food = nil };

-- Need to be outside of OnInitialize to catch whispers while trade frame is not opened before
EventRegistry:RegisterFrameEventAndCallback("CHAT_MSG_WHISPER", function(_, text, name)
    Module:SaveLastWhisper(text, name);
end);

EventRegistry:RegisterFrameEventAndCallback("TRADE_SHOW", function()
    if (UH:GetModule("Trade"):IsEnabled()) then
        Module:ShowFrames();
    else
        ---@diagnostic disable-next-line: undefined-field
        UH:EnableModule("Trade");
    end
end);

function Module:OnInitialize()
    EventRegistry:RegisterFrameEventAndCallback("TRADE_CLOSED", function()
        Module:HideFrames();
    end);
end

function Module:OnEnable()
    if (UnitClass("player") == "Mage") then
        Module.Buttons.Water = Module:CreateItemButton("UHTradeWaterButton");
        Module.Buttons.Food = Module:CreateItemButton("UHTradeFoodButton", Module.Buttons.Water);
        Module:UpdateItemFromButtons();
    end

    Module:CreateTradeDataFrame();
    Module:ShowFrames();
end

function Module:SaveLastWhisper(message, sender)
    UH.db.global.whispers[sender] = message;
    Module:UpdateLastWhisperInFrame();
end

function Module:CreateTradeDataFrame()
    if (not TradeFrame or not TradeFrame:IsShown()) then
        return;
    end

    local name, server = UnitFullName("npc");
    server = server or GetRealmName();

    local frameWidth = 200;
    local frame = UH.UTILS.AceGUI:Create("Frame");
    Module.TradeDataFrameRef = frame;
    frame:Hide();
    frame:SetTitle("Trading with...");
    frame:SetLayout("Flow");
    frame:SetWidth(frameWidth);
    frame:SetHeight(330);
    frame:EnableResize(false);
    frame:ClearAllPoints();
    frame:SetPoint("TOPRIGHT", TradeFrame, "TOPRIGHT", 10 + frameWidth, 0);
    frame:SetCallback("OnClose", function(widget)
        UH.UTILS.AceGUI:Release(widget);
        Module.TradeDataFrameRef = nil;
    end);

    local _, englishClass = UnitClass("npc");

    CreateLabel(frame, name);
    CreateLabel(frame, "|cffffd100Server:|r " .. server);
    CreateLabel(frame, "|cffffd100Guild:|r " .. (GetGuildInfo("npc") or "-"));
    CreateLabel(frame, "|cffffd100Level:|r " .. UnitLevel("npc"));
    CreateLabel(frame, UnitRace("npc") .. " " .. UH.UTILS:GetClassColoredText(UnitClass("npc"), englishClass));

    local spacer = CreateLabel(frame);
    spacer:SetText(" ");
    spacer:SetHeight(10);

    local scrollFrameParent = UH.UTILS.AceGUI:Create("InlineGroup");
    scrollFrameParent:SetTitle("Last whisper:");
    scrollFrameParent:SetFullWidth(true);
    scrollFrameParent:SetFullHeight(true);
    frame:AddChild(scrollFrameParent);

    local scroll = UH.UTILS.AceGUI:Create("ScrollFrame");
    scroll:SetFullWidth(true);
    scroll:SetLayout("Flow");
    scrollFrameParent:AddChild(scroll);
    frame.LastWhisperScrollableRef = scroll;

    local label = CreateLabel(scroll, "-", 14);
    label:SetWidth(frameWidth - 60);
    label:SetFullHeight(true);

    function frame:UpdateWhisper()
        label:SetText(UH.db.global.whispers[name .. "-" .. server] or "-");
    end

    frame:UpdateWhisper();
end

function Module:HideFrames()
    if (Module.TradeDataFrameRef) then
        Module.TradeDataFrameRef:Hide();
    end

    if (Module.Buttons.Water) then
        Module.Buttons.Water:Hide();
    end

    if (Module.Buttons.Food) then
        Module.Buttons.Food:Hide();
    end
end

function Module:ShowFrames()
    if (Module.TradeDataFrameRef) then
        Module.TradeDataFrameRef:Show();
    end

    if (Module.Buttons.Water) then
        Module.Buttons.Water:Show();
    end

    if (Module.Buttons.Food) then
        Module.Buttons.Food:Show();
    end
end

function CreateLabel(frame, text, fontSize)
    local label = UH.UTILS.AceGUI:Create("Label");
    local fontPath, _, fontFlags = label.label:GetFont();
    label.label:SetFont(fontPath, fontSize or 16, fontFlags);
    label:SetText(text);
    label.label:SetWordWrap(true);
    label:SetFullWidth(true);
    frame:AddChild(label);

    return label;
end

function Module:UpdateLastWhisperInFrame()
    if (Module.TradeDataFrameRef) then
        Module.TradeDataFrameRef:UpdateWhisper();
    end
end

function Module:UpdateItemFromButtons()
    -- All lists are ordered by rank, descending sort
    local waterSpellIDs = { 10140, 10139, 10138, 6127, 5506, 5505, 5504 };
    local foodSpellIDs = { 28612, 10145, 10144, 6129, 990, 597, 587 };
    local waterItemIDs = { 8079, 8078, 8077, 3772, 2136, 2288, 5350 };
    local foodItemIDs = { 22895, 8076, 8075, 1487, 1114, 1113, 5349 };

    function UpdateItem(type, spellIDs, itemIDs)
        if (not Module.Buttons[type]) then
            return;
        end

        local itemID, spellID = Module:GetItemIDBy(spellIDs, itemIDs);

        if (not itemID or not spellID) then
            return;
        end

        Module.Buttons[type]:UpdateItem(itemID, spellID);
    end

    UpdateItem("Water", waterSpellIDs, waterItemIDs);
    UpdateItem("Food", foodSpellIDs, foodItemIDs);
end

function Module:GetItemIDBy(spells, items)
    for index, spellID in ipairs(spells) do
        ---@diagnostic disable-next-line: deprecated
        if (IsSpellKnown(spellID, false)) then
            return items[index], spellID;
        end
    end

    return nil, nil;
end

function Module:CreateItemButton(name, parent)
    local button = CreateFrame("Button", name, parent, "UHTradeItemButtonTemplate");
    button.ModuleRef = Module;
    button:RegisterForClicks("AnyUp");
    button:SetSize(36, 36);
    button:SetAttribute("IsEquipmentset", false);
    button:SetAttribute("IsMount", false);
    button:SetAttribute("shift-type1", "spell");

    if (parent) then
        button:SetPoint("TOPLEFT", parent, "TOPRIGHT", 10, 0);
    else
        button:SetPoint("BOTTOMLEFT", TradeFrame, "BOTTOMRIGHT", 10, 3);
    end

    function button:UpdateItem(itemID, spellID)
        button:SetAttribute("shift-spell1", spellID);
        button:SetAttribute("itemID", itemID);
        button:SetAttribute("spellID", spellID);
        self:UpdateState();
    end

    button:HookScript('OnClick', function()
        if (not IsShiftKeyDown()) then
            button:OnClickNotShift();
        end
    end);

    return button;
end

-- Mixins
UHTradeItemButtonMixin = {}
function UHTradeItemButtonMixin:OnLoad()
    self:RegisterEvent("ACTIONBAR_UPDATE_USABLE");
    self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN"); -- not updating cooldown from lua anymore, see SetActionUIButton
    self:RegisterEvent("SPELL_UPDATE_CHARGES");
    self:RegisterEvent("UPDATE_INVENTORY_ALERTS");
    self:RegisterEvent("PLAYER_TARGET_CHANGED");
    self:RegisterEvent("TRADE_SKILL_SHOW");
    self:RegisterEvent("TRADE_SKILL_CLOSE");
    self:RegisterEvent("PLAYER_ENTER_COMBAT");
    self:RegisterEvent("PLAYER_LEAVE_COMBAT");
    self:RegisterEvent("START_AUTOREPEAT_SPELL");
    self:RegisterEvent("STOP_AUTOREPEAT_SPELL");
    self:RegisterEvent("UNIT_INVENTORY_CHANGED");
    self:RegisterEvent("LEARNED_SPELL_IN_TAB");
    self:RegisterEvent("PET_STABLE_UPDATE");
    self:RegisterEvent("PET_STABLE_SHOW");
    self:RegisterUnitEvent("LOSS_OF_CONTROL_ADDED", "player");
    self:RegisterUnitEvent("LOSS_OF_CONTROL_UPDATE", "player");
    self:RegisterEvent("SPELL_UPDATE_ICON");
    self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW");
    self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE");
end

function UHTradeItemButtonMixin:OnEvent(event, ...)
    self:UpdateState();
end

function UHTradeItemButtonMixin:UpdateState()
    local Item = self:GetAttribute('itemID');

    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc,
    itemTexture, itemSellPrice = C_Item.GetItemInfo(Item);
    self.icon:SetTexture(itemTexture);

    local count = C_Item.GetItemCount(Item, false, true)
    if (count > 999) then
        self.Count:SetText("*");
    else
        self.Count:SetText(count)
    end

    if count > 0 then
        self.icon:SetVertexColor(1.0, 1.0, 1.0);
    else
        self.icon:SetVertexColor(0.4, 0.4, 0.4);
    end

    self.Name:SetText('');
    self:UpdateCooldown();
end

function UHTradeItemButtonMixin:UpdateCooldown()
    local start, duration, enable;
    local modRate = 1.0;

    local Item = self:GetAttribute('itemID');

    start, duration, enable = C_Container.GetItemCooldown(Item);

    if (self.cooldown.currentCooldownType ~= COOLDOWN_TYPE_NORMAL) then
        self.cooldown:SetEdgeTexture("Interface\\Cooldown\\edge");
        self.cooldown:SetSwipeColor(0, 0, 0);
        self.cooldown:SetHideCountdownNumbers(false);
        self.cooldown.currentCooldownType = COOLDOWN_TYPE_NORMAL;
    end

    CooldownFrame_Set(self.cooldown, start, duration, enable, false, modRate);
end

function UHTradeItemButtonMixin:OnEnter()
    if (IsShiftKeyDown()) then
        local spell = self:GetAttribute('spellID');

        if (not spell) then
            return;
        end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetSpellByID(spell);
    else
        local item = self:GetAttribute('itemID');
        local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
        itemEquipLoc, itemTexture, itemSellPrice = C_Item.GetItemInfo(item);

        if (not itemLink) then
            return;
        end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetHyperlink(itemLink);
    end

    GameTooltip:Show();
end

function UHTradeItemButtonMixin:OnLeave()
    GameTooltip:Hide();
end

function UHTradeItemButtonMixin:OnClickNotShift(...)
    if (not IsShiftKeyDown()) then
        local itemID = self:GetAttribute('itemID');

        if (not itemID) then
            return;
        end

        local emptyTradeSlot = nil;
        -- -1 to prevent the "Will not be traded" slot
        for tradeSlot = 1, (MAX_TRADE_ITEMS - 1) do
            if (not GetTradePlayerItemLink(tradeSlot)) then
                emptyTradeSlot = tradeSlot;
                break;
            end
        end

        if (emptyTradeSlot == nil) then
            return;
        end

        local bagFromBiggerStack = nil;
        local slotFromBiggerStack = nil;
        local stackSize = 0;

        for bag = 0, NUM_BAG_SLOTS do
            for slot = 1, C_Container.GetContainerNumSlots(bag) do
                local id = C_Container.GetContainerItemID(bag, slot);
                local containerInfo = C_Container.GetContainerItemInfo(bag, slot);

                if (containerInfo and id == itemID and not containerInfo.isLocked) then
                    if (containerInfo.stackCount == 20) then
                        C_Container.PickupContainerItem(bag, slot);
                        ClickTradeButton(emptyTradeSlot);
                        ClearCursor();
                        return;
                    elseif (containerInfo.stackCount > stackSize) then
                        stackSize = containerInfo.stackCount;
                        bagFromBiggerStack = bag;
                        slotFromBiggerStack = slot;
                    end
                end
            end
        end

        if (bagFromBiggerStack and slotFromBiggerStack) then
            C_Container.PickupContainerItem(bagFromBiggerStack, slotFromBiggerStack);
            ClickTradeButton(emptyTradeSlot);
            ClearCursor();
        end
    end
end

function UHTradeItemButtonMixin:OnUpdate()
    if (GameTooltip:IsOwned(self)) then
        local showSpell = IsShiftKeyDown() and self:GetAttribute("spellID");

        if (self._lastShowSpell ~= showSpell) then
            self._lastShowSpell = showSpell;
            GameTooltip:Hide();
            self:GetScript("OnEnter")(self);
        end
    end
end
