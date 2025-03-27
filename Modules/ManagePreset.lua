function MDH:GetManagePresetGeneratorFunction()
    return function(owner, rootDescription)
        rootDescription:CreateTitle(MDH:TableLength(MDH.db.global.presets) == 0 and "No presets available" or
                                        "Presets available");

        for i, value in pairs(MDH.db.global.presets) do
            local button = rootDescription:CreateButton(value.name);

            button:CreateButton("Edit", function()
                MDH:OpenNewPresetFrame(value, i);
            end);

            button:CreateButton("Remove", function()
                local newPresets = {};

                for j, value in pairs(MDH.db.global.presets) do
                    if (i ~= j) then
                        tinsert(newPresets, value);
                    end
                end

                MDH.db.global.presets = newPresets;
            end);
        end
    end
end
