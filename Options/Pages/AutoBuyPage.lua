local ADDON_NAME = ...;

---@class AutoBuyPage
local AutoBuyPage = {};

---@type Frame|nil
local autoBuyListFrame = nil;

-- Returns display name and icon for an itemLink (both may be nil if not cached)
---@param itemLink ItemLink
---@return string|nil, number|string|nil
local function GetItemDisplay(itemLink)
  local name, _, _, _, _, _, _, _, _, icon = C_Item.GetItemInfo(itemLink);
  return name, icon;
end

-- Builds the inline-icon prefix string for a given icon (or empty string)
---@param icon number|string|nil
---@return string
local function IconStr(icon)
  if (not icon) then
    return "";
  end
  return "|T" .. icon .. ":14:14:0:0|t ";
end

---@return Frame
local function GetOrCreateEditDialog()
  if (_G["UtilityHubAutoBuyEditDialog"]) then
    return _G["UtilityHubAutoBuyEditDialog"];
  end

  local dialog = CreateFrame("Frame", "UtilityHubAutoBuyEditDialog", UIParent, "BasicFrameTemplate");
  dialog:SetSize(320, 195);
  dialog:SetPoint("CENTER");
  dialog:SetFrameStrata("DIALOG");
  dialog:SetMovable(true);
  dialog:EnableMouse(true);
  dialog:RegisterForDrag("LeftButton");
  dialog:SetScript("OnDragStart", dialog.StartMoving);
  dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing);
  dialog:Hide();

  -- Quantity row
  local qtyLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  qtyLabel:SetPoint("TOPLEFT", 15, -40);
  qtyLabel:SetText("Quantity:");

  local qtyInput = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate");
  qtyInput:SetSize(80, 20);
  qtyInput:SetPoint("LEFT", qtyLabel, "RIGHT", 10, 0);
  qtyInput:SetAutoFocus(false);
  qtyInput:SetNumeric(true);
  dialog.qtyInput = qtyInput;

  -- Scope label
  local scopeLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  scopeLabel:SetPoint("TOPLEFT", 15, -75);
  scopeLabel:SetText("Scope:");

  -- Radio buttons (Account / Character / Class)
  local SCOPES = {
    { key = UtilityHub.Enums.AutoBuyScope.ACCOUNT,   text = "Account" },
    { key = UtilityHub.Enums.AutoBuyScope.CHARACTER, text = "Character" },
    { key = UtilityHub.Enums.AutoBuyScope.CLASS,     text = "Class" },
  };

  dialog.scopeButtons = {};

  for i, scopeData in ipairs(SCOPES) do
    local radio = CreateFrame("CheckButton", nil, dialog, "UIRadioButtonTemplate");
    radio:SetPoint("TOPLEFT", scopeLabel, "BOTTOMLEFT", (i - 1) * 95, -5);
    radio:SetSize(16, 16);
    radio.scopeKey = scopeData.key;

    local radioLabel = radio:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    radioLabel:SetPoint("LEFT", radio, "RIGHT", 2, 0);
    radioLabel:SetText(scopeData.text);

    radio:SetScript("OnClick", function(self)
      for _, btn in ipairs(dialog.scopeButtons) do
        btn:SetChecked(btn == self);
      end

      if (self.scopeKey == UtilityHub.Enums.AutoBuyScope.CHARACTER) then
        dialog.scopeValueInput:SetText(UnitName("player") or "");
        dialog.scopeValueInput:SetEnabled(true);
        dialog.scopeValueLabel:SetAlpha(1);
      elseif (self.scopeKey == UtilityHub.Enums.AutoBuyScope.CLASS) then
        local _, classFile = UnitClass("player");
        dialog.scopeValueInput:SetText(classFile or "");
        dialog.scopeValueInput:SetEnabled(true);
        dialog.scopeValueLabel:SetAlpha(1);
      else
        dialog.scopeValueInput:SetText("");
        dialog.scopeValueInput:SetEnabled(false);
        dialog.scopeValueLabel:SetAlpha(0.5);
      end
    end);

    tinsert(dialog.scopeButtons, radio);
  end

  -- Scope value row
  local scopeValueLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  scopeValueLabel:SetPoint("TOPLEFT", 15, -128);
  scopeValueLabel:SetText("Value:");
  dialog.scopeValueLabel = scopeValueLabel;

  local scopeValueInput = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate");
  scopeValueInput:SetSize(200, 20);
  scopeValueInput:SetPoint("LEFT", scopeValueLabel, "RIGHT", 10, 0);
  scopeValueInput:SetAutoFocus(false);
  dialog.scopeValueInput = scopeValueInput;

  scopeValueInput:SetScript("OnEnter", function(self)
    local scope = UtilityHub.Enums.AutoBuyScope.ACCOUNT;

    for _, btn in ipairs(dialog.scopeButtons) do
      if (btn:GetChecked()) then
        scope = btn.scopeKey;
        break;
      end
    end

    if (scope == UtilityHub.Enums.AutoBuyScope.CLASS) then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:SetText("Class identifier (uppercase)");
      GameTooltip:AddLine("WARRIOR  PALADIN  HUNTER", 1, 1, 1, true);
      GameTooltip:AddLine("ROGUE  PRIEST  SHAMAN", 1, 1, 1, true);
      GameTooltip:AddLine("MAGE  WARLOCK  DRUID", 1, 1, 1, true);
      GameTooltip:Show();
    elseif (scope == UtilityHub.Enums.AutoBuyScope.CHARACTER) then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
      GameTooltip:SetText("Character name (exact)");
      GameTooltip:Show();
    end
  end);

  scopeValueInput:SetScript("OnLeave", function(self)
    if (GameTooltip:IsOwned(self)) then
      GameTooltip:Hide();
    end
  end);

  -- Save / Cancel buttons
  local cancelBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate");
  cancelBtn:SetText("Cancel");
  cancelBtn:SetSize(80, 22);
  cancelBtn:SetPoint("BOTTOMRIGHT", -15, 15);

  local saveBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate");
  saveBtn:SetText("Save");
  saveBtn:SetSize(80, 22);
  saveBtn:SetPoint("RIGHT", cancelBtn, "LEFT", -5, 0);
  dialog.saveBtn = saveBtn;
  cancelBtn:SetScript("OnClick", function()
    dialog:Hide();
  end);

  ---@param itemLink ItemLink
  ---@param currentData AutoBuyItem
  ---@param onSave fun(quantity: number, scope: EAutoBuyScope, scopeValue: string|nil)
  function dialog:Open(itemLink, currentData, onSave)
    local itemName = C_Item.GetItemInfo(itemLink) or itemLink;

    if (self.TitleText) then
      self.TitleText:SetText(itemName);
    end

    self.qtyInput:SetText(tostring(currentData.quantity or 1));

    local currentScope = currentData.scope or UtilityHub.Enums.AutoBuyScope.ACCOUNT;
    local currentScopeValue = currentData.scopeValue or "";

    for _, btn in ipairs(self.scopeButtons) do
      btn:SetChecked(btn.scopeKey == currentScope);
    end

    local isAccountScope = (currentScope == UtilityHub.Enums.AutoBuyScope.ACCOUNT);
    self.scopeValueInput:SetText(currentScopeValue);
    self.scopeValueInput:SetEnabled(not isAccountScope);
    self.scopeValueLabel:SetAlpha(isAccountScope and 0.5 or 1);

    self.saveBtn:SetScript("OnClick", function()
      local qty = tonumber(self.qtyInput:GetText());

      if (not qty or qty <= 0) then
        return;
      end

      local scope = UtilityHub.Enums.AutoBuyScope.ACCOUNT;

      for _, btn in ipairs(self.scopeButtons) do
        if (btn:GetChecked()) then
          scope = btn.scopeKey;
          break;
        end
      end

      local scopeValue = nil;

      if (scope ~= UtilityHub.Enums.AutoBuyScope.ACCOUNT) then
        local v = string.trim(self.scopeValueInput:GetText());
        if (v ~= "") then
          scopeValue = v;
        end
      end

      onSave(qty, scope, scopeValue);
      self:Hide();
    end);

    self:Show();
    self:Raise();
  end

  return dialog;
