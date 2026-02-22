--- @class UtilityHub_OptionListControlMixin : SettingsControlMixin
UtilityHub_OptionListControlMixin = CreateFromMixins(SettingsControlMixin);

function UtilityHub_OptionListControlMixin:OnLoad()
  -- Force refresh when control becomes visible
  self:SetScript("OnShow", function()
    if (self.dataProvider and self:GetSetting()) then
      local toRemove = {};
      for _, value in self.dataProvider:Enumerate() do
        tinsert(toRemove, value);
      end
      for _, value in ipairs(toRemove) do
        self.dataProvider:Remove(value);
      end
      self:UpdateList(self:GetValue());
    end
  end);

  local function CreateDeleteIconButton(self, frame)
    local rowData = frame.rowData;

    if (not frame.customElements) then
      frame.customElements = {};
    end

    if (frame.customElements.DeleteIconButton) then
      frame.customElements.DeleteIconButton.rowData = rowData;
      return frame.customElements.DeleteIconButton;
    end

    frame.customElements.DeleteIconButton = CreateFrame("Button", nil, frame);
    frame.customElements.DeleteIconButton:SetNormalAtlas("transmog-icon-remove");
    frame.customElements.DeleteIconButton:SetPoint("TOPRIGHT", -5, -5);
    frame.customElements.DeleteIconButton:SetSize(15, 15);
    frame.customElements.DeleteIconButton:SetScript("OnClick", function()
      self.EditBoxAdd:ClearFocus();
      self:Remove(frame.customElements.DeleteIconButton.rowData);
    end);
    frame.customElements.DeleteIconButton:SetScript("OnEnter", function()
      local el = frame.customElements.DeleteIconButton;

      if (el) then
        GameTooltip:SetOwner(el, "ANCHOR_RIGHT");
        GameTooltip:SetText("Remove");
        GameTooltip:Show();
      end
    end);
    frame.customElements.DeleteIconButton:SetScript("OnLeave", function()
      local el = frame.customElements.DeleteIconButton;

      if (not GameTooltip:IsOwned(el)) then
        return;
      end

      GameTooltip:Hide();
    end);

    return frame.customElements.DeleteIconButton;
  end

  local function CreateEditIconButton(self, frame)
    local rowData = frame.rowData;

    if (not frame.customElements) then
      frame.customElements = {};
    end

    if (frame.customElements.EditIconButton) then
      frame.customElements.EditIconButton.rowData = rowData;
      return frame.customElements.EditIconButton;
    end

    frame.customElements.EditIconButton = CreateFrame("Button", nil, frame);
    frame.customElements.EditIconButton:SetNormalTexture("Interface\\WorldMap\\GEAR_64GREY");
    frame.customElements.EditIconButton:SetPoint("TOPRIGHT", -28, -4);
    frame.customElements.EditIconButton:SetSize(18, 18);
    frame.customElements.EditIconButton:SetScript("OnClick", function()
      if (frame.configuration.OnEditClicked) then
        frame.configuration.OnEditClicked(frame.rowData);
      end
    end);
    frame.customElements.EditIconButton:SetScript("OnEnter", function()
      local el = frame.customElements.EditIconButton;

      if (el) then
        GameTooltip:SetOwner(el, "ANCHOR_RIGHT");
        GameTooltip:SetText("Edit");
        GameTooltip:Show();
      end
    end);
    frame.customElements.EditIconButton:SetScript("OnLeave", function()
      local el = frame.customElements.EditIconButton;

      if (not GameTooltip:IsOwned(el)) then
        return;
      end

      GameTooltip:Hide();
    end);

    return frame.customElements.EditIconButton;
  end

  SettingsControlMixin.OnLoad(self);

  -- List
  local content = CreateFrame("Frame", nil, self, "InsetFrameTemplate");
  self.content = content;
  content:SetPoint("TOPLEFT", 245, -25);
  content:SetPoint("BOTTOMRIGHT", -5, 7);

  self.ScrollBar = CreateFrame("EventFrame", nil, content, "MinimalScrollBar");
  self.ScrollBar:SetPoint("TOPRIGHT", -10, -5);
  self.ScrollBar:SetPoint("BOTTOMRIGHT", 0, 5);

  self.ScrollBox = CreateFrame("Frame", nil, content, "WowScrollBoxList");
  self.ScrollBox:SetPoint("TOPLEFT", 2, -4);
  self.ScrollBox:SetPoint("BOTTOMRIGHT", self.ScrollBar, "BOTTOMLEFT", -3, 0);

  local view = CreateScrollBoxListLinearView();
  view:SetElementExtent(26);
  view:SetElementInitializer("Button", function(frame, rowData)
    local configuration = self:GetConfiguration();
    local GetText = configuration.GetText or function(rowData)
      return rowData;
    end;

    -- Reset custom elements from previous use
    if (frame.customElements) then
      if (frame.customElements.DeleteIconButton) then
        frame.customElements.DeleteIconButton:Hide();
      end
      if (frame.customElements.EditIconButton) then
        frame.customElements.EditIconButton:Hide();
      end
    end

    frame:SetPushedTextOffset(0, 0);
    frame:SetHighlightAtlas("search-highlight");
    frame:SetNormalFontObject(GameFontHighlight);
    frame.rowData = rowData;
    frame.configuration = configuration;
    frame:SetText(GetText(rowData));

    local fontString = frame:GetFontString();
    fontString:SetJustifyH("LEFT");
    fontString:SetPoint("LEFT", 6, 0);
    fontString:SetPoint("RIGHT", -6, 0);

    frame:SetScript("OnEnter", function(self)
      if (frame.configuration.hasHyperlink and frame.configuration.GetHyperlink) then
        GameTooltip:SetOwner(self, "ANCHOR_LEFT");
        GameTooltip:SetHyperlink(frame.configuration.GetHyperlink(frame.rowData));
        GameTooltip:Show();
      end
    end);
    frame:SetScript("OnLeave", function(self)
      if (GameTooltip:IsOwned(self)) then
        GameTooltip:Hide();
      end
    end);

    if (configuration.showRemoveIcon) then
      local btn = CreateDeleteIconButton(self, frame);

      if (btn) then
        btn:Show();
      end
    else
      if (frame.customElements and frame.customElements.DeleteIconButton) then
        frame.customElements.DeleteIconButton:Hide();
      end
    end

    if (configuration.showEditIcon) then
      local btn = CreateEditIconButton(self, frame);

      if (btn) then
        btn:Show();
      end
    else
      if (frame.customElements and frame.customElements.EditIconButton) then
        frame.customElements.EditIconButton:Hide();
      end
    end

    local CustomizeRow = configuration.CustomizeRow;

    if (CustomizeRow) then
      CustomizeRow(
        frame,
        {
          CreateDeleteIconButton = CreateDeleteIconButton,
          CreateEditIconButton = CreateEditIconButton
        }
      );
    end
  end);

  ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view);

  -- Search bar
  self.EditBoxAdd = CreateFrame("EditBox", nil, content, "SearchBoxTemplate");
  self.EditBoxAdd:Hide();
  self.EditBoxAdd.Instructions:SetText("");
  self.EditBoxAdd.searchIcon:Hide();
  self.EditBoxAdd:SetTextInsets(0, 20, 0, 0);
  self.EditBoxAdd:SetWidth(320);
  self.EditBoxAdd:SetHeight(30);
  self.EditBoxAdd:SetAutoFocus(false);
  self.EditBoxAdd:SetPoint("TOPLEFT", 4, 28);
  self.EditBoxAdd:SetHyperlinksEnabled(true);
  self.EditBoxAdd:SetScript("OnMouseUp", function()
    local _, _, itemLink = GetCursorInfo();

    if (itemLink) then
      self.EditBoxAdd:SetText(itemLink);
    end

    ClearCursor();
  end);
  self.EditBoxAdd:SetScript("OnEscapePressed", function(self)
    self:ClearFocus();
  end);

  self.ButtonAdd = CreateFrame("Button", nil, content, "UIPanelButtonTemplate");
  self.ButtonAdd:Hide();
  self.ButtonAdd:SetText("Add");
  self.ButtonAdd:SetSize(44, 22);
  self.ButtonAdd:SetPoint("TOPLEFT", self.EditBoxAdd, "TOPRIGHT", 10, -4);
  self.ButtonAdd:SetScript("OnClick", function()
    self.EditBoxAdd:ClearFocus();
    self:AddRow(self.EditBoxAdd:GetText());
    self.EditBoxAdd:SetText("");
  end);

  self.EditBoxAdd:SetScript("OnEnterPressed", function()
    self.EditBoxAdd:ClearFocus();
    self.ButtonAdd:Click();
  end);
