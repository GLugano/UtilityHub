local moduleName = 'Characters';
---@class Characters : AceModule
local Module = UtilityHub.Addon:NewModule(moduleName);

local charMap = {
  -- Letter A
  [192] = { normalized = "A", original = "À" },
  [193] = { normalized = "A", original = "Á" },
  [194] = { normalized = "A", original = "Â" },
  [195] = { normalized = "A", original = "Ã" },
  [196] = { normalized = "A", original = "Ä" },
  [197] = { normalized = "A", original = "Å" },
  [224] = { normalized = "a", original = "à" },
  [225] = { normalized = "a", original = "á" },
  [226] = { normalized = "a", original = "â" },
  [227] = { normalized = "a", original = "ã" },
  [228] = { normalized = "a", original = "ä" },
  [229] = { normalized = "a", original = "å" },

  -- Letter C
  [199] = { normalized = "C", original = "Ç" },
  [231] = { normalized = "c", original = "ç" },

  -- Letter D
  [272] = { normalized = "D", original = "Đ" },
  [273] = { normalized = "d", original = "đ" },
  [208] = { normalized = "D", original = "Ð" },
  [240] = { normalized = "d", original = "ð" },

  -- Letter E
  [200] = { normalized = "E", original = "È" },
  [201] = { normalized = "E", original = "É" },
  [202] = { normalized = "E", original = "Ê" },
  [203] = { normalized = "E", original = "Ë" },
  [232] = { normalized = "e", original = "è" },
  [233] = { normalized = "e", original = "é" },
  [234] = { normalized = "e", original = "ê" },
  [235] = { normalized = "e", original = "ë" },

  -- Letter I
  [204] = { normalized = "I", original = "Ì" },
  [205] = { normalized = "I", original = "Í" },
  [206] = { normalized = "I", original = "Î" },
  [207] = { normalized = "I", original = "Ï" },
  [236] = { normalized = "i", original = "ì" },
  [237] = { normalized = "i", original = "í" },
  [238] = { normalized = "i", original = "î" },
  [239] = { normalized = "i", original = "ï" },

  -- Letter N
  [209] = { normalized = "N", original = "Ñ" },
  [241] = { normalized = "n", original = "ñ" },

  -- Letter O
  [210] = { normalized = "O", original = "Ò" },
  [211] = { normalized = "O", original = "Ó" },
  [212] = { normalized = "O", original = "Ô" },
  [213] = { normalized = "O", original = "Õ" },
  [214] = { normalized = "O", original = "Ö" },
  [216] = { normalized = "O", original = "Ø" },
  [242] = { normalized = "o", original = "ò" },
  [243] = { normalized = "o", original = "ó" },
  [244] = { normalized = "o", original = "ô" },
  [245] = { normalized = "o", original = "õ" },
  [246] = { normalized = "o", original = "ö" },
  [248] = { normalized = "o", original = "ø" },

  -- Letter U
  [217] = { normalized = "U", original = "Ù" },
  [218] = { normalized = "U", original = "Ú" },
  [219] = { normalized = "U", original = "Û" },
  [220] = { normalized = "U", original = "Ü" },
  [249] = { normalized = "u", original = "ù" },
  [250] = { normalized = "u", original = "ú" },
  [251] = { normalized = "u", original = "û" },
  [252] = { normalized = "u", original = "ü" },

  -- Letter Y
  [221] = { normalized = "Y", original = "Ý" },
  [253] = { normalized = "y", original = "ý" },
  [255] = { normalized = "y", original = "ÿ" },
};

---@param str string|nil
---@return integer|nil
local function GetFirstCharCodepoint(str)
  if (not str or str == "") then
    return nil;
  end

  local b1 = string.byte(str, 1);

  -- Standard A-Z / ASCII (1 byte)
  if (b1 < 128) then
    return b1;
  end

  -- 2-byte character (Common WoW specials)
  if (b1 >= 192 and b1 < 224) then
    local b2 = string.byte(str, 2);
    return (b1 - 192) * 64 + (b2 - 128);
  end

  -- 3-byte character (Rare)
  if (b1 >= 224 and b1 < 240) then
    local b2, b3 = string.byte(str, 2, 3);
    return (b1 - 224) * 4096 + (b2 - 128) * 64 + (b3 - 128);
  end

  return b1;