end

---@param parent Frame
---@return Frame
function AutoBuyPage:Create(parent)
  local frame = CreateFrame("Frame", "UtilityHubAutoBuyPage", parent);

  -- Title
  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
  title:SetPoint("TOPLEFT", 20, -20);
  title:SetText("AutoBuy Settings");

  -- Enable checkbox
  local enableCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate");
  enableCheckbox:SetSize(24, 24);
  enableCheckbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20);
  enableCheckbox:SetChecked(UtilityHub.Database.global.options.autoBuy);

  local enableLabel = enableCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal");
  enableLabel:SetPoint("LEFT", enableCheckbox, "RIGHT", 5, 0);
  enableLabel:SetText("Enabled");

  enableCheckbox:SetScript("OnClick", function(self)
    local checked = self:GetChecked();
    UtilityHub.Database.global.options.autoBuy = checked;
    UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "autoBuy", checked);
  end);

  enableCheckbox:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText("AutoBuy", 1, 1, 1);
    GameTooltip:AddLine(
      "Enable the functionality to autobuy specific limited stock items from vendors when the window is opened",
      nil,
      nil,
      nil,
      true
    );
    GameTooltip:Show();
  end);

  enableCheckbox:SetScript("OnLeave", function(self)
    if (GameTooltip:IsOwned(self)) then
      GameTooltip:Hide();
    end
  end);

  local framesHelper         = UtilityHub.GameOptions.framesHelper;

  -- Forward-declare so closures defined before the function bodies can capture them
  local RefreshList;
  local RefreshBagItems;

  -- ===== Collapsible Add Item section =====
  local ADD_COLLAPSED_HEIGHT = 26;
  local ADD_EXPANDED_HEIGHT  = 155;
  local addExpanded          = false;

  local addSection           = CreateFrame("Frame", nil, frame, "InsetFrameTemplate");
  addSection:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -15);
  addSection:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, 0);
  addSection:SetHeight(ADD_COLLAPSED_HEIGHT);

  -- Toggle header button
  local addToggle = CreateFrame("Button", nil, addSection);
  addToggle:SetHeight(22);
  addToggle:SetPoint("TOPLEFT", 2, -2);
  addToggle:SetPoint("TOPRIGHT", -2, -2);

  local addToggleText = addToggle:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  addToggleText:SetAllPoints();
  addToggleText:SetJustifyH("LEFT");
  addToggleText:SetText("[+] Add item");

  -- Content frame (hidden while collapsed)
  local addContent = CreateFrame("Frame", nil, addSection);
  addContent:SetPoint("TOPLEFT", addToggle, "BOTTOMLEFT", 0, -4);
  addContent:SetPoint("BOTTOMRIGHT", addSection, "BOTTOMRIGHT", 0, 0);
  addContent:Hide();

  -- Vertical divider at horizontal center of content
  local divider = addContent:CreateTexture(nil, "ARTWORK");
  divider:SetColorTexture(0.3, 0.3, 0.3, 0.8);
  divider:SetWidth(1);
  divider:SetPoint("TOP", addContent, "TOP", 0, -4);
  divider:SetPoint("BOTTOM", addContent, "BOTTOM", 0, 4);

  -- ---- Left pane: Type / Link ----
  local leftPane = CreateFrame("Frame", nil, addContent);
  leftPane:SetPoint("TOPLEFT", addContent, "TOPLEFT", 4, -4);
  leftPane:SetPoint("BOTTOMRIGHT", addContent, "BOTTOM", -6, 4);

  local leftLabel = leftPane:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  leftLabel:SetPoint("TOPLEFT", 0, 0);
  leftLabel:SetText("Type ID or drag link:");

  local addEditBox = CreateFrame("EditBox", nil, leftPane, "SearchBoxTemplate");
  addEditBox.Instructions:SetText("");
  addEditBox.searchIcon:Hide();
  addEditBox:SetTextInsets(0, 20, 0, 0);
  addEditBox:SetHeight(24);
  addEditBox:SetAutoFocus(false);
  addEditBox:SetHyperlinksEnabled(true);
  addEditBox:SetPoint("TOPLEFT", leftPane, "TOPLEFT", 0, -26);
  addEditBox:SetPoint("TOPRIGHT", leftPane, "TOPRIGHT", -56, -26);

  local addBtn = CreateFrame("Button", nil, leftPane, "UIPanelButtonTemplate");
  addBtn:SetText("Add");
  addBtn:SetSize(44, 24);
  addBtn:SetPoint("LEFT", addEditBox, "RIGHT", 8, 0);

  addEditBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus();
  end);

  addEditBox:SetScript("OnMouseUp", function()
    local _, _, itemLink = GetCursorInfo();
    if (itemLink) then
      addEditBox:SetText(itemLink);
    end
    ClearCursor();
  end);

  local function DoAddItem()
    local text = string.trim(addEditBox:GetText());

    if (#text == 0) then
      return;
    end

    local numericID = tonumber(text);

    -- Validate that it's either a numeric ID or an itemLink format
    if (not numericID and not string.match(text, "item:(%d+):")) then
      return;
    end

    addEditBox:SetText("");

    local function ProceedWithLink(link)
      if (not link) then return; end

      local newID = tonumber(string.match(link, "item:(%d+):"));
      if (not newID) then return; end

      -- Check for duplicate by comparing itemIDs
      local list = UtilityHub.Database.global.options.autoBuyList or {};

      for _, existingItem in ipairs(list) do
        if (existingItem.itemLink) then
          local existingID = tonumber(string.match(existingItem.itemLink, "item:(%d+):"));
          if (existingID == newID) then
            return;
          end
        end
      end

      local dialog = GetOrCreateEditDialog();
      dialog:Open(
        link,
        { quantity = 1, scope = UtilityHub.Enums.AutoBuyScope.ACCOUNT, scopeValue = nil },
        function(qty, scope, scopeValue)
          local currentList = UtilityHub.Database.global.options.autoBuyList or {};

          tinsert(currentList, {
            itemLink = link,
            quantity = qty,
            scope = scope,
            scopeValue = scopeValue,
          });

          UtilityHub.Database.global.options.autoBuyList = currentList;
          UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "autoBuyList", currentList);
          RefreshList();
          RefreshBagItems();
        end
      );
    end

    if (numericID) then
      -- Resolve asynchronously: works even if the item is not in the client cache yet
      UtilityHub.Helpers.Item:AsyncGetItemInfo(numericID, ProceedWithLink);
    else
      ProceedWithLink(text);
    end
  end

  addEditBox:SetScript("OnEnterPressed", function()
    addEditBox:ClearFocus();
    DoAddItem();
  end);

  addBtn:SetScript("OnClick", function()
    addEditBox:ClearFocus();
    DoAddItem();
  end);

  -- ---- Right pane: From Bag ----
  local rightPane = CreateFrame("Frame", nil, addContent);
  rightPane:SetPoint("TOPLEFT", addContent, "TOP", 6, -4);
  rightPane:SetPoint("BOTTOMRIGHT", addContent, "BOTTOMRIGHT", -4, 4);

  local rightLabel = rightPane:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  rightLabel:SetPoint("TOPLEFT", 0, 0);
  rightLabel:SetText("From Bag:");

  local fromBagRefreshBtn = CreateFrame("Button", nil, rightPane, "UIPanelButtonTemplate");
  fromBagRefreshBtn:SetSize(65, 20);
  fromBagRefreshBtn:SetPoint("TOPRIGHT", 0, 2);
  fromBagRefreshBtn:SetText("Refresh");

  local fromBagListFrame = framesHelper:CreateCustomList(
    "AutoBuyFromBagList",
    rightPane,
    nil,
    {
      SortComparator = function(a, b)
        local nameA = (a.itemLink and C_Item.GetItemInfo(a.itemLink)) or "";
        local nameB = (b.itemLink and C_Item.GetItemInfo(b.itemLink)) or "";
        return nameA < nameB;
      end,
      GetText = function(rowData)
        local itemName, icon = GetItemDisplay(rowData.itemLink);
        local displayName = itemName or rowData.itemLink or "Unknown";

        if (rowData.alreadyAdded) then
          return IconStr(icon) .. "|cff888888" .. displayName .. " (added)|r";
        end

        return IconStr(icon) .. displayName;
      end,
      GetHyperlink = function(rowData)
        return rowData.itemLink or "";
      end,
      CustomizeRow = function(listFrame, helpers)
        local rowData = listFrame.rowData;

        if (not rowData.alreadyAdded) then
          listFrame:SetScript("OnClick", function()
            local dialog = GetOrCreateEditDialog();

            dialog:Open(
              rowData.itemLink,
              { quantity = 1, scope = UtilityHub.Enums.AutoBuyScope.ACCOUNT, scopeValue = nil },
              function(qty, scope, scopeValue)
                local currentList = UtilityHub.Database.global.options.autoBuyList or {};

                tinsert(currentList, {
                  itemLink = rowData.itemLink,
                  quantity = qty,
                  scope = scope,
                  scopeValue = scopeValue,
                });

                UtilityHub.Database.global.options.autoBuyList = currentList;
                UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "autoBuyList", currentList);
                RefreshList();
                RefreshBagItems();
              end
            );
          end);
        else
          listFrame:SetScript("OnClick", nil);
        end
      end,
      hasHyperlink = true,
    },
    "InsetFrameTemplate"
  );
  fromBagListFrame:SetPoint("TOPLEFT", rightLabel, "BOTTOMLEFT", 0, -4);
  fromBagListFrame:SetPoint("BOTTOMRIGHT", rightPane, "BOTTOMRIGHT", 0, 0);

  -- Scan bags and populate the From Bag list
  RefreshBagItems = function()
    local autoBuyList = UtilityHub.Database.global.options.autoBuyList or {};
    local addedIDs = {};

    for _, item in ipairs(autoBuyList) do
      if (item.itemLink) then
        local id = tonumber(string.match(item.itemLink, "item:(%d+):"));
        if (id) then addedIDs[id] = true; end
      end
    end

    local bagItems = {};
    local seenIDs = {};

    for bag = 0, NUM_BAG_SLOTS do
      local numSlots = C_Container.GetContainerNumSlots(bag);

      for slot = 1, numSlots do
        local bagItemLink = C_Container.GetContainerItemLink(bag, slot);

        if (bagItemLink) then
          local itemID = tonumber(string.match(bagItemLink, "item:(%d+):"));

          if (itemID and not seenIDs[itemID]) then
            seenIDs[itemID] = true;
            tinsert(bagItems, {
              itemLink = bagItemLink,
              alreadyAdded = addedIDs[itemID] == true,
            });
          end
        end
      end
    end

    fromBagListFrame:ReplaceData(bagItems);
  end;

  fromBagRefreshBtn:SetScript("OnClick", function()
    RefreshBagItems();
  end);

  -- Expand / collapse the add section
  local function SetAddExpanded(expanded)
    addExpanded = expanded;

    if (expanded) then
      addSection:SetHeight(ADD_EXPANDED_HEIGHT);
      addToggleText:SetText("[-] Add item");
      addContent:Show();
      RefreshBagItems();
    else
      addSection:SetHeight(ADD_COLLAPSED_HEIGHT);
      addToggleText:SetText("[+] Add item");
      addContent:Hide();
    end
  end

  addToggle:SetScript("OnClick", function()
    SetAddExpanded(not addExpanded);
  end);

  -- ===== Filter row (just above the main list) =====
  local showMineOnly = true;

  -- Helper: returns true if the item applies to the current character
  local function IsItemForCurrentPlayer(rowData)
    local scope = rowData.scope or UtilityHub.Enums.AutoBuyScope.ACCOUNT;

    if (scope == UtilityHub.Enums.AutoBuyScope.ACCOUNT) then
      return true;
    elseif (scope == UtilityHub.Enums.AutoBuyScope.CHARACTER) then
      return rowData.scopeValue == UnitName("player");
    elseif (scope == UtilityHub.Enums.AutoBuyScope.CLASS) then
      local _, classFile = UnitClass("player");
      return rowData.scopeValue == classFile;
    end

    return true;
  end

  local filterLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  filterLabel:SetPoint("TOPLEFT", addSection, "BOTTOMLEFT", 0, -10);
  filterLabel:SetText("Filter:");

  local filterMineBtn = CreateFrame("CheckButton", nil, frame, "UIRadioButtonTemplate");
  filterMineBtn:SetSize(16, 16);
  filterMineBtn:SetPoint("LEFT", filterLabel, "RIGHT", 8, 0);
  filterMineBtn:SetChecked(true);

  local filterMineLabel = filterMineBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  filterMineLabel:SetPoint("LEFT", filterMineBtn, "RIGHT", 2, 0);
  filterMineLabel:SetText("Mine");

  local filterAllBtn = CreateFrame("CheckButton", nil, frame, "UIRadioButtonTemplate");
  filterAllBtn:SetSize(16, 16);
  filterAllBtn:SetPoint("LEFT", filterMineBtn, "RIGHT", 46, 0);
  filterAllBtn:SetChecked(false);

  local filterAllLabel = filterAllBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  filterAllLabel:SetPoint("LEFT", filterAllBtn, "RIGHT", 2, 0);
  filterAllLabel:SetText("All");

  filterMineBtn:SetScript("OnClick", function()
    showMineOnly = true;
    filterMineBtn:SetChecked(true);
    filterAllBtn:SetChecked(false);
    RefreshList();
  end);

  filterAllBtn:SetScript("OnClick", function()
    showMineOnly = false;
    filterMineBtn:SetChecked(false);
    filterAllBtn:SetChecked(true);
    RefreshList();
  end);

  -- ===== Main items list =====

  -- Helper: scope tag text for list rows
  local function GetScopeTag(rowData)
    local scope = rowData.scope or UtilityHub.Enums.AutoBuyScope.ACCOUNT;

    if (scope == UtilityHub.Enums.AutoBuyScope.CHARACTER) then
      return "[Char: " .. (rowData.scopeValue or "?") .. "]";
    elseif (scope == UtilityHub.Enums.AutoBuyScope.CLASS) then
      return "[Class: " .. (rowData.scopeValue or "?") .. "]";
    end

    return "[Account]";
  end

  autoBuyListFrame = framesHelper:CreateCustomList(
    "AutoBuyList",
    frame,
    nil,
    {
      SortComparator = function(a, b)
        local nameA = (a.itemLink and C_Item.GetItemInfo(a.itemLink)) or "";
        local nameB = (b.itemLink and C_Item.GetItemInfo(b.itemLink)) or "";
        return nameA < nameB;
      end,
      Predicate = function(rowData)
        return rowData.itemLink;
      end,
      GetText = function(rowData)
        local _, icon = GetItemDisplay(rowData.itemLink);
        local displayName = rowData.itemLink or "Unknown";
        local qty = rowData.quantity or 1;
        local scopeTag = GetScopeTag(rowData);

        local qtyText = "Once";

        if (qty ~= 1) then
          qtyText = "Restock: " .. qty;
        end

        return IconStr(icon) .. string.format("%s (%s) %s", displayName, qtyText, scopeTag);
      end,
      GetHyperlink = function(rowData)
        return rowData.itemLink or "";
      end,
      OnRemove = function(rowData, configuration)
        local list = UtilityHub.Database.global.options.autoBuyList or {};
        local removeID = tonumber(string.match(rowData.itemLink, "item:(%d+):"));

        for i = #list, 1, -1 do
          if (list[i].itemLink) then
            local existingID = tonumber(string.match(list[i].itemLink, "item:(%d+):"));

            if (existingID == removeID) then
              tremove(list, i);
              break;
            end
          end
        end

        UtilityHub.Database.global.options.autoBuyList = list;
        UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "autoBuyList", list);
        RefreshList();
      end,
      CustomizeRow = function(listFrame, helpers)
        if (not listFrame.customElements) then
          listFrame.customElements = {};
        end

        if (not listFrame.customElements.EditButton) then
          local editButton = CreateFrame("Button", nil, listFrame);
          listFrame.customElements.EditButton = editButton;
          editButton:SetSize(16, 16);
          editButton:SetPoint("TOPRIGHT", -25, -5);
          local texture = editButton:CreateTexture();
          UtilityHub.Textures:ApplyTexture("OrangeCogs", texture);

          editButton:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
            GameTooltip:SetText("Edit");
            GameTooltip:Show();
          end);

          editButton:SetScript("OnLeave", function(self)
            if (GameTooltip:IsOwned(self)) then
              GameTooltip:Hide();
            end
          end);
        end

        -- Re-bind OnClick each time to capture the current rowData.
        listFrame.customElements.EditButton:SetScript("OnClick", function(self)
          local dialog = GetOrCreateEditDialog();
          local rowData = self:GetParent().rowData;

          dialog:Open(rowData.itemLink, rowData, function(qty, scope, scopeValue)
            local list = UtilityHub.Database.global.options.autoBuyList or {};
            local editID = tonumber(string.match(rowData.itemLink, "item:(%d+):"));

            for i, item in ipairs(list) do
              if (item.itemLink) then
                local existingID = tonumber(string.match(item.itemLink, "item:(%d+):"));
                if (existingID == editID) then
                  list[i].quantity = qty;
                  list[i].scope = scope;
                  list[i].scopeValue = scopeValue;
                  break;
                end
              end
            end

            UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", "autoBuyList", list);
            RefreshList();
          end);
        end);
      end,
      showRemoveIcon = true,
      hasHyperlink = true,
    },
    "InsetFrameTemplate"
  );

  autoBuyListFrame:SetPoint("TOPLEFT", filterLabel, "BOTTOMLEFT", 0, -6);
  autoBuyListFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 20);

  -- Define RefreshList now that autoBuyListFrame exists
  RefreshList = function()
    local allList = UtilityHub.Database.global.options.autoBuyList or {};
    local validList = {};

    for _, item in ipairs(allList) do
      if (item.itemLink) then
        tinsert(validList, item);
      end
    end

    if (showMineOnly) then
      local filtered = {};

      for _, item in ipairs(validList) do
        if (IsItemForCurrentPlayer(item)) then
          tinsert(filtered, item);
        end
      end

      autoBuyListFrame:ReplaceData(filtered);
    else
      autoBuyListFrame:ReplaceData(validList);
    end
  end;

  -- Load initial data
  RefreshList();
  RefreshBagItems();

  return frame;
end

-- Register page
UtilityHub.OptionsPages.AutoBuy = AutoBuyPage;
