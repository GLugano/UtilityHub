local MAJOR, MINOR = "Utils-1.0", 2;
local UTILS = LibStub:NewLibrary(MAJOR, MINOR);

-- If utils is nil, libstub already have that version saved
if (UTILS == nil) then
    return;
end

UTILS.AceGUI = LibStub("AceGUI-3.0");

if not UTILS then
    return
end -- No upgrade needed

function UTILS:ApplyPrefix(text)
    return UTILS.prefix .. text;
end

function UTILS:AddMovableToFrame(frameRef)
    frameRef:SetMovable(true);

    frameRef.isMoving = false
    frameRef:SetScript("OnMouseDown", function(self, button)
        if (button == "MiddleButton" and not frameRef.isMoving) then
            frameRef:StartMoving();
            frameRef.isMoving = true;
        end
    end)

    frameRef:SetScript("OnMouseUp", function(self, button)
        if (button == "MiddleButton" and frameRef.isMoving) then
            frameRef:StopMovingOrSizing();
            frameRef.isMoving = false;
        end
    end)
end

function UTILS:GetTimeString(seconds, countOnly, type)
    local timecalc = 0;

    if (countOnly) then
        timecalc = seconds;
    else
        timecalc = seconds - time();
    end

    local y = math.floor((timecalc / (86400 * 365)));
    local d = math.floor((timecalc % (86400 * 365)) / 86400);
    local h = math.floor((timecalc % 86400) / 3600);
    local m = math.floor((timecalc % 3600) / 60);
    local s = math.floor((timecalc % 60));
    local space = "";

    if (LOCALE_koKR or LOCALE_zhCN or LOCALE_zhTW) then
        space = " ";
    end

    if (type == "short") then
        if (y == 1 and d == 0) then
            return y .. " " .. L["yearShort"];
        elseif (y == 1) then
            return y .. " " .. L["yearShort"] .. " " .. d .. " " .. L["dayShort"];
        end
        if (y > 1 and d == 0) then
            return y .. " " .. L["yearShort"];
        elseif (y > 1) then
            return y .. " " .. L["yearShort"] .. " " .. d .. " " .. L["dayShort"];
        end
        if (d == 1 and h == 0) then
            return d .. L["dayShort"];
        elseif (d == 1) then
            return d .. L["dayShort"] .. space .. h .. L["hourShort"];
        end
        if (d > 1 and h == 0) then
            return d .. L["dayShort"];
        elseif (d > 1) then
            return d .. L["dayShort"] .. space .. h .. L["hourShort"];
        end
        if (h == 1 and m == 0) then
            return h .. L["hourShort"];
        elseif (h == 1) then
            return h .. L["hourShort"] .. space .. m .. L["minuteShort"];
        end
        if (h > 1 and m == 0) then
            return h .. L["hourShort"];
        elseif (h > 1) then
            return h .. L["hourShort"] .. space .. m .. L["minuteShort"];
        end
        if (m == 1 and s == 0) then
            return m .. L["minuteShort"];
        elseif (m == 1) then
            return m .. L["minuteShort"] .. space .. s .. L["secondShort"];
        end
        if (m > 1 and s == 0) then
            return m .. L["minuteShort"];
        elseif (m > 1) then
            return m .. L["minuteShort"] .. space .. s .. L["secondShort"];
        end
        -- If no matches it must be seconds only.
        return s .. L["secondShort"];
    elseif (type == "medium") then
        if (y == 1 and d == 0) then
            return y .. " " .. L["yearMedium"];
        elseif (y == 1) then
            return y .. " " .. L["yearMedium"] .. " " .. d .. " " .. L["daysMedium"];
        end
        if (y > 1 and d == 0) then
            return y .. " " .. L["yearsMedium"];
        elseif (y > 1) then
            return y .. " " .. L["yearsMedium"] .. " " .. d .. " " .. L["daysMedium"];
        end
        if (d == 1 and h == 0) then
            return d .. " " .. L["dayMedium"];
        elseif (d == 1) then
            return d .. " " .. L["dayMedium"] .. " " .. h .. " " .. L["hoursMedium"];
        end
        if (d > 1 and h == 0) then
            return d .. " " .. L["daysMedium"];
        elseif (d > 1) then
            return d .. " " .. L["daysMedium"] .. " " .. h .. " " .. L["hoursMedium"];
        end
        if (h == 1 and m == 0) then
            return h .. " " .. L["hourMedium"];
        elseif (h == 1) then
            return h .. " " .. L["hourMedium"] .. " " .. m .. " " .. L["minutesMedium"];
        end
        if (h > 1 and m == 0) then
            return h .. " " .. L["hoursMedium"];
        elseif (h > 1) then
            return h .. " " .. L["hoursMedium"] .. " " .. m .. " " .. L["minutesMedium"];
        end
        if (m == 1 and s == 0) then
            return m .. " " .. L["minuteMedium"];
        elseif (m == 1) then
            return m .. " " .. L["minuteMedium"] .. " " .. s .. " " .. L["secondsMedium"];
        end
        if (m > 1 and s == 0) then
            return m .. " " .. L["minutesMedium"];
        elseif (m > 1) then
            return m .. " " .. L["minutesMedium"] .. " " .. s .. " " .. L["secondsMedium"];
        end
        -- If no matches it must be seconds only.
        return s .. " " .. L["secondsMedium"];
    else
        if (y == 1 and d == 0) then
            return y .. " " .. L["year"];
        elseif (y == 1) then
            return y .. " " .. L["year"] .. " " .. d .. " " .. L["days"];
        end
        if (y > 1 and d == 0) then
            return y .. " " .. L["years"];
        elseif (y > 1) then
            return y .. " " .. L["years"] .. " " .. d .. " " .. L["days"];
        end
        if (d == 1 and h == 0) then
            return d .. " " .. L["day"];
        elseif (d == 1) then
            return d .. " " .. L["day"] .. " " .. h .. " " .. L["hours"];
        end
        if (d > 1 and h == 0) then
            return d .. " " .. L["days"];
        elseif (d > 1) then
            return d .. " " .. L["days"] .. " " .. h .. " " .. L["hours"];
        end
        if (h == 1 and m == 0) then
            return h .. " " .. L["hour"];
        elseif (h == 1) then
            return h .. " " .. L["hour"] .. " " .. m .. " " .. L["minutes"];
        end
        if (h > 1 and m == 0) then
            return h .. " " .. L["hours"];
        elseif (h > 1) then
            return h .. " " .. L["hours"] .. " " .. m .. " " .. L["minutes"];
        end
        if (m == 1 and s == 0) then
            return m .. " " .. L["minute"];
        elseif (m == 1) then
            return m .. " " .. L["minute"] .. " " .. s .. " " .. L["seconds"];
        end
        if (m > 1 and s == 0) then
            return m .. " " .. L["minutes"];
        elseif (m > 1) then
            return m .. " " .. L["minutes"] .. " " .. s .. " " .. L["seconds"];
        end
        -- If no matches it must be seconds only.
        return s .. " " .. L["seconds"];
    end