end

function UtilityHub_OptionListControlMixin:Init(initializer)
  SettingsControlMixin.Init(self, initializer);

  local configuration = self:GetConfiguration();

  local setting = self:GetSetting();
  self.settingVariable = setting and setting.variable or "unknown";

  -- Store global reference to this control for external access
  if (not _G.UtilityHub_OptionListControls) then
    _G.UtilityHub_OptionListControls = {};
  end
  _G.UtilityHub_OptionListControls[self.settingVariable] = self;

  self.dataProvider = CreateDataProvider();
  self.dataProvider:SetSortComparator(configuration.SortComparator);
  self.ScrollBox:SetDataProvider(self.dataProvider);

  self:UpdateList(self:GetValue());
  self:Sort();

  self.EditBoxAdd:SetText("");

  if (configuration.showInput) then
    self.ButtonAdd:Show();
    self.EditBoxAdd:Show();
  else
    self.ButtonAdd:Hide();
    self.EditBoxAdd:Hide();
  end
end

function UtilityHub_OptionListControlMixin:SetValue(value)
  self:UpdateList(value);
end

---@param values table|nil
function UtilityHub_OptionListControlMixin:UpdateList(values)
  ---@param rowData any
  ---@return function
  local function GeneratePredicateFn(rowData)
    return function(elementData)
      local predicateFn = self:GetPredicateFn();

      return predicateFn(elementData) == predicateFn(rowData);
    end
  end;

  ---@param values string[]
  ---@param itemLink string
  ---@return boolean
  local Find = function(values, value)
    local predicateFn = self:GetPredicateFn();

    for _, loopValue in ipairs(values) do
      if (predicateFn(loopValue) == predicateFn(value)) then
        return true;
      end
    end

    return false;
  end

  ---@type string[]
  local values = values or {};
  local dataProvider = self.dataProvider;
  local hasChanges = false;

  -- Check for insert/update
  for _, value in ipairs(values) do
    local index, row = dataProvider:FindByPredicate(GeneratePredicateFn(value));

    if (not row) then
      dataProvider:Insert(value);
      hasChanges = true;
    end
  end

  -- Check for remove
  local notFound = {};

  for _, value in dataProvider:Enumerate() do
    if (not Find(values, value)) then
      tinsert(notFound, value);
      hasChanges = true;
    end
  end

  for _, value in ipairs(notFound) do
    dataProvider:RemoveByPredicate(GeneratePredicateFn(value));
  end

  if (hasChanges) then
    self:Sort();
  end
