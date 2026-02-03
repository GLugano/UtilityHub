UHTradeItemButtonMixin = {};

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
  self:RegisterEvent("SPELLS_CHANGED");
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
  local item = self:GetAttribute('itemID');

  if (not item) then
    return;
  end

  local count = C_Item.GetItemCount(item, false, true);
  local itemTexture = select(10, C_Item.GetItemInfo(item));

  self.icon:SetTexture(itemTexture);

  if (count > 999) then
    self.Count:SetText("*");
  else
    self.Count:SetText(count);
  end

  if (count > 0) then
    self.icon:SetVertexColor(1.0, 1.0, 1.0);
  else
    self.icon:SetVertexColor(0.4, 0.4, 0.4);
  end

  self.Name:SetText('');
  self:UpdateCooldown();
end

function UHTradeItemButtonMixin:UpdateCooldown()
  ---@type number
  local modRate = 1.0;
  local Item = self:GetAttribute('itemID');
  local start, duration, enable = C_Container.GetItemCooldown(Item);

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

    if (not item) then
      return;
    end

    local itemLink = select(2, C_Item.GetItemInfo(item));

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

    ---@type integer|nil
    local bagFromBiggerStack = nil;
    ---@type integer|nil
    local slotFromBiggerStack = nil;
    ---@type integer
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
