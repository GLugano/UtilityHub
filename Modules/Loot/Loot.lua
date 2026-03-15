EventRegistry:RegisterFrameEventAndCallback("LOOT_BIND_CONFIRM", function(_, slotIndex)
  local instanceID = select(8, GetInstanceInfo());

  -- Check if is Stratholme and its level 70 or above
  if (instanceID == 329 and UnitLevel("player") >= 70 and UtilityHub.Database.global.options.disableLootConfirmInStrat) then
    ConfirmLootSlot(slotIndex);
    StaticPopup_Hide("LOOT_BIND");
  end
end);
