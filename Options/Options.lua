local ADDON_NAME, addonTable = ...;
---@type UtilityHub
local UH = LibStub('AceAddon-3.0'):GetAddon(ADDON_NAME);

function addonTable.GenerateOptions()
  local order = {};

  local function GetNextOrder(key)
    order[key] = (order[key] or 0) + 1;
    return order[key];
  end

  local function GenerateSeparator(key, name)
    return {
      type = "header",
      name = name or "",
      order = GetNextOrder(key),
    };
  end

  local function GenerateSpacer(key)
    return {
      type = "description",
      name = " ",
      order = GetNextOrder(key),
      fontSize = "large",
    };
  end

  -- Default
  tinsert(UH.Options, {
    key = ADDON_NAME,
    name = ADDON_NAME,
    root = true,
    group = {
      type = "group",
      order = GetNextOrder("default"),
      args = {
        addonDescription1 = {
          type = "description",
          name =
          "I did this addon because i like to code and to solve problems without WA. If you have any ideas, contact me.",
          order = GetNextOrder("default"),
          fontSize = "medium",
        },
        spacer1 = GenerateSpacer("default"),
        addonDescription2 = {
          type = "description",
          name = "For the addon options, check the options in the left.",
          order = GetNextOrder("default"),
          fontSize = "large",
        },
        spacer2 = GenerateSpacer("default"),
        addonTitle = {
          type = "description",
          name = "Author: Cacetinho - Nightslayer",
          order = GetNextOrder("default"),
          fontSize = "medium",
        },
      },
    },
  });

  -- Tooltip
  tinsert(UH.Options, {
    key = ADDON_NAME .. "_Tooltip",
    name = "Tooltip",
    root = false,
    group = {
      name = "Tooltip",
      type = "group",
      order = GetNextOrder("tooltip"),
      args = {
        tooltipGroupSeparator = GenerateSeparator("tooltip"),
        tooltipSimpleStats = {
          type = "toggle",
          name = "Enable",
          desc = "Change the way most stats are shown in the tooltip",
          order = GetNextOrder("tooltip"),
          get = function() return UH.db.global.options.simpleStatsTooltip end,
          set = function(_, val)
            UH.db.global.options.simpleStatsTooltip = val;
            UH.Events:TriggerEvent("OPTIONS_CHANGED", "simpleStatsTooltip", val);
          end,
        },
      },
    },
  });

  -- AutoBuy
  tinsert(UH.Options, {
    key = ADDON_NAME .. "_AutoBuy",
    name = "AutoBuy",
    root = false,
    group = {
      name = "AutoBuy",
      type = "group",
      order = GetNextOrder("autoBuy"),
      args = {
        autoBuy = {
          type = "toggle",
          name = "Enable",
          desc =
          "Enable the functionality to autobuy specific limited stock items from vendors when the window is opened",
          order = GetNextOrder("autoBuy"),
          get = function() return UH.db.global.options.autoBuy end,
          set = function(_, val)
            UH.db.global.options.autoBuy = val;
            UH.Events:TriggerEvent("OPTIONS_CHANGED", "autoBuy", val);
          end,
        },
        autoBuyList = {
          type = "input",
          dialogControl = "ItemList",
          name = "AutoBuyItemList",
          order = GetNextOrder("autoBuy"),
          width = "full",
          set = function(_, val)
            UH.db.global.options.autoBuyList = C_EncodingUtil.DeserializeJSON(val);
          end,
          get = function()
            return C_EncodingUtil.SerializeJSON(UH.db.global.options.autoBuyList or {});
          end,
          ---@type ItemListArg
          arg = {
            widthSizeType = "full",
            heightSizeType = "full",
            OnEnterRow = function(self, frame, rowData)
              GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
              GameTooltip:SetHyperlink(rowData);
              GameTooltip:Show();
            end,
            OnLeaveRow = function(self, frame)
              if (not GameTooltip:IsOwned(frame)) then
                return;
              end

              GameTooltip:Hide();
            end,
            CreateNewRow = function(self, text, OnSuccess, OnError)
              UH.Helpers:AsyncGetItemInfo(text, function(itemLink)
                if (itemLink) then
                  OnSuccess(itemLink, function(error)
                    if (error == "ROW_ALREADY_EXISTS") then
                      UH.Helpers:ShowNotification("Item already added to the list");
                    end
                  end);
                else
                  OnError();
                end
              end);
            end,
            CustomizeRowElement = function(self, frame, rowData, helpers)
              frame:SetText(rowData);
              frame:GetFontString():SetPoint("LEFT", 6, 0);
              frame:GetFontString():SetPoint("RIGHT", -20, 0);
              helpers.CreateDeleteIconButton(self, frame, rowData);

              return { skipFontStringPoints = true };
            end
          },
        },
      },
    },
  });

  -- Mail

  ---@type Preset
  local presetModule = UH:GetModule("Preset");
  UH.tempPreset = presetModule:GetNewEmptyPreset();

  local function GenerateNewPreset()
    return {
      name = function()
        return UH.tempPreset and UH.tempPreset.id and "Editing preset" or "New preset";
      end,
      type = "group",
      order = GetNextOrder("mail"),
      args = {
        newPresetTitle = {
          type = "description",
          name = "New preset",
          fontSize = "large",
          order = GetNextOrder("mail"),
        },
        newPresetNameInput = {
          type = "input",
          name = "Name",
          order = GetNextOrder("mail"),
          width = "full",
          get = function()
            return UH.tempPreset.name;
          end,
          set = function(_, value)
            UH.tempPreset.name = value;
          end
        },
        newPresetToInput = {
          type = "input",
          name = "To",
          width = "full",
          order = GetNextOrder("mail"),
          get = function()
            return UH.tempPreset.to;
          end,
          set = function(_, value)
            UH.tempPreset.to = value;
          end
        },
        newPresetSeparator = GenerateSeparator("mail", "Items"),
        newPresetItemGroups = {
          name = function()
            local count = 0;

            for _, group in ipairs(UH.tempPreset.itemGroups) do
              if (group.checked) then
                count = count + 1;
              end
            end

            return string.format("Item groups: %s selected", count);
          end,
          type = "group",
          order = GetNextOrder("mail"),
          inline = true,
          args = {
            presetItemGroupList = {
              type = "input",
              dialogControl = "ItemList",
              name = "PresetItemGroupList",
              order = GetNextOrder("mail"),
              width = "full",
              set = function(_, val)
                UH.tempPreset.itemGroups = C_EncodingUtil.DeserializeJSON(val);
              end,
              get = function()
                return C_EncodingUtil.SerializeJSON(UH.tempPreset.itemGroups or {});
              end,
              ---@type ItemListArg
              arg = {
                hideAdd = true,
                widthSizeType = "manual",
                heightSizeType = "manual",
                width = 410,
                height = 250,
                GetRowIndex = function(self, rows, rowData)
                  for index, loopItem in ipairs(rows) do
                    if (loopItem.name == rowData.name) then
                      return index;
                    end
                  end

                  return nil;
                end,
                CustomizeRowElement = function(self, frame, rowData, helpers)
                  frame:SetText(rowData.name);
                  frame:GetFontString():SetTextColor(1, 1, 1);
                  frame:GetFontString():SetPoint("LEFT", 40, 0);
                  frame:GetFontString():SetPoint("RIGHT", -6, 0);

                  helpers.CreateCheckbox(self, frame, rowData);

                  return { skipFontStringPoints = true };
                end
              },
            },
          },
        },
        newPresetManualInclusions = {
          name = function()
            return string.format("Manual inclusions: %s selected", #UH.tempPreset.custom);
          end,
          type = "group",
          order = GetNextOrder("mail"),
          inline = true,
          args = {
            presetManualInclusionsList = {
              type = "input",
              dialogControl = "ItemList",
              name = "PresetManualInclusionsList",
              order = GetNextOrder("mail"),
              width = "full",
              set = function(_, val)
                UH.tempPreset.custom = C_EncodingUtil.DeserializeJSON(val);
              end,
              get = function()
                return C_EncodingUtil.SerializeJSON(UH.tempPreset.custom or {});
              end,
              ---@type ItemListArg
              arg = {
                widthSizeType = "manual",
                heightSizeType = "manual",
                width = 400,
                height = 250,
                OnEnterRow = function(self, frame, rowData)
                  GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
                  GameTooltip:SetHyperlink(rowData);
                  GameTooltip:Show();
                end,
                OnLeaveRow = function(self, frame)
                  if (not GameTooltip:IsOwned(frame)) then
                    return;
                  end

                  GameTooltip:Hide();
                end,
                CreateNewRow = function(self, text, OnSuccess, OnError)
                  UH.Helpers:AsyncGetItemInfo(text, function(itemLink)
                    if (itemLink) then
                      OnSuccess(itemLink, function(error)
                        if (error == "ROW_ALREADY_EXISTS") then
                          UH.Helpers:ShowNotification("Item already added to the list");
                        end
                      end);
                    else
                      OnError();
                    end
                  end);
                end,
                CustomizeRowElement = function(self, frame, rowData, helpers)
                  frame:SetText(rowData);
                  frame:GetFontString():SetTextColor(1, 1, 1);
                  frame:GetFontString():SetPoint("LEFT", 6, 0);
                  frame:GetFontString():SetPoint("RIGHT", -20, 0);

                  helpers.CreateDeleteIconButton(self, frame, rowData);

                  return { skipFontStringPoints = true };
                end
              },
            },
          },
        },
        newPresetManualExclusions = {
          name = function()
            return string.format("Manual exclusions: %s selected", #UH.tempPreset.exclusion);
          end,
          type = "group",
          order = GetNextOrder("mail"),
          inline = true,
          args = {
            presetManualExclusionsList = {
              type = "input",
              dialogControl = "ItemList",
              name = "PresetManualExclusionsList",
              order = GetNextOrder("mail"),
              width = "full",
              set = function(_, val)
                UH.tempPreset.exclusion = C_EncodingUtil.DeserializeJSON(val);
              end,
              get = function()
                return C_EncodingUtil.SerializeJSON(UH.tempPreset.exclusion or {});
              end,
              ---@type ItemListArg
              arg = {
                widthSizeType = "manual",
                heightSizeType = "manual",
                width = 400,
                height = 250,
                OnEnterRow = function(self, frame, rowData)
                  GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
                  GameTooltip:SetHyperlink(rowData);
                  GameTooltip:Show();
                end,
                OnLeaveRow = function(self, frame)
                  if (not GameTooltip:IsOwned(frame)) then
                    return;
                  end

                  GameTooltip:Hide();
                end,
                CreateNewRow = function(self, text, OnSuccess, OnError)
                  UH.Helpers:AsyncGetItemInfo(text, function(itemLink)
                    if (itemLink) then
                      OnSuccess(itemLink, function(error)
                        if (error == "ROW_ALREADY_EXISTS") then
                          UH.Helpers:ShowNotification("Item already added to the list");
                        end
                      end);
                    else
                      OnError();
                    end
                  end);
                end,
                CustomizeRowElement = function(self, frame, rowData, helpers)
                  frame:SetText(rowData);
                  frame:GetFontString():SetTextColor(1, 1, 1);
                  frame:GetFontString():SetPoint("LEFT", 6, 0);
                  frame:GetFontString():SetPoint("RIGHT", -20, 0);

                  helpers.CreateDeleteIconButton(self, frame, rowData);

                  return { skipFontStringPoints = true };
                end
              },
            },
          },
        },
        newPresetSave = {
          type = "execute",
          name = "Save",
          order = GetNextOrder("mail"),
          width = 0.8,
          disabled = false,
          func = function(info, value)
            local itemGroups = {};

            for _, group in ipairs(UH.tempPreset.itemGroups) do
              itemGroups[group.key] = group.checked;
            end

            local result = presetModule:SavePreset({
              name = UH.tempPreset.name,
              to = UH.tempPreset.to,
              custom = UH.tempPreset.custom,
              itemGroups = itemGroups,
              exclusion = UH.tempPreset.exclusion,
            }, UH.tempPreset.id);

            if (result) then
              UH.tempPreset = presetModule:GetNewEmptyPreset();
              UH.AceConfigDialog:SelectGroup(ADDON_NAME .. "_Mail", "mailPresetsGroup");
            end
          end
        },
      }
    };
  end

  tinsert(UH.Options, {
    key = ADDON_NAME .. "_Mail",
    name = "Mail",
    root = false,
    group = {
      name = "Mail",
      type = "group",
      order = GetNextOrder("mail"),
      args = {
        mailCharactersGroup = {
          name = "Characters",
          type = "group",
          order = GetNextOrder("mail"),
          args = {
            mailCharactersTitle = {
              type = "description",
              name = "Module: Mail - Characters",
              fontSize = "large",
              order = GetNextOrder("mail"),
            },
            mailCharactersSeparator = GenerateSeparator("mail"),
            mailCharacters = {
              type = "input",
              dialogControl = "ItemList",
              name = "ConfigurableItemList",
              order = GetNextOrder("mail"),
              width = "full",
              set = function(_, val)
                UH.db.global.characters = C_EncodingUtil.DeserializeJSON(val);
              end,
              get = function()
                return C_EncodingUtil.SerializeJSON(UH.db.global.characters or {});
              end,
              ---@type ItemListArg
              arg = {
                hideAdd = true,
                widthSizeType = "side",
                heightSizeType = "full",
                GetRowIndex = function(self, rows, rowData)
                  for index, loopItem in ipairs(rows) do
                    if (loopItem.name == rowData.name) then
                      return index;
                    end
                  end

                  return nil;
                end,
                CustomizeRowElement = function(self, frame, rowData, helpers)
                  local widget = self;
                  local options = {
                    { text = "Main/alt",  value = UH.Enums.CHARACTER_GROUP.MAIN_ALT },
                    { text = "Bank",      value = UH.Enums.CHARACTER_GROUP.BANK },
                    { text = "Ungrouped", value = UH.Enums.CHARACTER_GROUP.UNGROUPED },
                  };

                  function CreateDropDown()
                    if (not frame.customElements[widget.name].DropDownGroup) then
                      frame.customElements[widget.name].DropDownGroup = CreateFrame(
                        "Frame",
                        string.format("MailCharacters%sDropDownGroup", rowData.name),
                        frame,
                        "UIDropDownMenuTemplate"
                      );
                      frame.customElements[widget.name].DropDownGroup:SetPoint("TOPRIGHT", -10, 1);

                      local function OnSelect(self, arg1)
                        widget.items[widget:GetRowIndex(widget.items, rowData)].group = arg1 or
                            UH.Enums.CHARACTER_GROUP.UNGROUPED;
                        widget:FireValueChanged();
                      end

                      local function Init(self, level)
                        for _, item in ipairs(options) do
                          local info = UIDropDownMenu_CreateInfo();
                          info.text = item.text;
                          info.value = item.value;
                          info.arg1 = item.value;
                          info.func = OnSelect;
                          UIDropDownMenu_AddButton(info, level);
                        end
                      end

                      UIDropDownMenu_Initialize(frame.customElements[widget.name].DropDownGroup, Init);
                      UIDropDownMenu_SetWidth(frame.customElements[widget.name].DropDownGroup, 100);
                    end

                    local selectedValue = rowData.group or UH.Enums.CHARACTER_GROUP.UNGROUPED;
                    local selectedOption = options[1];

                    for _, option in pairs(options) do
                      if (option.value == selectedValue) then
                        selectedOption = option;
                      end
                    end

                    UIDropDownMenu_SetSelectedValue(frame.customElements[widget.name].DropDownGroup, selectedOption
                      .value);
                    UIDropDownMenu_SetText(frame.customElements[widget.name].DropDownGroup, selectedOption.text);
                  end

                  frame:SetText(rowData.name);
                  frame:GetFontString():SetPoint("LEFT", 6, 0);
                  frame:GetFontString():SetPoint("RIGHT", -20, 0);

                  local color = UH.Helpers:GetRGBFromClassName(rowData.className);

                  frame:GetFontString():SetTextColor(color.r, color.g, color.b);

                  if (rowData.name ~= UnitName("player")) then
                    helpers.CreateDeleteIconButton(self, frame, rowData);
                  end

                  CreateDropDown();

                  return { skipFontStringPoints = true };
                end
              }
            },
          },
        },
        mailPresetsGroup = {
          name = "Presets",
          type = "group",
          order = GetNextOrder("mail"),
          args = {
            mailPresetsTitle = {
              type = "description",
              name = "Module: Mail - Presets",
              fontSize = "large",
              order = GetNextOrder("mail"),
            },
            mailPresetsSeparator = GenerateSeparator("mail"),
            presetsList = {
              type = "input",
              dialogControl = "ItemList",
              name = "PresetsList",
              order = GetNextOrder("mail"),
              width = "full",
              set = function(_, val)
                UH.db.global.presets = C_EncodingUtil.DeserializeJSON(val);
              end,
              get = function()
                return C_EncodingUtil.SerializeJSON(UH.db.global.presets or {});
              end,
              ---@type ItemListArg
              arg = {
                hideAdd = true,
                widthSizeType = "side",
                heightSizeType = "full",
                CustomizeRowElement = function(self, frame, rowData, helpers)
                  local widget = self;

                  frame:SetText(rowData.name);
                  frame:GetFontString():SetTextColor(1, 1, 1);
                  frame:GetFontString():SetPoint("LEFT", 6, 0);
                  frame:GetFontString():SetPoint("RIGHT", -20, 0);

                  local function CreateEditIconButton()
                    frame.customElements[widget.name].EditIconButton = CreateFrame("Button", nil, frame);
                    -- frame.customElements[widget.name].EditIconButton:SetNormalAtlas("common-icon-edit");
                    -- frame.texture = CreateText
                    frame.customElements[widget.name].EditIconButton:SetNormalTexture("Interface\\WorldMap\\GEAR_64GREY");
                    frame.customElements[widget.name].EditIconButton:SetPoint("TOPRIGHT", -28, -4);
                    frame.customElements[widget.name].EditIconButton:SetSize(18, 18);
                    frame.customElements[widget.name].EditIconButton:SetScript("OnClick", function()
                      local index = widget:GetRowIndex(widget.items, rowData);
                      local data = widget.items[index];

                      UH.tempPreset = {
                        id = index,
                        name = data.name,
                        to = data.to,
                        itemGroups = {},
                        custom = data.custom or {},
                        exclusion = data.exclusion or {},
                      };

                      for itemGroupName, itemGroup in UH.UTILS:OrderedPairs(presetModule.ItemGroupOptions) do
                        tinsert(
                          UH.tempPreset.itemGroups,
                          {
                            checked = data.itemGroups[itemGroupName] or false,
                            name = itemGroup.label,
                            key = itemGroupName,
                          }
                        );
                      end

                      UH.AceConfigDialog:SelectGroup(ADDON_NAME .. "_Mail", "mailPresetsGroup", "newPreset");
                    end);
                    frame.customElements[widget.name].EditIconButton:SetScript("OnEnter", function()
                      local el = frame.customElements[widget.name].EditIconButton;

                      if (el) then
                        GameTooltip:SetOwner(el, "ANCHOR_RIGHT");
                        GameTooltip:SetText("Edit");
                        GameTooltip:Show();
                      end
                    end);
                    frame.customElements[widget.name].EditIconButton:SetScript("OnLeave", function()
                      local el = frame.customElements[widget.name].EditIconButton;

                      if (not GameTooltip:IsOwned(el)) then
                        return;
                      end

                      GameTooltip:Hide();
                    end);

                    return frame.customElements[widget.name].EditIconButton;
                  end

                  helpers.CreateDeleteIconButton(self, frame, rowData);
                  CreateEditIconButton();

                  return { skipFontStringPoints = true };
                end
              },
            },
            newPreset = GenerateNewPreset(),
          },
        },
      },
    },
  });

  -- Cooldowns
  tinsert(UH.Options, {
    key = ADDON_NAME .. "_Cooldowns",
    name = "Cooldowns",
    root = false,
    group = {
      name = "Cooldowns",
      type = "group",
      order = GetNextOrder("cooldowns"),
      args = {
        cooldowns = {
          type = "toggle",
          name = "Enable",
          desc =
          "Enable tracking and listing of all character cooldowns (with the addon active)",
          order = GetNextOrder("cooldowns"),
          width = "full",
          get = function() return UH.db.global.options.cooldowns end,
          set = function(_, val)
            UH.db.global.options.cooldowns = val;
            UH.Events:TriggerEvent("OPTIONS_CHANGED", "cooldowns", val);
          end,
        },
        cooldownsPlaySound = {
          type = "toggle",
          name = "Play sound when a cooldown is ready",
          order = GetNextOrder("cooldowns"),
          width = "full",
          get = function() return UH.db.global.options.cooldownPlaySound end,
          set = function(_, val)
            UH.db.global.options.cooldownPlaySound = val;
            UH.Events:TriggerEvent("OPTIONS_CHANGED", "cooldownPlaySound", val);
          end,
        },
      },
    },
  });
end
