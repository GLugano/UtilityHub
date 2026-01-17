local ADDON_NAME = ...;
---@type UtilityHub
local UH = LibStub('AceAddon-3.0'):GetAddon(ADDON_NAME);
local moduleName = 'Characters';
---@class Characters
---@diagnostic disable-next-line: undefined-field
local Module = UH:NewModule(moduleName);

function Module:OnEnable()
  -- TODO
end

function Module:GetAccountCharactersGeneratorFunction()
  local refUH = UH;

  return function(owner, rootDescription)
    local groups = {
      [UH.Enums.CHARACTER_GROUP.MAIN_ALT] = {},
      [UH.Enums.CHARACTER_GROUP.BANK] = {},
      [UH.Enums.CHARACTER_GROUP.UNGROUPED] = {},
    };

    for i, row in pairs(refUH.db.global.characters) do
      local group = row.group or UH.Enums.CHARACTER_GROUP.UNGROUPED;
      local groupList = groups[group];

      tinsert(groupList, row);
    end

    local indexGroupWithData = 1;

    for groupID, group in pairs(groups) do
      table.sort(group, function(a, b)
        return a.name < b.name;
      end);

      if (#group > 0) then
        if (indexGroupWithData ~= 1) then
          rootDescription:CreateDivider();
        end

        indexGroupWithData = indexGroupWithData + 1;
        rootDescription:CreateTitle("• " .. UH.Enums.CHARACTER_GROUP_TEXT[groupID]);

        for _, character in pairs(group) do
          local characterButton = rootDescription:CreateButton(
            character.name,
            function() Module:StartMail(character.name) end
          );
          characterButton:AddInitializer(function(button, description, menu)
            local color = UH.Helpers:GetRGBFromClassName(character.className);
            button.fontString:SetTextColor(color.r, color.g, color.b);
          end);
          characterButton:SetEnabled(character.name ~= UnitName("player"));
        end
      end
    end
  end
end

function Module:StartMail(characterName)
  MailFrameTab_OnClick(_G["MailFrameTab2"]);
  SendMailNameEditBox:SetText(characterName);
end
