UtilityHub.Integration.AtlasLootClassic = {
  ---@type boolean
  Enabled = false,
  hooked = false,
  Init = function(self)
    UtilityHub.Integration:ResolveWhenAddonIsLoaded({ "DragonflightUI", "AtlasLootClassic" }, function()
      _G.PVPFrame:HookScript("OnShow", function()
        UtilityHub.Integration.AtlasLootClassic.hooked = true;

        ---@type BackdropTemplate|nil
        local frame = _G.AtlasLootPVPSidePanel;

        if (not frame) then
          return;
        end

        frame:ClearAllPoints();
        frame:SetPoint("TOPLEFT", _G.PVPFrame, "TOPRIGHT", 2, 2);
        frame:SetPoint("BOTTOMLEFT", _G.PVPFrame, "BOTTOMRIGHT", 2, 2);
        frame:SetWidth(238);
      end);

      UtilityHub.Integration.AtlasLootClassic.Enabled = true;
    end);
  end,
};
