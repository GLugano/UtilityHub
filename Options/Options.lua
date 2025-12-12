local ADDON_NAME = ...;
---@type UtilityHub
local UH = LibStub('AceAddon-3.0'):GetAddon(ADDON_NAME);
local order = 0;

local function GetNextOrder()
  order = order + 1;
  return order;
end

UH.Options = {
  name = ADDON_NAME,
  type = "group",
  args = {
    tooltipGroup = {
      name = "Tooltip",
      type = "group",
      order = GetNextOrder(),
      args = {
        tooltipGroupTitle = {
          type = "description",
          name = "Module: Tooltip",
          fontSize = "large",
          order = GetNextOrder(),
        },
        tooltipGroupSeparator = {
          type = "header",
          name = "",
          order = GetNextOrder(),
        },
        tooltipSimpleStats = {
          type = "toggle",
          name = "Enable",
          desc = "Change the way most stats are shown in the tooltip",
          order = GetNextOrder(),
          get = function() return UH.db.global.options.simpleStatsTooltip end,
          set = function(_, val)
            UH.db.global.options.simpleStatsTooltip = val;
            UH.Events:TriggerEvent("OPTIONS_CHANGED", "simpleStatsTooltip", val);
          end,
        },
      },
    },
    autoBuyGroup = {
      name = "AutoBuy",
      type = "group",
      order = GetNextOrder(),
      args = {
        autoBuyGroupTitle = {
          type = "description",
          name = "Module: AutoBuy",
          fontSize = "large",
          order = GetNextOrder(),
        },
        autoBuyGroupSeparator = {
          type = "header",
          name = "",
          order = GetNextOrder(),
        },
        autoBuy = {
          type = "toggle",
          name = "Enable",
          desc =
          "Enable the functionality to autobuy specific limited stock items from vendors when the window is opened",
          order = GetNextOrder(),
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
          order = GetNextOrder(),
          width = "full",
          set = function(_, val)
            UH.db.global.options.autoBuyList = C_EncodingUtil.DeserializeJSON(val);
          end,
          get = function()
            return C_EncodingUtil.SerializeJSON(UH.db.global.options.autoBuyList or {});
          end,
          ---@type ItemListArg
          arg = {
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
                  OnSuccess(itemLink);
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
        }
      },
    },
    mailGroup = {
      name = "Mail",
      type = "group",
      order = GetNextOrder(),
      args = {
        mailGroupTitle = {
          type = "description",
          name = "Module: Mail",
          fontSize = "large",
          order = GetNextOrder(),
        },
        mailGroupSeparator = {
          type = "header",
          name = "",
          order = GetNextOrder(),
        },
        mailCharacters = {
          type = "input",
          dialogControl = "ItemList",
          name = "ConfigurableItemList",
          order = GetNextOrder(),
          width = "full",
          set = function(_, val)
            UH.db.global.characters = C_EncodingUtil.DeserializeJSON(val);
          end,
          get = function()
            return C_EncodingUtil.SerializeJSON(UH.db.global.characters or {});
          end,
          arg = {
            HideAdd = true,
            CustomizeRowElement = function(self, frame, rowData, helpers)
              frame:SetText(rowData.name);

              if (rowData.className ~= nil) then
                local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[rowData.className];

                if (color) then
                  frame:GetFontString():SetTextColor(color.r, color.g, color.b);
                end
              end

              if (rowData == UnitName("player")) then
                return { skipFontStringPoints = false };
              else
                frame:GetFontString():SetPoint("LEFT", 6, 0);
                frame:GetFontString():SetPoint("RIGHT", -20, 0);
                helpers.CreateDeleteIconButton(self, frame, rowData);

                return { skipFontStringPoints = true };
              end
            end
          }
        }
      },
    },
  },
};
