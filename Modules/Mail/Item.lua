local ADDON_NAME, addonTable = ...;
local moduleName = 'Item';
---@class Item : AceModule
local Module = UtilityHub.Addon:NewModule(moduleName);

function Module:GetLoadItemGeneratorFunction()
  return function(owner, rootDescription)
    rootDescription:CreateTitle("Item types");

    for _, class in pairs(UtilityHub.Constants.AuctionHouseItemClassStructure) do
      local classButton = rootDescription:CreateButton(class.name);

      if (#class.subClasses > 0) then
        for _, subClass in ipairs(class.subClasses) do
          local subClassButton = classButton:CreateButton(subClass.name);
          subClassButton:SetResponder(function(data, menuInputData, menu)
            Module:Execute(class, subClass);
            return MenuResponse.Open;
          end);
        end
      end

      classButton:SetResponder(function(data, menuInputData, menu)
        Module:Execute(class);
        return MenuResponse.Open;
      end);
    end
  end
end

---@param class AuctionHouseItemClassStructureClass
---@param subClass AuctionHouseItemClassStructureSubClass|nil
function Module:Execute(class, subClass)
  UtilityHub.Helpers.Mail:OpenSendMailTab(function()
    UtilityHub.Helpers.Mail:ClearAllMailSlots();

    local name = class.name;

    if (subClass) then
      name = name .. " - " .. subClass.name;
    end

    SendMailSubjectEditBox:SetText("UH -  [" .. name .. "]");

    for _, bag in pairs(UtilityHub.Constants.BagIDs) do
      for slot = 1, C_Container.GetContainerNumSlots(bag) do
        local itemLink = C_Container.GetContainerItemLink(bag, slot);

        if (itemLink) then
          local _, _, _, _, _, _, _, _, _, _, _, classID, subClassID = C_Item.GetItemInfo(itemLink);
          local isSoulbound = C_Item.IsBound(ItemLocation:CreateFromBagAndSlot(bag, slot));
          local isConjured = UtilityHub.Libs.Utils:IsItemConjured(itemLink);
          local classCheck = classID == class.classID;
          local subClassCheck = true;

          if (subClass) then
            subClassCheck = subClassID == subClass.subClassID;
          end

          if (not isSoulbound and not isConjured and classCheck and subClassCheck) then
            UtilityHub.Helpers.Mail:AddItemToNextEmptyMailSlot(bag, slot);
          end
        end
      end
    end

    ClearCursor();

    if (#SendMailNameEditBox:GetText() == 0) then
      SendMailNameEditBox:SetFocus();
    end
  end);
end