end

function UtilityHub_OptionListControlMixin:Sort()
  self.dataProvider:Sort();
end

---@return table
function UtilityHub_OptionListControlMixin:GetValue()
  return self:GetSetting():GetValue() or {};
end

---@param rowData any
---@return integer|nil
function UtilityHub_OptionListControlMixin:GetRowIndex(rowData)
  local rows = self:GetValue();
  local predicateFn = self:GetPredicateFn();

  for index, loopItem in ipairs(rows) do
    if (predicateFn(loopItem) == predicateFn(rowData)) then
      return index;
    end
  end

  return nil;
end

function UtilityHub_OptionListControlMixin:Remove(rowData)
  local index = self:GetRowIndex(rowData);
  local rows = self:GetValue();

  if (index) then
    table.remove(rows, index);

    -- Update database and refresh UI manually
    if (self.dataProvider) then
      self.dataProvider:Flush();
      self:UpdateList(rows);
    end
  end
end

---@return function
function UtilityHub_OptionListControlMixin:GetPredicateFn()
  return self:GetConfiguration().Predicate or function(rowData)
    return rowData;
  end;
end

function UtilityHub_OptionListControlMixin:OnValueChanged(value)
  self:GetSetting():SetValue(value);
  self:UpdateList(value);
end

---@return OptionListConfiguration
function UtilityHub_OptionListControlMixin:GetConfiguration()
  return self.data.configuration;
end

function UtilityHub_OptionListControlMixin:AddRow(text)
  text = string.trim(text);

  if (#text == 0) then
    return;
  end

  local value = self:GetValue();
  local newRowFn = function(text)
    return text;
  end
  local configuration = self:GetConfiguration();

  if (configuration.NewRow) then
    newRowFn = configuration.NewRow;
  end

  local newRow = newRowFn(text);

  if (self:GetRowIndex(newRow) ~= nil) then
    return;
  end

  tinsert(value, newRowFn(text));
  self:OnValueChanged(value);
end

---@class OptionListConfiguration
---@field SortComparator fun(a: any, b: any): boolean
---@field Predicate fun(value: any): any
---@field showInput? boolean
---@field hasHyperlink? boolean
---@field showRemoveIcon? boolean
---@field showEditIcon? boolean
---@field CustomizeRow? fun(frame: table, helpers)
---@field NewRow? fun(text: string): any
---@field GetText? fun(rowData: any): string
---@field GetHyperlink? fun(rowData: any): string
---@field OnEditClicked? fun(rowData: any)
