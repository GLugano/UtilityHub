function MDH:SearchAndBuyRares()
    local rareItems = {
        14468,
        14481,
        16224
    };

    for i = 1, GetMerchantNumItems() do
        local itemLink = GetMerchantItemLink(i);

        if (itemLink) then
            local itemID = tonumber(string.match(itemLink, "item:(%d+):"));

            if (MDH.UTILS:ValueInTable(rareItems, itemID)) then
                BuyMerchantItem(i, 1);
                MDH.UTILS:ShowChatNotification("Bought: " .. itemLink);
            end
        end
    end
end
