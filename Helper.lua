local ADDON_NAME = ...;
---@type UtilityHub
local UH = LibStub('AceAddon-3.0'):GetAddon(ADDON_NAME);
---@class Helpers
UH.Helpers = {};

--- Return true or false if the player is in the raid or group by his name and his index if in raid
---@param playerName string
function UH.Helpers:CheckIfPlayerInTheRaidOrGroupByName(playerName)
  if (not IsInGroup() or not IsInRaid()) then
    return false;
  end

  for i = 1, GetNumGroupMembers() do
    local name = GetRaidRosterInfo(i);

    if (name == playerName) then
      return true, i;
    end
  end

  return false, nil;
end

function UH.Helpers:FormatDuration(seconds)
  local hours = math.floor(seconds / 3600);
  local minutes = math.floor((seconds % 3600) / 60);
  local secs = seconds % 60;
  return string.format("%02d:%02d:%02d", hours, minutes, secs),
      (hours > 24 or (hours == 24 and minutes > 0 and seconds > 0));
end

function UH.Helpers:ShowNotification(text)
  UH.UTILS:ShowChatNotification(text, UH.prefix);
end

function UH.Helpers:ApplyPrefix(text)
  return UH.prefix .. text;
end

---@param item number | string
---@param cb fun(itemLink) | nil
function UH.Helpers:AsyncGetItemInfo(item, cb)
  local function tryCB(value)
    if (cb) then
      cb(value);
    end

    return value;
  end;

  if (not item) then
    return tryCB(nil);
  end

  local itemID = tonumber(item);

  if (itemID and type(itemID) == "number") then
    local tempItem = Item:CreateFromItemID(itemID);

    tempItem:ContinueOnItemLoad(function()
      tryCB(tempItem:GetItemLink());
    end);
  elseif (type(item) == "string") then
    local _, itemLink = C_Item.GetItemInfo(item);

    if (itemLink) then
      return tryCB(itemLink);
    end
  end

  return tryCB(nil);
end;
