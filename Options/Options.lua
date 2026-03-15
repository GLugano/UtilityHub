local ADDON_NAME = ...;

local framesHelper = {
  OnSettingChanged = function(setting, value)
    UtilityHub.Events:TriggerEvent("OPTIONS_CHANGED", setting.variableKey, value);
  end,
  ---@param category any
  ---@param name string
  ---@param var string
  ---@param varKey string
  ---@param varTable table
  ---@param defaultValue any
  ---@param tooltip string|nil
  CreateCheckbox = function(
      self,
      category,
      name,
      var,
      varKey,
      varTable,
      defaultValue,
      tooltip
  )
    local setting = Settings.RegisterAddOnSetting(
      category,
      var,
      varKey,
      varTable,
      type(defaultValue),
      name,
      defaultValue
    );
    setting:SetValueChangedCallback(self.OnSettingChanged);

    Settings.CreateCheckbox(category, setting, tooltip);
  end,
  ---@param category any
  ---@param name string
  ---@param var string
  ---@param varKey string
  ---@param varTable table
  ---@param defaultValue any
  ---@param configuration OptionListConfiguration
  CreateList = function(
      self,
      category,
      name,
      var,
      varKey,
      varTable,
      defaultValue,
      configuration
  )
    local layout = SettingsPanel:GetLayout(category);
    local setting = Settings.RegisterAddOnSetting(
      category,
      var,
      varKey,
      varTable,
      Settings.VarType.String,
      name,
      defaultValue
    );
    local data = Settings.CreateSettingInitializerData(setting, nil);
    data.configuration = configuration;
    local initializer = Settings.CreateSettingInitializer("UtilityHub_OptionListControlTemplate", data);
    layout:AddInitializer(initializer);
    setting:SetValueChangedCallback(self.OnSettingChanged);
  end,
  ------------------------------------------------------------------------
  ---------------------------------- CUSTOM ------------------------------
  ------------------------------------------------------------------------
  ---@param name string
  ---@param labelText string
  ---@param parent table
  ---@param previous? table
  ---@return Frame, EditBox, FontString
  CreateCustomFormField = function(
      self,
      name,
      labelText,
      parent,
      previous
  )
    local frame = CreateFrame("Frame", nil, parent);

    if (previous) then
      frame:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -7);
      frame:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", 0, -7);
    end

    frame:SetHeight(30);

    local input = CreateFrame(
      "EditBox",
      UtilityHub.Helpers.String:ApplyPrefix(name),
      frame, -- Parent is now the new 'frame'
      "InputBoxTemplate"
    );
    input:SetSize(200, 30);
    input:SetPoint("LEFT", frame, "LEFT", 254, 0);
    input:SetPoint("CENTER", frame, "CENTER", 0, 0);
    input:SetAutoFocus(false);
    input:SetText("");
    input:SetCursorPosition(0);

    local label = frame:CreateFontString(nil, "OVERLAY");
    label:SetFontObject("GameFontNormal");
    label:SetPoint("LEFT", frame, "LEFT", 48, 0);
    label:SetPoint("RIGHT", input, "LEFT", -5, 0);
    label:SetPoint("CENTER", input, "CENTER", 0, 0);
    label:SetText(labelText);
    label:SetJustifyH("LEFT");

    return frame, input, label;
  end,
  ---@class CustomList
  ---@field frame InsetFrameTemplate
  ---@field ReplaceData fun(data: table)

  ---@param name string
  ---@param labelText string
  ---@param parent table
  ---@param previous? table
  ---@param configuration OptionsCreateList
  ---@param frameTemplate? `Tp` | Template
  ---@return CustomList
  CreateCustomList = function(
      self,
      name,
      parent,
      previous,
      configuration,
      frameTemplate
  )
    ---comment
    ---@param frame table
    ---@param OnCheckedChange? fun(frame: table, rowData)
    local function CreateListCheckbox(frame, OnCheckedChange)
      if (frame.customElements.Checkbox) then
        frame.customElements.Checkbox:SetChecked(frame.rowData.checked);
        return;
      end

      local checkbox = frame.customElements.Checkbox or
          CreateFrame(
            "CheckButton",
            nil,
            frame,
            "UICheckButtonTemplate"
          );
      frame.customElements.Checkbox = checkbox;

      local rowData = checkbox:GetParent().rowData;

      checkbox:ClearAllPoints();
      checkbox:SetPoint("TOPLEFT", 6, 1);
      checkbox:SetChecked(rowData.checked);
      checkbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked();
        self:GetParent().checked = checked;
        frame.rowData.checked = checked;

        if (OnCheckedChange) then
          OnCheckedChange(frame, frame.rowData);
        end
      end);
    end

    local function CreateDeleteIconButton(frame)
      if (frame.customElements.DeleteIconButton) then
        return;
      end

      local deleteButton = CreateFrame("Button", nil, frame);
      frame.customElements.DeleteIconButton = deleteButton
      deleteButton:SetNormalAtlas("transmog-icon-remove");
      deleteButton:SetPoint("TOPRIGHT", -5, -5);
      deleteButton:SetSize(15, 15);
      deleteButton:SetScript("OnClick", function(self)
        self:Remove(deleteButton:GetParent().rowData);
      end);
      deleteButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetText("Remove");
        GameTooltip:Show();
      end);
      deleteButton:SetScript("OnLeave", function()
        local el = deleteButton;

        if (not GameTooltip:IsOwned(el)) then
          return;
        end

        GameTooltip:Hide();
      end);
      function deleteButton:Remove(rowData)
        if (configuration.OnRemove) then
          configuration.OnRemove(rowData, configuration);
        end
      end
    end

    local frame = CreateFrame("Frame", name, parent, frameTemplate);

    if (previous) then
      frame:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -42);
    end

    frame.ScrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar");
    frame.ScrollBar:SetPoint("TOPRIGHT", -10, -5);
    frame.ScrollBar:SetPoint("BOTTOMRIGHT", 0, 5);

    frame.ScrollBox = CreateFrame("Frame", nil, frame, "WowScrollBoxList");
    frame.ScrollBox:SetPoint("TOPLEFT", 2, -4);
    frame.ScrollBox:SetPoint("BOTTOMRIGHT", frame.ScrollBar, "BOTTOMLEFT", -3, 0);

    local view = CreateScrollBoxListLinearView();
    view:SetElementExtent(26);
    view:SetElementInitializer("Button", function(rowFrame, rowData)
      local GetText = configuration.GetText or function(rowData)
        return rowData;
      end;

      rowFrame:SetPushedTextOffset(0, 0);
      rowFrame:SetHighlightAtlas("search-highlight");
      rowFrame:SetNormalFontObject(GameFontHighlight);
      rowFrame.rowData = rowData;
      rowFrame.configuration = configuration;
      rowFrame:SetText(GetText(rowData));
      rowFrame.ScrollParent = frame;

      rowFrame:SetScript("OnEnter", function(self)
        if (rowFrame.configuration.hasHyperlink and rowFrame.configuration.GetHyperlink) then
          GameTooltip:SetOwner(self, "ANCHOR_LEFT");
          GameTooltip:SetHyperlink(rowFrame.configuration.GetHyperlink(rowFrame.rowData));
          GameTooltip:Show();
        end
      end);
      rowFrame:SetScript("OnLeave", function(self)
        if (GameTooltip:IsOwned(self)) then
          GameTooltip:Hide();
        end
      end);

      if (not rowFrame.customElements) then
        rowFrame.customElements = {};
      end

      local fontString = rowFrame:GetFontString();
      fontString:SetJustifyH("LEFT");

      if (configuration.showCheckbox) then
        CreateListCheckbox(rowFrame, configuration.OnCheckedChange);
        rowFrame:GetFontString():SetPoint("LEFT", 40, 0);
      else
        fontString:SetPoint("LEFT", 6, 0);
      end

      if (configuration.showRemoveIcon) then
        CreateDeleteIconButton(rowFrame);
        rowFrame:GetFontString():SetPoint("RIGHT", -40, 0);
      else
        rowFrame:GetFontString():SetPoint("RIGHT", -6, 0);
      end

      if (configuration.CustomizeRow) then
        configuration.CustomizeRow(
          rowFrame,
          {}
        );
      end
    end);

    ScrollUtil.InitScrollBoxListWithScrollBar(frame.ScrollBox, frame.ScrollBar, view);

    frame.dataProvider = CreateDataProvider();
    frame.dataProvider:SetSortComparator(configuration.SortComparator);
    frame.ScrollBox:SetDataProvider(frame.dataProvider);

    function frame:GetData()
      local data = {};

      for _, value in self.dataProvider:Enumerate() do
        tinsert(data, value);
      end

      return data;
    end

    function frame:ReplaceData(data)
      frame.dataProvider:Flush();

      for _, rowData in ipairs(data) do
        frame.dataProvider:Insert(rowData);
      end
    end

    if (configuration.OnUpdate) then
      frame.dataProvider:RegisterCallback(
        DataProviderMixin.Event.OnSizeChanged,
        function(owner, newSize)
          configuration.OnUpdate(frame);
        end
      );
    end

    return frame;
  end,
  ---@param parent Frame
  ---@param addFn any
  ---@return table|EditBox|SearchBoxTemplate
  CreateCustomListAdd = function(self, parent, addFn)
    local editBox = CreateFrame("EditBox", nil, parent, "SearchBoxTemplate");
    editBox.Instructions:SetText("");
    editBox.searchIcon:Hide();
    editBox:SetTextInsets(0, 20, 0, 0);
    editBox:SetWidth(320);
    editBox:SetHeight(30);
    editBox:SetAutoFocus(false);
    editBox:SetPoint("TOPLEFT", 4, 28);
    editBox:SetHyperlinksEnabled(true);
    editBox:SetScript("OnMouseUp", function()
      local _, _, itemLink = GetCursorInfo();

      if (itemLink) then
        editBox:SetText(itemLink);
      end

      ClearCursor();
    end);
    editBox:SetScript("OnEscapePressed", function(self)
      self:ClearFocus();
    end);
    function editBox:AddRow()
      local text = self:GetText();
      text = string.trim(text);

      if (#text == 0) then
        return;
      end

      addFn(text);
    end

    local buttonAdd = CreateFrame("Button", nil, editBox, "UIPanelButtonTemplate");
    editBox.ButtonAdd = buttonAdd;
    buttonAdd:SetText("Add");
    buttonAdd:SetSize(44, 24);
    buttonAdd:SetPoint("TOPLEFT", editBox, "TOPRIGHT", 10, -4);
    buttonAdd:SetScript("OnClick", function()
      editBox:ClearFocus();
      editBox:AddRow();
      editBox:SetText("");
    end);

    editBox:SetScript("OnEnterPressed", function()
      editBox:ClearFocus();
      buttonAdd:Click();
    end);

    return editBox;
  end,
  ---@param text string
  ---@param parent Frame
  ---@return Frame, FontString
  CreateCustomTitle = function(self, text, parent)
    local header = CreateFrame("Frame", "UtilityHubCustomSettingHeader", parent);
    header:SetHeight(50);
    header:SetPoint("TOPLEFT");
    header:SetPoint("TOPRIGHT");

    local label = header:CreateFontString(nil, "OVERLAY");
    label:SetFontObject("GameFontHighlightHuge");
    label:SetPoint("TOPLEFT", 7, -22);
    label:SetText(text);
    label:SetJustifyH("LEFT");

    local myTexture = header:CreateTexture(nil, "ARTWORK");
    myTexture:SetAtlas("Options_HorizontalDivider", TextureKitConstants.UseAtlasSize);
    myTexture:SetPoint("TOPLEFT", 0, -50);

    return header, label;
  end,
  ---@class TabDefinition
  ---@field name string
  ---@field label string
  ---@field CreateFrame fun(parent: Frame, tab: table|Button|MinimalTabTemplate): table|Frame|InsetFrameTemplate

  ---@param name string
  ---@param tabs TabDefinition[]
  ---@param height number
  ---@param parent Frame
  ---@param previous Frame
  ---@return Frame
  CreateCustomTabbedFrame = function(
      self,
      name,
      tabs,
      height,
      parent,
      previous
  )
    local function CreateTab(name, label, parent)
      local tab = CreateFrame("Button", name .. "TabButton", parent, "MinimalTabTemplate");
      tab.Text:SetText(label);
      tab.tabText = label;
      tab:SetWidth(100);

      return tab;
    end

    local frame = CreateFrame("Frame", name, parent);
    frame:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -7);
    frame:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", -15, -7);
    frame:SetHeight(height);

    do -- Borders
      local topLeftTexture = frame:CreateTexture("TOPLEFT");
      frame.TOPLEFT = topLeftTexture;
      topLeftTexture:SetAtlas("Options_Tab_Left", TextureKitConstants.UseAtlasSize);
      topLeftTexture:SetPoint("TOPLEFT", 0, -31);

      local topRightTexture = frame:CreateTexture("TOPRIGHT");
      frame.TOPRIGHT = topRightTexture;
      topRightTexture:SetAtlas("Options_Tab_Right", TextureKitConstants.UseAtlasSize);
      topRightTexture:SetPoint("TOPRIGHT", 0, -31);

      local bottomLeftTexture = frame:CreateTexture("BOTTOMLEFT");
      frame.BOTTOMLEFT = bottomLeftTexture;
      bottomLeftTexture:SetAtlas("Options_Tab_Left", TextureKitConstants.UseAtlasSize);
      bottomLeftTexture:SetPoint("BOTTOMLEFT", 8, -15);
      bottomLeftTexture:SetRotation(math.rad(90));

      local bottomRightTexture = frame:CreateTexture("BOTTOMRIGHT");
      frame.BOTTOMRIGHT = bottomRightTexture;
      bottomRightTexture:SetTexture("Interface/OptionsFrame/Options");
      bottomRightTexture:SetSize(7, 23);
      bottomRightTexture:SetTexCoord(0.5966796875, 0.58984375, 0.0751953125, 0.09765625);
      bottomRightTexture:SetPoint("BOTTOMRIGHT", 0, -7);
      bottomRightTexture:SetRotation(math.rad(180));

      local topTexture = frame:CreateTexture("TOP");
      frame.TOP = topTexture;
      topTexture:SetAtlas("Options_Tab_Middle", TextureKitConstants.UseAtlasSize);
      topTexture:SetPoint("TOPLEFT", topLeftTexture, "TOPRIGHT");
      topTexture:SetPoint("TOPRIGHT", topRightTexture, "TOPLEFT");

      local bottomTexture = frame:CreateTexture("BOTTOM");
      frame.BOTTOM = bottomTexture;
      bottomTexture:SetAtlas("Options_Tab_Middle", TextureKitConstants.UseAtlasSize);
      bottomTexture:SetPoint("BOTTOMLEFT", bottomLeftTexture, "BOTTOMRIGHT", 8, 8);
      bottomTexture:SetPoint("BOTTOMRIGHT", bottomRightTexture, "BOTTOMLEFT", 0, 8);
      bottomTexture:SetRotation(math.rad(180));

      local leftTexture = frame:CreateTexture("LEFT");
      frame.LEFT = leftTexture;
      leftTexture:SetTexture("Interface/OptionsFrame/Options");
      leftTexture:SetSize(2, 15);
      leftTexture:SetTexCoord(0.589844, 0.591, 0.028, 0.04);
      leftTexture:SetPoint("TOPLEFT", topLeftTexture, "BOTTOMLEFT");
      leftTexture:SetPoint("BOTTOMLEFT");

      local rightTexture = frame:CreateTexture("RIGHT");
      frame.RIGHT = rightTexture;
      rightTexture:SetTexture("Interface/OptionsFrame/Options");
      rightTexture:SetSize(3, 15);
      rightTexture:SetTexCoord(0.594, 0.597, 0.094, 0.09765625);
      rightTexture:SetPoint("TOPRIGHT", topRightTexture, "BOTTOMRIGHT");
      rightTexture:SetPoint("BOTTOMRIGHT", bottomRightTexture, "TOPRIGHT");

      ---@param self Frame
      ---@param childFrame Frame
      frame.PositionChildFrame = function(self, childFrame)
        childFrame:SetPoint("TOPLEFT", 7, -37);
        childFrame:SetPoint("TOPRIGHT", -7, -37);
        childFrame:SetPoint("BOTTOMLEFT");
        childFrame:SetPoint("BOTTOMRIGHT");
      end;
    end

    frame.ActivateTab = function(self, tabIndex)
      for index, tab in ipairs(self.tabs) do
        if (index == tabIndex) then
          tab.frame:Show();
        else
          tab.frame:Hide();
        end
      end
    end;

    frame.OnClickTab = function(self, button, tabIndex)
      self:ActivateTab(tabIndex);
      PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
    end

    local previousTab;

    frame.tabsGroup = CreateRadioButtonGroup();
    frame.tabs = {};

    for index, tabData in ipairs(tabs) do
      local tab = CreateTab(
        tabData.name,
        tabData.label,
        frame
      );

      if (index == 1) then
        tab:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, 6);
      else
        tab:SetPoint("TOPLEFT", previousTab, "TOPRIGHT", 6, 0);
      end

      previousTab = tab;

      tab.frame = tabData.CreateFrame(frame, tab);
      tab.frame:Hide();
      frame:PositionChildFrame(tab.frame);

      tinsert(frame.tabs, tab);
    end

    frame.tabsGroup:AddButtons(frame.tabs);
    frame.tabsGroup:SelectAtIndex(1);
    frame.tabsGroup:RegisterCallback(
      ButtonGroupBaseMixin.Event.Selected,
      frame.OnClickTab,
      frame
    );

    frame:ActivateTab(1);

    return frame;
  end,
  ---@param parent Frame
  ---@param text string
  ---@param OnClick fun()
  ---@return table|Button|UIPanelButtonTemplate
  CreateCustomButton = function(
      self,
      parent,
      text,
      OnClick
  )
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate");
    button:SetText(text);
    button:SetSize(130, 30);
    button:SetScript("OnClick", function()
      OnClick();
    end);

    return button;
  end,
  ---comment
  ---@param self any
  ---@param parent Frame
  ---@param r number
  ---@param g number
  ---@param b number
  ---@param labelText string
  ---@param OnValueChange fun(r, g, b)
  ---@return table|Frame
  CreateCustomColorPicker = function(
      self,
      parent,
      labelText,
      OnValueChange
  )
    local field = CreateFrame("Frame", nil, parent);
    field:SetSize(150, 24);
    field.r, field.g, field.b = 0, 0, 0;

    -- Label
    local label = field:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    label:SetPoint("LEFT");
    label:SetText(labelText);

    -- Color square button
    local button = CreateFrame("Button", nil, field);
    button:SetSize(24, 24);
    button:SetPoint("RIGHT");

    local texture = button:CreateTexture(nil, "ARTWORK");
    texture:SetAllPoints();
    texture:SetColorTexture(field.r, field.g, field.b);

    local border = button:CreateTexture(nil, "BACKGROUND");
    border:SetAllPoints();
    border:SetColorTexture(0, 0, 0, 1);
    texture:SetPoint("TOPLEFT", 1, -1);
    texture:SetPoint("BOTTOMRIGHT", -1, 1);

    button:SetScript("OnClick", function()
      local info = {
        swatchFunc = function()
          field.r, field.g, field.b = ColorPickerFrame:GetColorRGB();
          texture:SetColorTexture(field.r, field.g, field.b);
          OnValueChange(field.r, field.g, field.b);
        end,
        cancelFunc = function()
          field.r, field.g, field.b =
              ColorPickerFrame.previousValues.r,
              ColorPickerFrame.previousValues.g,
              ColorPickerFrame.previousValues.b;
          texture:SetColorTexture(field.r, field.g, field.b);
          OnValueChange(field.r, field.g, field.b);
        end,
        hasOpacity = false,
        r = field.r,
        g = field.g,
        b = field.b,
      }

      ColorPickerFrame:SetupColorPickerAndShow(info);
    end);

    field.GetColor = function()
      return {
        r = field.r,
        g = field.g,
        b = field.b,
      };
    end;
    field.SetColor = function(self, nr, ng, nb)
      field.r, field.g, field.b = nr, ng, nb;
      texture:SetColorTexture(nr, ng, nb);
    end;

    return field;
  end
};