end

function UTILS:ValueInTable(table, valueToFind)
    for key, value in pairs(table) do
        if (value == valueToFind) then
            return true;
        end
    end

    return false;
end

function UTILS:RawMoneyToGold(raw)
    if (raw == nil) then
        return 0;
    end

    -- Gold starts at 5 position right to left. Ex: 50000 is 5g
    local goldString = string.sub(raw, 1, -5);

    if (string.len(goldString) == 0) then
        return 0;
    end

    return tonumber(goldString);
end

function UTILS:ShowChatNotification(text)
    print("|cffddff00[BH]|r " .. text)
end

function UTILS:CreateCheckbox(name, parent, label, checked, onClick)
    local checkboxRef = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate");

    checkboxRef:SetScript("OnClick", function(self)
        local tick = self:GetChecked();
        onClick(self, tick and true or false);

        if (tick) then
            PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
        else
            PlaySound(857) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
        end
    end);

    checkboxRef:SetChecked(checked);
    checkboxRef.TextRef = checkboxRef:CreateFontString(nil, "OVERLAY", "GameFontNormal");
    checkboxRef.TextRef:SetText(label);
    checkboxRef.TextRef:SetPoint("LEFT", checkboxRef, "RIGHT", 0, 0);

    return checkboxRef;
end

function UTILS:ShallowCopyTable(t)
    local t2 = {};

    for k, v in pairs(t) do
        t2[k] = v;
    end

    return t2;
end

function UTILS:ReverseTable(t)
    local reversed = {};
    local n = #t;

    for i = 1, n do
        reversed[i] = t[n - i + 1]
    end

    return reversed;
end

function UTILS:CreateIconButton(parent, id, skipTextures)
    local button = CreateFrame("DropdownButton", nil, parent, nil, id);
    local size = 30;

    button:SetSize(size, size);
    button:SetNormalTexture("");
    button:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square");
    button:GetHighlightTexture():SetBlendMode("ADD");
    button:SetPushedTexture("Interface/Buttons/UI-Quickslot-Depress");

    button.baseTextureRef = button:CreateTexture(nil, "ARTWORK");
    button.baseTextureRef:SetAllPoints();

    if (not skipTextures) then
        button.bgTextureRef = button:CreateTexture(nil, "BACKGROUND", nil, -1);
        button.bgTextureRef:SetTexture("Interface/Buttons/UI-EmptySlot-Disabled");
        button.bgTextureRef:SetPoint("CENTER", button.baseTextureRef, "CENTER");
        button.bgTextureRef:SetSize(1.5 * size, 1.5 * size);

        button.edgeTextureRef = button:CreateTexture(nil, "OVERLAY", nil, -1);
        button.edgeTextureRef:SetTexture("Interface/Buttons/UI-Quickslot2");
        button.edgeTextureRef:SetSize(1.625 * size, 1.625 * size);
        button.edgeTextureRef:SetPoint("CENTER", button.baseTextureRef, "CENTER", 0.25, -0.25);
    end

    return button;
