local ADDON_NAME = ...;

---@class OptionsCanvas
local OptionsCanvas = {};

OptionsCanvas.currentPage = nil;
OptionsCanvas.pages = {};

---@return Frame
function OptionsCanvas:CreateMainFrame()
  -- Don't specify parent - let Settings API manage it
  local mainFrame = CreateFrame("Frame", "UtilityHubCanvasFrame");
  mainFrame:SetSize(800, 600);

  -- Navigation sidebar (left side, 180px wide)
  local sidebar = CreateFrame("Frame", nil, mainFrame);
  sidebar:SetPoint("TOPLEFT", 10, -10);
  sidebar:SetPoint("BOTTOMLEFT", 10, 10);
  sidebar:SetWidth(180);

  -- Sidebar background
  local sidebarBg = sidebar:CreateTexture(nil, "BACKGROUND");
  sidebarBg:SetAllPoints();
  sidebarBg:SetColorTexture(0.1, 0.1, 0.1, 0.3);

  -- Content area (right side)
  local content = CreateFrame("Frame", nil, mainFrame);
  content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 10, 0);
  content:SetPoint("BOTTOMRIGHT", -10, 10);

  -- Content background
  local contentBg = content:CreateTexture(nil, "BACKGROUND");
  contentBg:SetAllPoints();
  contentBg:SetColorTexture(0.05, 0.05, 0.05, 0.2);

  mainFrame.sidebar = sidebar;
  mainFrame.content = content;

  return mainFrame;
end

---@param parent Frame
---@param text string
---@param OnClick fun()
---@param isFirst boolean
---@param previousButton? Button
---@return Button
function OptionsCanvas:CreateNavigationButton(
    parent,
    text,
    OnClick,
    isFirst,
    previousButton
)
  local button = CreateFrame("Button", nil, parent);
  button:SetSize(160, 32);
  button:SetNormalFontObject("GameFontNormal");
  button:SetHighlightFontObject("GameFontHighlight");
  button:SetText(text);

  if (isFirst) then
    button:SetPoint("TOPLEFT", 10, -10);
  else
    button:SetPoint("TOPLEFT", previousButton, "BOTTOMLEFT", 0, -2);
  end

  -- Button background
  local normalTexture = button:CreateTexture(nil, "BACKGROUND");
  normalTexture:SetAllPoints();
  normalTexture:SetColorTexture(0.2, 0.2, 0.2, 0.5);
  button:SetNormalTexture(normalTexture);

  local highlightTexture = button:CreateTexture(nil, "HIGHLIGHT");
  highlightTexture:SetAllPoints();
  highlightTexture:SetColorTexture(0.3, 0.3, 0.3, 0.5);
  button:SetHighlightTexture(highlightTexture);

  button:SetScript(
    "OnClick",
    function()
      OnClick();
      PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    end
  );

  return button;
end

---@param contentFrame Frame
---@param pageName string
function OptionsCanvas:ShowPage(contentFrame, pageName)
  -- Hide all pages
  for name, page in pairs(self.pages) do
    if (page.frame) then
      page.frame:Hide();
    end
  end

  -- Show requested page
  if (self.pages[pageName] and self.pages[pageName].frame) then
    self.pages[pageName].frame:Show();
    self.currentPage = pageName;
  end
end

---@return Frame
function OptionsCanvas:Create()
  local mainFrame = self:CreateMainFrame();

  -- Register pages (order matters for navigation)
  self.pageOrder = { "general", "autoBuy", "mail", "graphicsSettings", "mouseRing" };
  self.pages = {
    general = {
      label = "General",
      CreateFrame = function(parent)
        return UtilityHub.OptionsPages.General:Create(parent);
      end
    },
    autoBuy = {
      label = "AutoBuy",
      CreateFrame = function(parent)
        return UtilityHub.OptionsPages.AutoBuy:Create(parent);
      end
    },
    mail = {
      label = "Mail",
      CreateFrame = function(parent)
        return UtilityHub.OptionsPages.Mail:Create(parent);
      end
    },
    graphicsSettings = {
      label = "Graphics",
      CreateFrame = function(parent)
        return UtilityHub.OptionsPages.GraphicsSettings:Create(parent);
      end
    },
    mouseRing = {
      label = "Mouse Ring",
      CreateFrame = function(parent)
        return UtilityHub.OptionsPages.MouseRing:Create(parent);
      end
    },
  };

  -- Create navigation buttons in order
  local previousButton = nil;
  local isFirst = true;

  for _, pageName in ipairs(self.pageOrder) do
    local pageData = self.pages[pageName];
    local button = self:CreateNavigationButton(
      mainFrame.sidebar,
      pageData.label,
      function()
        self:ShowPage(mainFrame.content, pageName);
      end,
      isFirst,
      previousButton
    );

    previousButton = button;
    isFirst = false;
  end

  -- Create page frames
  for pageName, pageData in pairs(self.pages) do
    local pageFrame = pageData.CreateFrame(mainFrame.content);
    pageFrame:SetAllPoints(mainFrame.content);
    pageFrame:Hide();
    self.pages[pageName].frame = pageFrame;
  end

  -- Show first page by default
  self:ShowPage(mainFrame.content, "general");

  return mainFrame;
end

-- Initialize namespace
if (not UtilityHub.OptionsCanvas) then
  UtilityHub.OptionsCanvas = OptionsCanvas;
end

-- Initialize pages namespace
if (not UtilityHub.OptionsPages) then
  UtilityHub.OptionsPages = {};
end