end

---@alias CharType "Normal"|"Special"

---@param name string|nil
---@return CharType|nil charType
---@return string|nil character
local function CheckFirstLetter(name)
  local code = GetFirstCharCodepoint(name);

  if (not code) then
    return nil, nil;
  end

  -- A. Check if it's already a standard A-Z (65-90) or a-z (97-122)
  if (code >= 65 and code <= 90) or (code >= 97 and code <= 122) then
    return "Normal", string.char(code);
  end

  -- B. Check if it's in your map
  if (charMap[code]) then
    return "Special", charMap[code].normalized;
  end

  -- C. It's something else (Number, Symbol, or Unmapped)
  return nil, nil;
end

function Module:GetAccountCharactersGeneratorFunction()
  return function(owner, rootDescription)
    local groups = {
      [UtilityHub.Enums.CharacterGroup.MAIN_ALT] = {},
      [UtilityHub.Enums.CharacterGroup.BANK] = {},
      [UtilityHub.Enums.CharacterGroup.UNGROUPED] = {},
    };

    for i, row in pairs(UtilityHub.Database.global.characters) do
      local group = row.group or UtilityHub.Enums.CharacterGroup.UNGROUPED;
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
        rootDescription:CreateTitle("• " .. UtilityHub.Enums.CharacterGroupText[groupID]);

        for _, character in pairs(group) do
          local characterButton = rootDescription:CreateButton(
            character.name,
            function()
              Module:StartMail(character.name)
            end
          );
          characterButton:AddInitializer(function(button, description, menu)
            local color = UtilityHub.Helpers.Color:GetRGBFromClassName(character.className);
            button.fontString:SetTextColor(color.r, color.g, color.b);
          end);
          characterButton:SetEnabled(character.name ~= UnitName("player"));
        end
      end
    end
  end
end

function Module:GetGuildCharactersGeneratorFunction()
  return function(owner, rootDescription)
    local total = GetNumGuildMembers();
    local columns = math.ceil(total / 20);
    local playerGroups = {};

    for i = 1, total do
      local name, _, _, level, _, _, _, _, isOnline, _, class = GetGuildRosterInfo(i);
      local displayedName = Ambiguate(name, "guild");
      local _, firstLetter = CheckFirstLetter(displayedName);

      if (firstLetter) then
        if (not playerGroups[firstLetter]) then
          playerGroups[firstLetter] = {};
        end

        tinsert(playerGroups[firstLetter], { name = displayedName, level = level, class = class });
      end
    end

    local sortedKeys = {};

    for k in pairs(playerGroups) do
      table.insert(sortedKeys, k);
    end

    table.sort(sortedKeys);

    for _, firstLetter in ipairs(sortedKeys) do
      local group = playerGroups[firstLetter];

      if (not group) then
        break;
      end

      table.sort(group, function(a, b)
        return a.name < b.name;
      end);

      rootDescription:CreateTitle("• " .. firstLetter);

      for _, player in ipairs(group) do
        local characterButton = rootDescription:CreateButton(
          string.format("%s (%s)", player.name, player.level),
          function()
            Module:StartMail(player.name)
          end
        );
        characterButton:AddInitializer(function(button, description, menu)
          local color = UtilityHub.Helpers.Color:GetRGBFromClassName(player.class);
          button.fontString:SetTextColor(color.r, color.g, color.b);
        end);
        characterButton:SetEnabled(player.name ~= UnitName("player"));
      end
    end

    -- If guild members still pending to load
    if (columns == 0) then
      columns = 1;
    end

    rootDescription:SetGridMode(MenuConstants.VerticalGridDirection, columns);
  end
end

function Module:StartMail(characterName)
  UtilityHub.Helpers.Mail:OpenSendMailTab(function()
    UtilityHub.Helpers.Mail:SetRecipient(characterName);
  end);
end
