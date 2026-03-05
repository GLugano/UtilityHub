UtilityHub.Integration.Baganator = {
  Init = function(_)
    UtilityHub.Integration:ResolveWhenAddonIsLoaded({ "Baganator", "Dejunk" }, function()
      Baganator.API.RegisterJunkPlugin("Dejunk + Personal", "dejunkcustom", function(bagID, slotID, _, _)
        return DejunkApi:IsJunk(bagID, slotID) or
            UtilityHub.Libs.Utils:IsItemConjured(C_Container.GetContainerItemLink(bagID, slotID));
      end)
    end);
  end
};