end

function UTILS:GetItemIDFromLink(itemLink)
    if (itemLink) then
        local itemID = itemLink:match("item:(%d+)");
        return tonumber(itemID);
    end

    return nil;
end

function UTILS:TableLength(t)
    local tLength = 0;

    for _ in pairs(t) do
        tLength = tLength + 1;
    end

    return tLength;
end

function UTILS:PrintGetItemInfo(item)
    local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc,
        itemTexture, integersellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent =
        C_Item.GetItemInfo(item);
    print("itemName: " .. tostring(itemName));
    print("itemLink: " .. tostring(itemLink));
    print("itemQuality: " .. tostring(itemQuality));
    print("itemLevel: " .. tostring(itemLevel));
    print("itemMinLevel: " .. tostring(itemMinLevel));
    print("itemType: " .. tostring(itemType));
    print("itemSubType: " .. tostring(itemSubType));
    print("itemStackCount: " .. tostring(itemStackCount));
    print("itemEquipLoc: " .. tostring(itemEquipLoc));
    print("itemTexture: " .. tostring(itemTexture));
    print("integersellPrice: " .. tostring(integersellPrice));
    print("classID: " .. tostring(classID));
    print("subclassID: " .. tostring(subclassID));
    print("bindType: " .. tostring(bindType));
    print("expansionID: " .. tostring(expansionID));
    print("setID: " .. tostring(setID));
    print("isCraftingReagent: " .. tostring(isCraftingReagent));
end

function UTILS:PrintTablePropertiesAndValue(t)
    for key, value in pairs(t) do
        print(key, value);
    end
end

local function __genOrderedIndex(t)
    local orderedIndex = {};

    for key in pairs(t) do
        table.insert(orderedIndex, key);
    end

    table.sort(orderedIndex);

    return orderedIndex;
end

local function orderedNext(t, state)
    local key = nil;

    if state == nil then
        t.__orderedIndex = __genOrderedIndex(t);
        key = t.__orderedIndex[1];
    else
        -- fetch the next value
        for i = 1, #t.__orderedIndex do
            if t.__orderedIndex[i] == state then
                key = t.__orderedIndex[i + 1];
            end
        end
    end

    if key then
        return key, t[key];
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil;
    return
end

function UTILS:OrderedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in order
    return orderedNext, t, nil;
end

function UTILS:GetCompactRaidFrameByUnit(unit)
    if (not unit) then
        return nil;
    end

    for i = 1, 40 do
        local frame = _G["CompactRaidFrame" .. i];

        if (frame and frame.unit and UnitIsUnit(frame.unit, unit)) then
            return frame;
        end
    end

    return nil;
end

function UTILS:GenerateIdByName(name)
    local time = GetTime(); -- Get current time in seconds with milliseconds

    return tostring(time) .. name;
end

function UTILS:ExportTableToCSV(tbl, headers)
    local csvData = {};

    if (headers) then
        local headerString = nil;

        for key, value in pairs(headers) do
            if (headerString) then
                headerString = headerString .. "," .. value;
            else
                headerString = value;
            end
        end

        table.insert(csvData, headerString);
    end

    -- Add rows
    for _, row in ipairs(tbl) do
        local values = {};

        for _, value in pairs(row) do
            local val = tostring(value):gsub('"', '""'); -- Escape quotes
            table.insert(values, val);
        end

        table.insert(csvData, table.concat(values, ","));
    end

    -- Convert table to string
    local csvString = table.concat(csvData, "\n");

    return csvString;
end

function UTILS:OpenExportDialog(data)
    local frame = UTILS.AceGUI:Create("Frame");
    frame:SetTitle("Clients CSV");
    frame:SetStatusText("Use CTRL+C to copy");
    frame:SetLayout("Flow");
    frame:SetWidth(400);
    frame:SetHeight(300);
    frame:SetCallback("OnClose", function(widget)
        UTILS.AceGUI:Release(frame);
    end);

    local jsonbox = UTILS.AceGUI:Create("MultiLineEditBox");
    frame:AddChild(jsonbox);
    jsonbox:SetLabel("Exported data");
    jsonbox:SetText(data);
    jsonbox:HighlightText();
    jsonbox:SetFullWidth(true);
    jsonbox:SetFullHeight(true);
    jsonbox:DisableButton(true);
end

function UTILS:StringEndsWith(str, ending)
    return ending == "" or str:sub(-#ending) == ending
end
