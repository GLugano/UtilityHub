local Type, Version = "ItemList", 1;
local AceGUI = LibStub("AceGUI-3.0");
-- if AceGUI:GetWidgetVersion(Type) and AceGUI:GetWidgetVersion(Type) >= Version then return end

---@class ItemListArg
---@field widthSizeType? "side" | "full" | "manual"
---@field heightSizeType? "default" | "full" | "manual"
---@field width? number
---@field height? number
---@field hideAdd? boolean
---@field GetRowIndex? fun(self, list: table[], rowData): number | nil
---@field OnEnterRow? fun(self, frame, rowData)
---@field OnLeaveRow? fun(self, frame)
---@field CreateNewRow? fun(self, text: string, OnSuccess: fun(rowData, errorCb), OnError: fun())
---@field CustomizeRowElement? fun(self, frame, rowData, helpers): CustomizeRowElementReturnFlags | nil

---@class CustomizeRowElementReturnFlags
---@field skipFontStringPoints? boolean

local ReleaseSimpleFrame = function(simpleFrame)
  if (simpleFrame) then
    simpleFrame:SetParent(nil);
    simpleFrame:ClearAllPoints();
    simpleFrame:Hide();
  end
end

local function Constructor()
  local buttonAddWidth = 40;
  local frame = CreateFrame("Frame", nil, UIParent);

  local content = CreateFrame("Frame", "ScrollableList", frame, "InsetFrameTemplate");
  content:SetHeight(300);

  local widget = {
    type             = Type,
    frame            = frame,
    content          = content,
    items            = {},
    rows             = {},
    events           = {},
    dragging         = nil,
    userdata         = nil,
    widthSizeType    = "full",
    heightSizeType   = "default",
    UpdateList       = nil,
    rendered         = false,
    GetUserDataTable = function(self)
      return self.userdata;
    end
  };

  function CreateScrollableList()
    local function CreateDeleteIconButton(self, frame, rowData)
      frame.customElements[widget.name].DeleteIconButton = CreateFrame("Button", nil, frame);
      frame.customElements[widget.name].DeleteIconButton:SetNormalAtlas("transmog-icon-remove");
      frame.customElements[widget.name].DeleteIconButton:SetPoint("TOPRIGHT", -5, -5);
      frame.customElements[widget.name].DeleteIconButton:SetSize(15, 15);
      frame.customElements[widget.name].DeleteIconButton:SetScript("OnClick", function()
        local index = widget:GetRowIndex(widget.items, rowData);

        if (index) then
          table.remove(widget.items, index);
          widget:FireValueChanged();
        end
      end);
      frame.customElements[widget.name].DeleteIconButton:SetScript("OnEnter", function()
        local el = frame.customElements[widget.name].DeleteIconButton;

        if (el) then
          GameTooltip:SetOwner(el, "ANCHOR_RIGHT");
          GameTooltip:SetText("Remove");
          GameTooltip:Show();
        end
      end);
      frame.customElements[widget.name].DeleteIconButton:SetScript("OnLeave", function()
        local el = frame.customElements[widget.name].DeleteIconButton;

        if (not GameTooltip:IsOwned(el)) then
          return;
        end

        GameTooltip:Hide();
      end);

      return frame.customElements[widget.name].DeleteIconButton;
    end

    local function CreateCheckbox(self, frame, rowData)
      local checkbox = frame.customElements[widget.name].Checkbox or
          CreateFrame("CheckButton", nil, frame,
            "SettingsCheckBoxTemplate");
      frame.customElements[widget.name].Checkbox = checkbox;
      local rowData = widget.items[widget:GetRowIndex(widget.items, rowData)];

      checkbox:ClearAllPoints();
      checkbox:SetPoint("TOPLEFT", 6, 1);
      checkbox:SetChecked(rowData.checked);
      checkbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked();
        local rowData = widget.items[widget:GetRowIndex(widget.items, rowData)];

        rowData.checked = checked;
        widget:FireValueChanged();
      end)
    end

    local container = widget.content;
    container:SetWidth(widget.frame:GetSize());
    content:SetPoint("TOPLEFT", frame.EditBoxAdd, "TOPLEFT", -2, -30);

    container.Scrollbar = CreateFrame("EventFrame", nil, container, "MinimalScrollBar");
    container.Scrollbar:SetPoint("TOPRIGHT", -10, -5);
    container.Scrollbar:SetPoint("BOTTOMRIGHT", -10, 5);

    container.ScrollBox = CreateFrame("Frame", nil, container, "WowScrollBoxList");
    container.ScrollBox:SetPoint("TOPLEFT", 2, -4);
    container.ScrollBox:SetPoint("BOTTOMRIGHT", container.Scrollbar, "BOTTOMLEFT", -3, 0);

    widget.UpdateList = function(self)
      container.ScrollBox:SetDataProvider(CreateDataProvider(widget.items));

      C_Timer.After(0.01, function()
        container.ScrollBox:ScrollToEnd();
        container.ScrollBox:ScrollToBegin();
      end);
    end

    container.View = CreateScrollBoxListLinearView();
    container.View:SetElementExtent(26);
    container.View:SetElementInitializer("Button", function(frame, rowData)
      frame:SetPushedTextOffset(0, 0);
      frame:SetHighlightAtlas("search-highlight");
      frame:SetNormalFontObject(GameFontHighlight);
      frame.rowData = rowData;

      if (not frame.customElements) then
        frame.customElements = {};
      end

      if (not frame.customElements[widget.name]) then
        frame.customElements[widget.name] = {};
      end

      for widgetName, customElementsByWidget in pairs(frame.customElements) do
        for customElementName, customElement in pairs(customElementsByWidget) do
          ReleaseSimpleFrame(customElement);
          customElementsByWidget[customElementName] = nil;
        end
      end

      frame:SetScript("OnEnter", function()
        if (widget.OnEnterRow) then
          widget:OnEnterRow(frame, rowData);
        end
      end);

      frame:SetScript("OnLeave", function()
        if (widget.OnLeaverRow) then
          widget:OnLeaverRow(frame);
        end
      end);

      local flags = widget:CustomizeRowElement(frame, rowData, {
        CreateDeleteIconButton = CreateDeleteIconButton,
        CreateCheckbox = CreateCheckbox,
        ReleaseSimpleFrame = ReleaseSimpleFrame,
      });

      frame:GetFontString():SetJustifyH("LEFT");

      if (not flags or not flags.skipFontStringPoints) then
        frame:GetFontString():SetPoint("LEFT", 6, 0);
        frame:GetFontString():SetPoint("RIGHT", -6, 0);
      end
    end);

    ScrollUtil.InitScrollBoxListWithScrollBar(container.ScrollBox, container.Scrollbar, container.View);
  end

  frame.EditBoxAdd = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate");
  frame.EditBoxAdd.Instructions:SetText("");
  frame.EditBoxAdd.searchIcon:Hide();
  frame.EditBoxAdd:SetTextInsets(0, 20, 0, 0);
  frame.EditBoxAdd:SetAutoFocus(false);
  frame.EditBoxAdd:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -2);
  frame.EditBoxAdd:SetHyperlinksEnabled(true);
  frame.EditBoxAdd:SetScript("OnMouseUp", function()
    local _, _, itemLink = GetCursorInfo();

    if (itemLink) then
      frame.EditBoxAdd:SetText(itemLink);
    end

    ClearCursor();
  end);

  frame.ButtonAdd = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
  frame.ButtonAdd:SetText("Add");
  frame.ButtonAdd:SetSize(40, 22);
  frame.ButtonAdd:SetPoint("LEFT", frame.EditBoxAdd, "RIGHT", 4, 0);
  frame.ButtonAdd:SetScript("OnClick", function()
    widget:OnNewRow();
  end);

  frame.EditBoxAdd:SetScript("OnEnterPressed", function()
    frame.ButtonAdd:Click();
  end);

  CreateScrollableList();

  widget.SetLabel = function(self, text) end
  widget.SetDisabled = function(self, disabled) end
  widget.SetList = function(self, list) end

  function widget:Refresh()
    -- widget:UpdateList();
  end

  function widget:DoLayout()
    widget:UpdateList();
  end

  function widget:SetValue(list)
  end

  function widget:GetValue()
    return C_EncodingUtil.SerializeJSON(self.items);
  end

  function widget:FireValueChanged()
    if (self.events.OnEnterPressed) then
      self:Fire("OnEnterPressed", self:GetValue());
    end
  end

  function widget:SetText(text)
    if (type(text) == "string") then
      local items = C_EncodingUtil.DeserializeJSON(text);

      self.items = items;

      if (self.rendered) then
        self:UpdateList();
      end
    end
  end

  function widget:SetCallback(event, method)
    if (type(method) == "function") then
      self.events[event] = method;
    end
  end

  function widget:OnAcquire()
    self.items = self.items or {};
  end

  function widget:OnRelease()
    widget.content.ScrollBox:RemoveDataProvider();
  end

  function widget:GetRowIndexBase(rows, rowData)
    for index, loopItem in ipairs(rows) do
      if (loopItem == rowData) then
        return index;
      end
    end

    return nil;
  end

  function widget:CreateNewRowBase(text, OnSuccess, OnError)
    if (text) then
      OnSuccess(text);
    else
      OnError();
    end
  end

  function widget:OnNewRow()
    frame.EditBoxAdd:Disable();
    frame.ButtonAdd:Disable();

    function OnSuccess(row, errorCb)
      DevTools_Dump(errorCb);
      if (not widget:GetRowIndex(widget.items, row)) then
        tinsert(widget.items, row);
        widget:FireValueChanged();
      elseif (errorCb) then
        errorCb("ROW_ALREADY_EXISTS");
      end

      frame.EditBoxAdd:SetText("");
      frame.EditBoxAdd:Enable();
      frame.ButtonAdd:Enable();
    end

    function OnError()
      frame.EditBoxAdd:SetText("");
      frame.EditBoxAdd:Enable();
      frame.ButtonAdd:Enable();
    end

    widget:CreateNewRow(frame.EditBoxAdd:GetText(), OnSuccess, OnError);
  end

  function widget:CustomizeRowElementBase(frame, row, helpers)
    -- Default consider the row as a simple string
    frame:SetText(row);
  end

  function widget:ToggleAddBar()
    if (widget.hideAdd) then
      frame.ButtonAdd:Hide();
      frame.EditBoxAdd:Hide();
      content:ClearAllPoints();
      content:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, -2);
    else
      frame.ButtonAdd:Show();
      frame.EditBoxAdd:Show();
      content:ClearAllPoints();
      content:SetPoint("TOPLEFT", frame.EditBoxAdd, "TOPLEFT", -2, -30);
    end
  end

  function widget:SetSizeType(widthSizeType, configWidth, heightSizeType, configHeight)
    local width = (widthSizeType == "side" and 440) or 630;
    local height = (heightSizeType == "default" and 250) or 480;
    local scrollBarHeight = (widget.hideAdd and 0) or 24;

    if (widthSizeType == "manual") then
      width = configWidth;
    end

    if (heightSizeType == "manual") then
      height = configHeight;
    end

    frame:SetWidth(width);
    frame:SetHeight(height);
    frame.EditBoxAdd:SetSize(width - buttonAddWidth - 4, scrollBarHeight);

    local frameWidth, frameHeight = widget.frame:GetSize();
    local scrollBoxParent = widget.content.ScrollBox:GetParent();
    scrollBoxParent:SetWidth(frameWidth);
    scrollBoxParent:SetHeight(frameHeight - scrollBarHeight - 6);

    widget.widthSizeType = widthSizeType;
    widget.heightSizeType = heightSizeType;
    widget.rendered = true;
  end

  ---@param data ItemListArg
  function widget:SetCustomData(data)
    widget.name = widget:GetUserDataTable().option.name;
    widget.hideAdd = data.hideAdd ~= nil and data.hideAdd;
    widget.OnEnterRow = (data and data.OnEnterRow) or nil;
    widget.OnLeaverRow = (data and data.OnLeaveRow) or nil;
    widget.GetRowIndex = (data and data.GetRowIndex) or widget.GetRowIndexBase;
    widget.CreateNewRow = (data and data.CreateNewRow) or widget.CreateNewRowBase;
    widget.CustomizeRowElement = (data and data.CustomizeRowElement) or widget.CustomizeRowElementBase;
    widget:SetSizeType(
      data.widthSizeType or "full",
      data.width,
      data.heightSizeType or "default",
      data.height
    );
    widget:ToggleAddBar();
  end

  hooksecurefunc("ChatEdit_InsertLink", function(link)
    if (frame.EditBoxAdd:HasFocus()) then
      frame.EditBoxAdd:SetText(link);
    end
  end);

  hooksecurefunc("OpenStackSplitFrame", function()
    if (frame.EditBoxAdd:HasFocus()) then
      StackSplitFrame:Hide();
    end
  end);

  AceGUI:RegisterAsWidget(widget);

  return widget;
end

AceGUI:RegisterWidgetType(Type, Constructor, Version);
