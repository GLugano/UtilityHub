---@class BasicDialogArgs
---@field name string

---@class BasicDialogGenerator
local basicDialog = {};

---@param arguments BasicDialogArgs
---@return BasicDialog
function basicDialog:New(arguments)
  local name = UtilityHub.Constants.AddonName .. arguments.name;

  ---@type Frame & BasicFrameTemplate
  local dialog;

  if (_G[name]) then
    dialog = _G[name];
  else
    dialog = CreateFrame(
      "Frame",
      UtilityHub.Constants.AddonName .. arguments.name,
      UIParent,
      "BasicFrameTemplate"
    );
    dialog:SetSize(320, 195);
    dialog:SetPoint("CENTER");
    dialog:SetFrameStrata("DIALOG");
    dialog:SetMovable(true);
    dialog:EnableMouse(true);
    dialog:RegisterForDrag("LeftButton");
    dialog:SetScript("OnDragStart", dialog.StartMoving);
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing);
  end

  dialog:Hide();

  ---@class BasicDialog
  local apiTable = {};

  apiTable.frame = dialog;
  apiTable.data = nil;

  ---@param data table
  function apiTable:OnSetData(data)
  end

  ---@param text string
  ---@return BasicDialog
  function apiTable:SetTitle(text)
    self.frame.TitleText:SetText(text);
    return self;
  end

  ---@param height number
  ---@param width number
  ---@return BasicDialog
  function apiTable:SetSize(height, width)
    self.frame:SetSize(width, height);
    return self;
  end

  ---@return BasicDialog
  function apiTable:Show()
    self.frame:Show();
    self.frame:Raise();
    return self;
  end

  ---@return BasicDialog
  function apiTable:Hide()
    self.frame:Hide();
    return self;
  end

  ---@return BasicDialog
  function apiTable:AddCancelButton(text)
    local cancelBtn = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate");
    cancelBtn:SetText(text or "Cancel");
    cancelBtn:SetSize(80, 22);
    cancelBtn:SetPoint("BOTTOMRIGHT", -15, 15);
    cancelBtn:SetScript("OnClick", function()
      self.frame:Hide();
    end);

    self.frame.cancelButton = cancelBtn;

    return self;
  end

  ---@return BasicDialog
  function apiTable:AddSaveButton()
    local saveBtn = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate");
    saveBtn:SetText("Save");
    saveBtn:SetSize(80, 22);
    saveBtn:SetPoint("BOTTOMRIGHT", -15, 15);

    saveBtn:SetScript("OnClick", function()
      self:OnSave();
    end);

    self.frame.saveButton = saveBtn;

    return self;
  end

  ---@return BasicDialog
  function apiTable:RealignButtons()
    if (self.frame.saveButton and self.frame.cancelButton) then
      self.frame.saveButton:ClearAllPoints();
      self.frame.saveButton:SetPoint("RIGHT", self.frame.cancelButton, "LEFT", -5, 0);
    end

    return self;
  end

  function apiTable:OnSave()
    self:Hide();
  end

  ---@param saveCb fun(self: BasicDialog)
  ---@return BasicDialog
  function apiTable:RegisterOnSave(saveCb)
    self.OnSave = saveCb;

    return self;
  end

  ---@param onSetData fun(self: BasicDialog, data: table)
  ---@return BasicDialog
  function apiTable:RegisterOnSetData(onSetData)
    self.OnSetData = onSetData;

    return self;
  end

  ---@param data table
  ---@return BasicDialog
  function apiTable:SetData(data)
    self.data = data;
    self:OnSetData(data);

    return self;
  end

  return apiTable;
end

UtilityHub.Components.BasicDialog = basicDialog;
