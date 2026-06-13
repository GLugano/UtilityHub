---@diagnostic disable-next-line: inject-field
UtilityHub.Integration = {};

function UtilityHub.Integration:ResolveWhenAddonIsLoaded(addon, func)
  local addons = {};

  if (type(addon) == "string") then
    addons[addon] = C_AddOns.IsAddOnLoaded(addon) or false;
  elseif (type(addon) == "table") then
    for _, addonName in pairs(addon) do
      addons[addonName] = C_AddOns.IsAddOnLoaded(addonName) or false;
    end
  end

  ---@return boolean
  local function AllAddonsLoaded()
    for _, loaded in pairs(addons) do
      if (not loaded) then
        return false;
      end
    end

    return true;
  end

  if (AllAddonsLoaded()) then
    func();
    return;
  end

  EventRegistry:RegisterFrameEventAndCallback("ADDON_LOADED", function(addonName)
    if (type(addons[addonName]) == "boolean") then
      addons[addonName] = true;

      if (AllAddonsLoaded()) then
        func();
      end
    end
  end);
end
