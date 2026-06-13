local hooked = false;

---@param query any
---@param page any
---@return string text
---@return number? minLevel
---@return number? maxLevel
---@return number? page
---@return boolean usable
---@return Enum.ItemQuality? rarity
---@return boolean getAll
---@return boolean exactMatch
---@return table? filterData
local function ParamsForBlizzardAPI(query, page)
  return query.searchString,
      query.minLevel,
      query.maxLevel,
      page,
      query.usable or false,
      query.quality,
      false,
      query.isExact or false,
      query.itemClassFilters;
end;

local function CreateAuctionatorUsableItems()
  if (not Auctionator) then
    return;
  end

  if (hooked) then
    return;
  end

  hooked = true;

  -- Create the checkbox when the AH is shown
  local eventFrame = CreateFrame("Frame");
  eventFrame:RegisterEvent("AUCTION_HOUSE_SHOW");
  eventFrame:SetScript("OnEvent", function()
    local shoppingList = AuctionatorShoppingTabItemFrame;

    if (not shoppingList) then
      return;
    end

    -- Check if we've already created the checkbox
    if (shoppingList.UtilityHubUsableCheckbox) then
      return;
    end

    local checkbox = CreateFrame("CheckButton", nil, shoppingList, "UICheckButtonTemplate");
    checkbox:SetPoint("LEFT", shoppingList.SearchContainer.ResetSearchStringButton, "RIGHT", 10, 0);
    checkbox.Text:SetText("Usable");
    checkbox.Text:SetFont("Fonts\\FRIZQT__.TTF", 12);
    checkbox.Text:SetTextColor(1, 1, 1, 1);
    shoppingList.UtilityHubUsableCheckbox = checkbox;

    -- Hook GetItemString to add the usable filter
    local originalGetItemString = AuctionatorShoppingTabItemFrame.GetItemString;

    function AuctionatorShoppingTabItemFrame:GetItemString()
      return strjoin(";",
        originalGetItemString(self),
        tostring(self.UtilityHubUsableCheckbox and self.UtilityHubUsableCheckbox:GetChecked() or "")
      );
    end;

    local originalSplitAdvancedSearch = Auctionator.Search.SplitAdvancedSearch;

    function Auctionator.Search.SplitAdvancedSearch(searchParametersString)
      local resultSearch = originalSplitAdvancedSearch(searchParametersString);

      local queryString, categoryKey, minItemLevel, maxItemLevel, minLevel, maxLevel,
      minCraftedLevel, maxCraftedLevel, minPrice, maxPrice, quality, tier,
      expansion, quantity, usable =
          strsplit(Auctionator.Constants.AdvancedSearchDivider, searchParametersString);

      resultSearch.usable = usable and true or false;

      return resultSearch;
    end;

    local parent = AuctionatorShoppingTabItemFrame:GetParent();
    local searchProvider = parent.SearchProvider;
    local originalCreateSearchTerm = searchProvider.CreateSearchTerm;

    function searchProvider:CreateSearchTerm(term, config)
      local originalSearchTerm = originalCreateSearchTerm(searchProvider, term, config);
      local parsed = Auctionator.Search.SplitAdvancedSearch(term);

      if (not originalSearchTerm.query.filters) then
        originalSearchTerm.query.filters = {};
      end

      if (parsed.usable) then
        tinsert(originalSearchTerm.query.filters, Enum.AuctionHouseFilter.UsableOnly);
      end

      originalSearchTerm.query.usable = parsed.usable or false;

      return originalSearchTerm;
    end;

    function Auctionator.AH.Internals.scan:DoNextSearchQuery()
      local page = self.nextPage;
      self.sentQuery = false;

      self.lastQueuedItem = function()
        self.sentQuery = true;
        SortAuctionSetSort("list", "unitprice");
        QueryAuctionItems(ParamsForBlizzardAPI(self.query, page));
      end;
      Auctionator.AH.Queue:Enqueue(self.lastQueuedItem);

      self.waitingOnPage = true;
      self.nextPage = self.nextPage + 1;

      Auctionator.EventBus:Fire(self, Auctionator.AH.Events.ScanPageStart, page);
    end;
  end);
end;

function UtilityHub.Integration.Auctionator()
  UtilityHub.Integration:ResolveWhenAddonIsLoaded({ "Auctionator" }, function()
    CreateAuctionatorUsableItems();
  end);
end;