-- Expose framesHelper for use by pages
UtilityHub.GameOptions.framesHelper = framesHelper;

UtilityHub.GameOptions.Register = function()
  ---@type Preset
  local presetModule = UtilityHub.Addon:GetModule("Preset");
  ---@type MailPreset|nil
  local selectedPreset = nil;

  -- Create Canvas layout main category
  local mainFrame = UtilityHub.OptionsCanvas:Create();
  UtilityHub.GameOptions.category = Settings.RegisterCanvasLayoutCategory(mainFrame, ADDON_NAME);

  do -- Mail Preset Editor (Canvas subcategory)
    -- Create a temporary subcategory for compatibility with the Mail preset editor
    UtilityHub.GameOptions.subcategories.mail = UtilityHub.GameOptions.category;

    do -- Mail > Edit/New Preset
      ---@param type "new"|"edit"
      ---@return Frame
      local function CreatePresetFrame(type)
        local frame = CreateFrame("Frame", type == "new" and "NewPresetFrame" or "EditPresetFrame");

        return frame;
      end

      local presetFrame = CreatePresetFrame("new");
      local title, titleLabel = framesHelper:CreateCustomTitle("New Preset", presetFrame);

      local name, nameEditBox = framesHelper:CreateCustomFormField(
        "name",
        "Name",
        presetFrame,
        title
      );
      local to, toEditBox = framesHelper:CreateCustomFormField(
        "to",
        "To",
        presetFrame,
        name
      );
      local color = framesHelper:CreateCustomColorPicker(
        presetFrame,
        "Color",
        function(r, g, b)
          selectedPreset.color = { r = r, g = g, b = b };
        end
      );

      color:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", -15, -10);

      ---@param itemLinkOrID ItemLink|number
      ---@param list ItemLink[]
      ---@param listFrame SimpleFrame
      local function InsertIntoList(itemLinkOrID, list, listFrame)
        UtilityHub.Helpers.Item:AsyncGetItemLink(itemLinkOrID, function(itemLink)
          local itemLinkID = UtilityHub.Libs.Utils:GetItemIDFromLink(itemLink);

          for _, value in ipairs(list) do
            local customItemLinkID = UtilityHub.Libs.Utils:GetItemIDFromLink(value);

            if (itemLinkID == customItemLinkID) then
              return;
            end
          end

          tinsert(list, itemLink);
          listFrame.dataProvider:Insert(itemLink);
        end);
      end

      local manualInclusionsEditBox, manualExclusionsEditBox;
      local tabbedFrame, itemGroupsFrame, manualInclusionsFrame, manualExclusionsFrame, itemTypesFrame;
      tabbedFrame = framesHelper:CreateCustomTabbedFrame(
        type == "new" and "NewPresetTabbedFrame" or "EditPresetTabbedFrame",
        {
          { -- ItemGroups
            name = "ItemGroups",
            label = "Item groups",
            CreateFrame = function(parent, tab)
              itemGroupsFrame = framesHelper:CreateCustomList(
                "ItemGroupsList",
                parent,
                null,
                {
                  SortComparator = function(a, b)
                    return a.name < b.name;
                  end,
                  GetText = function(rowData)
                    return rowData.name;
                  end,
                  OnCheckedChange = function(rowFrame, rowData)
                    if (tabbedFrame) then
                      tabbedFrame:UpdateTabsText();
                    end
                  end,
                  showCheckbox = true,
                }
              );

              return itemGroupsFrame;
            end
          },
          { -- Inclusions
            name = "ManualInclusions",
            label = "Inclusions",
            CreateFrame = function(parent)
              local textListFrame = CreateFrame("Frame", nil, parent);
              manualInclusionsEditBox = framesHelper:CreateCustomListAdd(
                textListFrame,
                function(itemLinkOrID)
                  InsertIntoList(itemLinkOrID, selectedPreset.custom, manualInclusionsFrame);
                end
              );

              manualInclusionsFrame = framesHelper:CreateCustomList(
                "ManualInclusionsList",
                textListFrame,
                null,
                {
                  SortComparator = function(a, b)
                    local itemNameA = select(3, strfind(a, "|H(.+)|h"));
                    local itemNameB = select(3, strfind(b, "|H(.+)|h"));

                    return itemNameA < itemNameB;
                  end,
                  GetText = function(rowData)
                    return rowData;
                  end,
                  Predicate = function(rowData)
                    return rowData;
                  end,
                  GetHyperlink = function(rowData)
                    return rowData;
                  end,
                  OnRemove = function(rowData, configuration)
                    local predicate = configuration.Predicate(rowData);

                    for index, value in ipairs(selectedPreset.custom) do
                      if (predicate == configuration.Predicate(value)) then
                        tremove(selectedPreset.custom, index);
                        manualInclusionsFrame.dataProvider:RemoveByPredicate(function(elementData)
                          return configuration.Predicate(elementData) == configuration.Predicate(rowData);
                        end);

                        return true;
                      end
                    end

                    return false;
                  end,
                  OnUpdate = function(frame)
                    tabbedFrame:UpdateTabsText();
                  end,
                  hasHyperlink = true,
                  showRemoveIcon = true,
                }
              );

              manualInclusionsEditBox:SetPoint("TOPLEFT", 13, -5);
              manualInclusionsEditBox:SetPoint("TOPRIGHT", -60, -5);

              manualInclusionsFrame:SetPoint("TOPLEFT", manualInclusionsEditBox, "BOTTOMLEFT", 0, -5);
              manualInclusionsFrame:SetPoint("TOPRIGHT", manualInclusionsEditBox.ButtonAdd, "BOTTOMRIGHT", 0, -5);
              manualInclusionsFrame:SetPoint("BOTTOMLEFT");
              manualInclusionsFrame:SetPoint("BOTTOMRIGHT");

              textListFrame.EditBox = manualInclusionsEditBox;
              textListFrame.List = manualInclusionsFrame;

              return textListFrame;
            end
          },
          { -- Exclusions
            name = "ManualExclusions",
            label = "Exclusions",
            CreateFrame = function(parent)
              local textListFrame = CreateFrame("Frame", nil, parent);
              manualExclusionsEditBox = framesHelper:CreateCustomListAdd(
                textListFrame,
                function(itemLinkOrID)
                  InsertIntoList(itemLinkOrID, selectedPreset.exclusion, manualExclusionsFrame);
                end
              );

              manualExclusionsFrame = framesHelper:CreateCustomList(
                "ManualExclusionsList",
                textListFrame,
                null,
                {
                  SortComparator = function(a, b)
                    local itemNameA = select(3, strfind(a, "|H(.+)|h"));
                    local itemNameB = select(3, strfind(b, "|H(.+)|h"));

                    return itemNameA < itemNameB;
                  end,
                  GetText = function(rowData)
                    return rowData;
                  end,
                  Predicate = function(rowData)
                    return rowData;
                  end,
                  GetHyperlink = function(rowData)
                    return rowData;
                  end,
                  OnRemove = function(rowData, configuration)
                    local predicate = configuration.Predicate(rowData);

                    for index, value in ipairs(selectedPreset.exclusion) do
                      if (predicate == configuration.Predicate(value)) then
                        tremove(selectedPreset.exclusion, index);
                        manualExclusionsFrame.dataProvider:RemoveByPredicate(function(elementData)
                          return configuration.Predicate(elementData) == configuration.Predicate(rowData);
                        end);

                        return true;
                      end
                    end

                    return false;
                  end,
                  OnUpdate = function(frame)
                    tabbedFrame:UpdateTabsText();
                  end,
                  hasHyperlink = true,
                  showRemoveIcon = true,
                }
              );

              manualExclusionsEditBox:SetPoint("TOPLEFT", 13, -5);
              manualExclusionsEditBox:SetPoint("TOPRIGHT", -60, -5);

              manualExclusionsFrame:SetPoint("TOPLEFT", manualExclusionsEditBox, "BOTTOMLEFT", 0, -5);
              manualExclusionsFrame:SetPoint("TOPRIGHT", manualExclusionsEditBox.ButtonAdd, "BOTTOMRIGHT", 0, -5);
              manualExclusionsFrame:SetPoint("BOTTOMLEFT");
              manualExclusionsFrame:SetPoint("BOTTOMRIGHT");

              textListFrame.EditBox = manualExclusionsEditBox;
              textListFrame.List = manualExclusionsFrame;

              return textListFrame;
            end
          },
          { -- Item types
            name = "ItemTypes",
            label = "Item types",
            CreateFrame = function(parent)
              local textListFrame = CreateFrame("Frame", nil, parent);

              local buttonAdd = CreateFrame("Button", nil, textListFrame, "UIPanelButtonTemplate");
              buttonAdd:SetText("Add");
              buttonAdd:SetSize(44, 24);
              buttonAdd:SetPoint("TOPRIGHT", textListFrame, "TOPRIGHT", 0, 0);
              buttonAdd:SetScript("OnClick", function()
                ---@param class AuctionHouseItemClassStructureClass
                ---@param subclass? AuctionHouseItemClassStructureSubClass
                ---@return number
                local function OnClickMenu(class, subclass)
                  local classID, subclassID = class.classID, subclass and subclass.subClassID or nil;

                  for _, value in ipairs(selectedPreset.itemType) do
                    if (value.classID == classID and value.subclassID == subclassID) then
                      return MenuResponse.Close;
                    end
                  end

                  ---@type MailPresetItemType
                  local data = { classID = classID, subclassID = subclassID };
                  tinsert(selectedPreset.itemType, data);
                  itemTypesFrame.dataProvider:Insert(data);

                  return MenuResponse.Close;
                end

                MenuUtil.CreateContextMenu(buttonAdd, function(owner, rootDescription)
                  rootDescription:CreateTitle("Item types");

                  for _, class in pairs(UtilityHub.Constants.AuctionHouseItemClassStructure) do
                    local classButton = rootDescription:CreateButton(class.name);

                    if (#class.subClasses > 0) then
                      for _, subClass in ipairs(class.subClasses) do
                        local subClassButton = classButton:CreateButton(subClass.name);
                        subClassButton:SetResponder(function(data, menuInputData, menu)
                          return OnClickMenu(class, subClass);
                        end);
                      end
                    end

                    classButton:SetResponder(function(data, menuInputData, menu)
                      return OnClickMenu(class, nil);
                    end);
                  end
                end);
              end);

              itemTypesFrame = framesHelper:CreateCustomList(
                "ItemTypesList",
                textListFrame,
                null,
                {
                  ---@param a MailPresetItemType
                  ---@param b MailPresetItemType
                  SortComparator = function(a, b)
                    if (a.classID == b.classID) then
                      if (not a.subclassID and b.subclassID) then
                        return true;
                      elseif (a.subclassID and not b.subclassID) then
                        return false;
                      end

                      return a.subclassID < b.subclassID;
                    end

                    return a.classID < b.classID;
                  end,
                  ---@param rowData MailPresetItemType
                  GetText = function(rowData)
                    local class, subclass = UtilityHub.Helpers.Item:GetClassAndSubclass(
                      rowData.classID,
                      rowData.subclassID
                    );
                    local text = tostring(class.name);

                    if (subclass) then
                      text = text .. " > " .. subclass.name;
                    end

                    return text;
                  end,
                  ---@param rowData MailPresetItemType
                  ---@return string
                  Predicate = function(rowData)
                    local text = tostring(rowData.classID);

                    if (rowData.subclassID) then
                      text = text .. "-" .. tostring(rowData.subclassID);
                    end

                    return text;
                  end,
                  OnRemove = function(rowData, configuration)
                    local predicate = configuration.Predicate(rowData);

                    for index, value in ipairs(selectedPreset.itemType) do
                      if (predicate == configuration.Predicate(value)) then
                        tremove(selectedPreset.itemType, index);
                        itemTypesFrame.dataProvider:RemoveByPredicate(function(elementData)
                          return configuration.Predicate(elementData) == configuration.Predicate(rowData);
                        end);

                        return true;
                      end
                    end

                    return false;
                  end,
                  OnUpdate = function(frame)
                    tabbedFrame:UpdateTabsText();
                  end,
                  showRemoveIcon = true,
                }
              );

              itemTypesFrame:SetPoint("TOPRIGHT", buttonAdd, "BOTTOMRIGHT", 0, -5);
              itemTypesFrame:SetPoint("BOTTOMLEFT");
              itemTypesFrame:SetPoint("BOTTOMRIGHT");

              textListFrame.EditBox = manualExclusionsEditBox;
              textListFrame.List = itemTypesFrame;

              return textListFrame;
            end
          },
        },
        400,
        presetFrame,
        to
      );

      function tabbedFrame:UpdateTabsText()
        local tab;

        do -- ItemGroups
          tab = tabbedFrame.tabs[1];

          local count = 0;

          for _, value in tab.frame.dataProvider:Enumerate() do
            if (value.checked) then
              count = count + 1;
            end
          end

          local newTitle = string.format("Item groups (%s)", count);
          tab.Text:SetText(newTitle);
          tab.tabText = newTitle;
        end

        do -- Inclusions
          tab = tabbedFrame.tabs[2];

          local newTitle = string.format("Inclusions (%s)", #tab.frame.List:GetData());
          tab.Text:SetText(newTitle);
          tab.tabText = newTitle;
        end

        do -- Exclusions
          tab = tabbedFrame.tabs[3];

          local newTitle = string.format("Exclusions (%s)", #tab.frame.List:GetData());
          tab.Text:SetText(newTitle);
          tab.tabText = newTitle;
        end

        do -- ItemTypes
          tab = tabbedFrame.tabs[4];

          local newTitle = string.format("Item types (%s)", #tab.frame.List:GetData());
          tab.Text:SetText(newTitle);
          tab.tabText = newTitle;
        end
      end

      local saveButton = framesHelper:CreateCustomButton(
        presetFrame,
        "Save",
        function()
          local itemGroups = {};

          for _, group in ipairs(itemGroupsFrame:GetData()) do
            itemGroups[group.key] = group.checked;
          end

          local result = presetModule:SavePreset({
            id = selectedPreset.id or nil,
            name = nameEditBox:GetText(),
            to = toEditBox:GetText(),
            custom = manualInclusionsFrame:GetData(),
            itemGroups = itemGroups,
            exclusion = manualExclusionsFrame:GetData(),
            color = color:GetColor(),
            itemType = itemTypesFrame:GetData(),
          });

          if (result) then
            -- Clear temp preset
            UtilityHub.tempSelectedPreset = nil;
            -- Go back to main settings (which will show Mail page)
            UtilityHub.GameOptions.OpenConfig();
          end
        end
      );

      saveButton:SetPoint("BOTTOMRIGHT", -12, 12);

      UtilityHub.GameOptions.subcategories.preset = Settings.RegisterCanvasLayoutSubcategory(
        UtilityHub.GameOptions.subcategories.mail,
        presetFrame,
        "Preset"
      );

      EventRegistry:RegisterCallback("Settings.CategoryChanged", function(...)
        local _, categoryData = ...;
        local tempItemGroups = {};

        if (categoryData and categoryData.name == "Preset") then
          local text = "New Preset";

          -- Use temp variable set by MailPage
          selectedPreset = UtilityHub.tempSelectedPreset;

          if (selectedPreset) then
            text = "Editing Preset";
          else
            selectedPreset = presetModule:GetNewEmptyPreset();
          end

          for itemGroupName, itemGroup in UtilityHub.Libs.Utils:OrderedPairs(presetModule.ItemGroupOptions) do
            tinsert(
              tempItemGroups,
              {
                checked = selectedPreset.itemGroups[itemGroupName] or false,
                name = itemGroup.label,
                key = itemGroupName,
              }
            );
          end

          -- Update UtilityHub.tempPreset with selectedPreset data (already done in OnEditClicked)
          -- or set to empty for new preset (done if no selectedPreset)
          titleLabel:SetText(text);
          nameEditBox:SetText(selectedPreset.name);
          toEditBox:SetText(selectedPreset.to);
          local r, g, b = 1, 1, 1;

          if (selectedPreset.color) then
            r = selectedPreset.color.r or r;
            g = selectedPreset.color.g or g;
            b = selectedPreset.color.b or b;
          end

          color:SetColor(r, g, b);

          itemGroupsFrame:ReplaceData(tempItemGroups);

          manualInclusionsEditBox:SetText("");
          manualInclusionsFrame:ReplaceData(selectedPreset.custom or {});
          manualExclusionsFrame:ReplaceData(selectedPreset.exclusion or {});
          itemTypesFrame:ReplaceData(selectedPreset.itemType or {});

          tabbedFrame:UpdateTabsText();
        else
          selectedPreset = nil;
          UtilityHub.tempSelectedPreset = nil;
        end
      end);
    end
  end

  Settings.RegisterAddOnCategory(UtilityHub.GameOptions.category);
end
