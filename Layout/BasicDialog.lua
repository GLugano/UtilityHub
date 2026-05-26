---@class BasicDialogArgs
---@field name string

---@class BasicDialogGenerator
local basicDialog = {};

---@param args BasicDialogArgs
---@return BasicDialog
function basicDialog:New(args)
  local name = UtilityHub.Constants.AddonName .. args.name;

  ---@type Frame & BaiscFrameTemplate
  local dialog;

  if (_G[name]) then
    dialog = _G[name];
  else
    dialog = CreateFrame(
      "Frame",
      UtilityHub.Constants.AddonName .. args.name,
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
  local dialogApi = {
    frame = dialog,
    ---@type table|nil
    data = nil,
    ---@param self BasicDialog
    OnSave = function(self)
      self.Hide();
    end,
    ---@param self BasicDialog
    ---@param data table
    OnSetData = function(self, data)
    end,
    ---@param text string
    ---@return BasicDialog
    SetTitle = function(self, text)
      self.frame.TitleText:SetText(text);
      return self;
    end,
    ---@param height number
    ---@param width number
    ---@return BasicDialog
    SetSize = function(self, height, width)
      self.frame:SetSize(width, height);
      return self;
    end,
    ---@return BasicDialog
    Show = function(self)
      self.frame:Show();
      self.frame:Raise();
      return self;
    end,
    ---@return BasicDialog
    Hide = function(self)
      self.frame:Hide();
      return self;
    end,
    ---@return BasicDialog
    AddCancelButton = function(self, text)
      local cancelBtn = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate");
      cancelBtn:SetText(text or "Cancel");
      cancelBtn:SetSize(80, 22);
      cancelBtn:SetPoint("BOTTOMRIGHT", -15, 15);
      cancelBtn:SetScript("OnClick", function()
        self.frame:Hide();
      end);

      self.frame.cancelButton = cancelBtn;

      return self;
    end,
    ---@return BasicDialog
    AddSaveButton = function(self)
      local saveBtn = CreateFrame("Button", nil, self.frame, "UIPanelButtonTemplate");
      saveBtn:SetText("Save");
      saveBtn:SetSize(80, 22);
      saveBtn:SetPoint("BOTTOMRIGHT", -15, 15);

      saveBtn:SetScript("OnClick", function()
        self:OnSave();
      end);

      self.frame.saveButton = saveBtn;

      return self;
    end,
    ---@return BasicDialog
    RealignButtons = function(self)
      if (self.frame.saveButton and self.frame.cancelButton) then
        self.frame.saveButton:ClearAllPoints();
        self.frame.saveButton:SetPoint("RIGHT", self.frame.cancelButton, "LEFT", -5, 0);
      end

      return self;
    end,
    ---@param self BasicDialog
    ---@param saveCb fun(self: BasicDialog)
    ---@return BasicDialog
    RegisterOnSave = function(self, saveCb)
      self.OnSave = saveCb;

      return self;
    end,
    ---@param self BasicDialog
    ---@param saveCb fun(self: BasicDialog, data: table)
    ---@return BasicDialog
    RegisterOnSetData = function(self, onSetData)
      self.OnSetData = onSetData;

      return self;
    end,
    SetData = function(self, data)
      self.data = data;
      self:OnSetData(data);

      return self;
    end,
  };

  return dialogApi;
end

UtilityHub.Components.BasicDialog = basicDialog;
