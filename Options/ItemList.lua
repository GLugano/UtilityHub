local Type, Version = "ItemList", 1;
local AceGUI = LibStub("AceGUI-3.0");
-- if AceGUI:GetWidgetVersion(Type) and AceGUI:GetWidgetVersion(Type) >= Version then return end

---@class ItemListArg
---@field HideAdd? boolean
---@field GetRowIndex? fun(self, list: table[], rowData): number | nil
---@field OnEnterRow? fun(self, frame, rowData)
---@field OnLeaveRow? fun(self, frame)
---@field CreateNewRow fun(self, text: string, OnSuccess: fun(rowData), OnError: fun())
---@field CustomizeRowElement? fun(self, frame, rowData, helpers): CustomizeRowElementReturnFlags | nil

---@class CustomizeRowElementReturnFlags
---@field skipFontStringPoints? boolean

local function Constructor()
  function CreateScrollableList(widget, parent)
    local function CreateDeleteIconButton(self, frame, rowData)
      frame.DeleteIconButton = CreateFrame("Button", nil, frame);
      frame.DeleteIconButton:SetNormalAtlas("transmog-icon-remove");
      frame.DeleteIconButton:SetPoint("TOPRIGHT", -5, -2.5);
      frame.DeleteIconButton:SetSize(15, 15);
      frame.DeleteIconButton:SetScript("OnClick", function()
        local index = widget:GetRowIndex(widget.items, rowData);

        if (index) then
          table.remove(widget.items, index);
          widget:UpdateList();
          widget:FireValueChanged();
        end
      end);
      frame.DeleteIconButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(frame.DeleteIconButton, "ANCHOR_RIGHT");
        GameTooltip:SetText("Remove");
        GameTooltip:Show();
      end);
      frame.DeleteIconButton:SetScript("OnLeave", function()
        if (not GameTooltip:IsOwned(frame)) then
          return;
        end

        GameTooltip:Hide();
      end);

      return frame.DeleteIconButton;
    end

    local container = CreateFrame("Frame", "ScrollableList", parent, "InsetFrameTemplate");
    container:SetHeight(300);
    container:SetWidth(parent:GetSize());

    local scrollBar = CreateFrame("EventFrame", nil, container, "MinimalScrollBar");
    scrollBar:SetPoint("TOPRIGHT", -10, -5);
    scrollBar:SetPoint("BOTTOMRIGHT", -10, 5);

    local scrollBox = CreateFrame("Frame", nil, container, "WowScrollBoxList");
    scrollBox:SetPoint("TOPLEFT", 2, -4);
    scrollBox:SetPoint("BOTTOMRIGHT", scrollBar, "BOTTOMLEFT", -3, 0);

    local function UpdateList()
      scrollBox:SetDataProvider(CreateDataProvider(widget.items));

      C_Timer.After(0.01, function()
        scrollBox:ScrollToEnd();
        scrollBox:ScrollToBegin();
      end);
    end

    local view = CreateScrollBoxListLinearView();
    view:SetElementExtent(20);
    view:SetElementInitializer("Button", function(frame, rowData)
      -- Clear custom components
      if (frame.DeleteIconButton) then
        frame.DeleteIconButton:SetParent(nil);
        frame.DeleteIconButton:ClearAllPoints();
        frame.DeleteIconButton:Hide(nil);
      end

      frame:SetPushedTextOffset(0, 0);
      frame:SetHighlightAtlas("search-highlight");
      frame:SetNormalFontObject(GameFontHighlight);
      frame.rowData = rowData;

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

      local flags = widget:CustomizeRowElement(frame, rowData,
        { CreateDeleteIconButton = CreateDeleteIconButton });

      frame:GetFontString():SetJustifyH("LEFT");

      if (not flags or not flags.skipFontStringPoints) then
        frame:GetFontString():SetPoint("LEFT", 6, 0);
        frame:GetFontString():SetPoint("RIGHT", -6, 0);
      end
    end);

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view);

    return container, UpdateList;
  end

  local widget = {
    type     = Type,
    frame    = nil,
    content  = nil,
    items    = {},
    rows     = {},
    events   = {},
    dragging = nil,
    userdata = nil,
  };
  local width = 440;
  local buttonAddWidth = 40;

  local frame = CreateFrame("Frame", nil, UIParent);
  frame:SetHeight(250);
  frame:SetWidth(width);
  widget.frame = frame;

  frame.EditBoxAdd = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate");
  frame.EditBoxAdd.Instructions:SetText("");
  frame.EditBoxAdd.searchIcon:Hide();
  frame.EditBoxAdd:SetTextInsets(0, 20, 0, 0);
  frame.EditBoxAdd:SetAutoFocus(false);
  frame.EditBoxAdd:SetSize(width - buttonAddWidth - 4, 24);
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

  local content, UpdateList = CreateScrollableList(widget, frame);
  widget.content = content;
  content:SetPoint("TOPLEFT", frame.EditBoxAdd, "TOPLEFT", -2, -30);

  widget.SetLabel = function(self, text) end
  widget.SetDisabled = function(self, disabled) end
  widget.SetList = function(self, list) end
  widget.GetUserDataTable = function(self)
    return self.userdata;
  end

  function widget:UpdateList()
    UpdateList();
  end

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
      self:UpdateList();
    end
  end

  function widget:SetCallback(event, method)
    if (type(method) == "function") then
      self.events[event] = method;
    end
  end

  function widget:OnAcquire()
    self.items = self.items or {};
    self:Refresh();
  end

  ---@param data ItemListArg
  function widget:SetCustomData(data)
    widget.HideAdd = data.HideAdd ~= nil and data.HideAdd;
    widget.OnEnterRow = (data and data.OnEnterRow) or nil;
    widget.OnLeaverRow = (data and data.OnLeaveRow) or nil;
    widget.GetRowIndex = (data and data.GetRowIndex) or widget.GetRowIndexBase;
    widget.CreateNewRow = (data and data.CreateNewRow) or widget.CreateNewRowBase;
    widget.CustomizeRowElement = (data and data.CustomizeRowElement) or widget.CustomizeRowElementBase;

    widget:ToggleAddBar();
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

    function OnSuccess(row)
      tinsert(widget.items, row);
      widget:UpdateList();
      widget:FireValueChanged();
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
    if (widget.HideAdd) then
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

  hooksecurefunc("ChatEdit_InsertLink", function(link)
    if (frame.EditBoxAdd:HasFocus()) then
      frame.EditBoxAdd:Insert(link);
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
