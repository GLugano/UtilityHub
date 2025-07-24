function MDH:CreateTradeDataFrame()
    if (not TradeFrame or not TradeFrame:IsShown()) then
        return;
    end

    local name, server = UnitFullName("npc");
    server = server or GetRealmName();

    local frameWidth = 200;
    local frame = MDH.UTILS.AceGUI:Create("Frame");
    MDH.TradeDataFrameRef = frame;
    frame:SetTitle("Trading with...");
    frame:SetLayout("Flow");
    frame:SetWidth(frameWidth);
    frame:SetHeight(330);
    frame:EnableResize(false);
    frame:ClearAllPoints();
    frame:SetPoint("TOPRIGHT", TradeFrame, "TOPRIGHT", 10 + frameWidth, 0);
    frame:SetCallback("OnClose", function(widget)
        MDH.UTILS.AceGUI:Release(widget);
        MDH.TradeDataFrameRef = nil;
    end);

    CreateLabel(frame, name);
    CreateLabel(frame, "|cffffd100Server:|r " .. server);
    CreateLabel(frame, "|cffffd100Guild:|r " .. (GetGuildInfo("npc") or "-"));
    CreateLabel(frame, "|cffffd100Level:|r " .. UnitLevel("npc"));
    CreateLabel(frame, UnitRace("npc") .. " " .. UnitClass("npc"));

    local spacer = CreateLabel(frame);
    spacer:SetText(" ");
    spacer:SetHeight(10);

    local scrollFrameParent = MDH.UTILS.AceGUI:Create("InlineGroup");
    scrollFrameParent:SetTitle("Last whisper:");
    scrollFrameParent:SetFullWidth(true);
    scrollFrameParent:SetFullHeight(true);
    frame:AddChild(scrollFrameParent);

    local scroll = MDH.UTILS.AceGUI:Create("ScrollFrame");
    scroll:SetFullWidth(true);
    scroll:SetLayout("Flow");
    scrollFrameParent:AddChild(scroll);
    frame.LastWhisperScrollableRef = scroll;

    local label = CreateLabel(scroll, "-", 14);
    label:SetWidth(frameWidth - 60);
    label:SetFullHeight(true);

    function frame:UpdateWhisper()
        label:SetText(MDH.db.global.whispers[name .. "-" .. server] or "-");
    end

    frame:UpdateWhisper();
end

function MDH:ShowTradeDataFrame()
    MDH:CreateTradeDataFrame();
end

function MDH:CloseTradeDataFrame()
    if (MDH.TradeDataFrameRef) then
        MDH.TradeDataFrameRef:Hide();
    end
end

function CreateLabel(frame, text, fontSize)
    local label = MDH.UTILS.AceGUI:Create("Label");
    local fontPath, _, fontFlags = label.label:GetFont();
    label.label:SetFont(fontPath, fontSize or 16, fontFlags);
    label:SetText(text);
    frame:AddChild(label);

    return label;
end

function MDH:UpdateLastWhisperInFrame()
    if (MDH.TradeDataFrameRef) then
        MDH.TradeDataFrameRef:UpdateWhisper();
    end
end
