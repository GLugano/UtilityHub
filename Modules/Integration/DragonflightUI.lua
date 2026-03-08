UtilityHub.Integration.DragonflightUI = {
  Enabled = false,
  Init = function(self)
    UtilityHub.Integration:ResolveWhenAddonIsLoaded(
      { "DragonflightUI" },
      function()
        UtilityHub.Integration.Enabled = true;
      end
    );
  end,
  ---@return boolean
  ModuleActive = function(self)
    return DragonflightUIProfessionFrame ~= nil;
  end,
  ---@return Frame
  GetSearchBox = function(self)
    return DragonflightUIProfessionFrame.RecipeList.SearchBox;
  end,
  ---@param value string
  UpdateSearchBox = function(self, value)
    local searchBox = UtilityHub.Integration.DragonflightUI:GetSearchBox();

    if (searchBox:GetText() == value) then
      return;
    end

    searchBox:SetText(value);
  end,
  ---@return boolean
  IsProfessionFrameOpen = function(self)
    return DragonflightUIProfessionFrame:IsShown();
  end,
  ---@return boolean
  IsCurrentSearchSlotName = function()
    local searchBox = UtilityHub.Integration.DragonflightUI:GetSearchBox();
    local text = searchBox:GetText();

    if (not text) then
      return false;
    end

    for _, craftSlot in pairs(UtilityHub.Constants.SlotValueToCraftSlotMap) do
      if (getglobal(craftSlot) == text) then
        return true;
      end
    end

    return false;
  end
};
