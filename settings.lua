local addonName = ...
local ByFireBePurged = {}

-- This frame will hold the settings panel once created.
ByFireBePurged.OptionsFrame = nil
ByFireBePurged.panelTitle = nil -- Will be initialized later

EventUtil.ContinueOnAddOnLoaded(addonName, function()
    ByFireBePurgedDB = ByFireBePurgedDB or {}
    ByFireBePurgedDB.sellList = ByFireBePurgedDB.sellList or {}
    ByFireBePurgedDB.destroyList = ByFireBePurgedDB.destroyList or {}
    ByFireBePurgedDB.autoSell = ByFireBePurgedDB.autoSell or true
    ByFireBePurgedDB.debugMode = ByFireBePurgedDB.debugMode or false

    -- Initialize panel title here as addonName is available
    local iconTextureString = "|TInterface\\\\AddOns\\\\" .. addonName .. "\\\\Media\\\\logo.tga:18:18:0:0|t"
    ByFireBePurged.panelTitle = "By Fire Be Purged " .. iconTextureString

    ByFireBePurged:SetupSettingsCategory()
end)

function ByFireBePurged:SetupSettingsCategory()
    local categoryData = {
        id = addonName, -- Matches TOC name, typically used for AddOn options
        name = ByFireBePurged.panelTitle,
        -- The 'frame' field will be populated by OnShow, or the system handles it.
        -- For canvas layout categories, the frame is often created then registered.
        -- For simpler categories, OnShow is often used to populate a provided container.
        -- Let's stick to the pattern of creating our frame and having the system use it.

        OnShow = function(self, settingsFrameContainer) -- 'self' is categoryData. settingsFrameContainer is where our UI should go.
            if not ByFireBePurged.OptionsFrame then
                ByFireBePurged.OptionsFrame = ByFireBePurged:CreateSettingsPanel()
            end
            -- Ensure the frame is parented correctly and fills the container.
            -- The settings system might do this automatically if self.frame is set,
            -- but explicitly parenting to settingsFrameContainer is safer for non-Blizzard frames.
            -- However, for AddOn settings, often you just provide the frame.
            -- Let's ensure our OptionsFrame is what the settings system uses.
            -- The Blizzard settings system expects `self.frame` to be the main panel.
            if not self.frame then -- self.frame is a convention for the Settings system.
                 self.frame = ByFireBePurged.OptionsFrame
            end

            -- If CreateSettingsPanel was designed to be a standalone panel (which it is),
            -- it might not need explicit reparenting if registered correctly.
            -- The Settings.RegisterCanvasLayoutCategory approach handles parenting.
            -- With Settings.RegisterCategory + OnShow, we tell the system about our frame.
            -- The system then parents `self.frame` into `settingsFrameContainer`.
            -- We just need to make sure `self.frame` IS our `OptionsFrame`.

            -- If OptionsFrame uses VerticalLayoutFrame, it should handle its own layout.
            if ByFireBePurged.OptionsFrame and ByFireBePurged.OptionsFrame.Layout then
                ByFireBePurged.OptionsFrame:Layout()
            end
        end,
        -- We can also provide a 'frame' directly if we were using RegisterCanvasLayoutCategory
        -- but with RegisterCategory, OnShow is better for deferred creation.
        -- Let's ensure 'frame' is set on the categoryData after creation if not handled by OnShow's self.frame
        -- The standard way is that OnShow sets self.frame.
    }

    -- For addon settings, we use RegisterAddOnCategory.
    -- This function takes the categoryData table.
    Settings.RegisterAddOnCategory(categoryData)
    -- If we wanted to use the older RegisterCanvasLayoutCategory, we'd create the frame first:
    -- ByFireBePurged.OptionsFrame = ByFireBePurged:CreateSettingsPanel()
    -- local category, layout = Settings.RegisterCanvasLayoutCategory(ByFireBePurged.OptionsFrame, ByFireBePurged.panelTitle)
    -- category.ID = addonName
    -- Settings.RegisterAddOnCategory(category) -- This part is a bit mixed. It's either one or the other.

    -- The correct way with `RegisterAddOnCategory` and `categoryData` containing `OnShow`
    -- is that `OnShow` should populate `self.frame`. The system will then handle it.
end


function ByFireBePurged:CreateSettingsPanel()
    -- Main frame for the settings panel, using a vertical layout.
    -- This frame will contain all UI elements for the addon's settings.
    local OptionsFrame = CreateFrame("Frame", addonName .. "OptionsFrame", UIParent, "VerticalLayoutFrame")
    OptionsFrame.spacing = 6 -- Vertical spacing between elements.
    OptionsFrame.padding = 6  -- Padding around the edges of the frame.
    -- OptionsFrame:SetSize(450, 500) -- Example fixed size, or let it be dynamic / fill container.

    -- The panelTitle is now set globally for the addon
    -- local iconTextureString = "|TInterface\\\\AddOns\\\\" .. addonName .. "\\\\Media\\\\logo.tga:18:18:0:0|t"
    -- ByFireBePurged.panelTitle = "By Fire Be Purged " .. iconTextureString -- This line is removed

    -- Registration is now handled by SetupSettingsCategory
    -- local category, layout = Settings.RegisterCanvasLayoutCategory(OptionsFrame, ByFireBePurged.panelTitle)
    -- category.ID = addonName
    -- Settings.RegisterAddOnCategory(category)

    local layoutIndex = 0
    -- Helper function to get a unique layout index for ordering elements vertically.
    -- Each major UI component added to OptionsFrame should get a new index.
    local function GetLayoutIndex()
        layoutIndex = layoutIndex + 1
        return layoutIndex
    end

    -- Helper function to create a header text with a divider.
    -- Used to visually group related settings.
    local function CreateHeader(text)
        local headerFrame = CreateFrame("Frame", nil, OptionsFrame)
        headerFrame:SetSize(300, 30) -- Adjusted width for better appearance.
        local headerText = headerFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        headerText:SetPoint("TOPLEFT", 0, -5)
        headerText:SetText(text)
        local divider = headerFrame:CreateTexture(nil, "ARTWORK")
        divider:SetAtlas("Options_HorizontalDivider", true)
        -- Make divider span a reasonable width. Relative to headerFrame's width.
        divider:SetPoint("BOTTOMLEFT", 0, 0)
        divider:SetPoint("BOTTOMRIGHT", 0, 0)
        headerFrame.layoutIndex = GetLayoutIndex()
        headerFrame.bottomPadding = 5 -- Space below the header.
        return headerFrame
    end

    -- Helper function to create a checkbox with a label and tooltip.
    -- Used for boolean settings.
    local function CreateCheckbox(text, dbOptionKey, tooltipText)
        local checkButton = CreateFrame("CheckButton", nil, OptionsFrame, "SettingsCheckBoxTemplate")
        checkButton.text = checkButton:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        checkButton.text:SetText(text)
        checkButton.text:SetPoint("LEFT", checkButton, "RIGHT", 4, 0)
        checkButton:SetSize(20, 20)
        checkButton.layoutIndex = GetLayoutIndex()
        checkButton:SetHitRectInsets(0, -(checkButton.text:GetStringWidth() + 10), 0, 0)

        checkButton:SetChecked(ByFireBePurgedDB[dbOptionKey])

        checkButton:SetScript("OnClick", function(self)
            ByFireBePurgedDB[dbOptionKey] = not ByFireBePurgedDB[dbOptionKey]
            self:SetChecked(ByFireBePurgedDB[dbOptionKey])
        end)

        if tooltipText then
            checkButton:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(text, 1, 1, 1) -- Title for tooltip
                GameTooltip:AddLine(tooltipText, nil, nil, nil, true) -- Wrapped description
                GameTooltip:Show()
            end)
            checkButton:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
        end
        return checkButton
    end

    -- General Settings Section
    CreateHeader("General Settings")
    CreateCheckbox("Enable Automatic Selling", "autoSell", "If checked, automatically sells items from your 'sell list' when you visit a merchant.")
    CreateCheckbox("Enable Debug Mode", "debugMode", "If checked, prints detailed operational messages to chat for troubleshooting.")

    -- Description label for slash commands.
    local descriptionLabel = OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    descriptionLabel:SetText("Use slash commands to manage your sell and destroy lists:\\n" ..
                             "/bfbp add <sell|destroy> <itemLink|itemID>\\n" ..
                             "/bfbp list <sell|destroy|all>\\n" ..
                             "/bfbp remove <sell|destroy> <itemLink|itemID>\\n" ..
                             "/bfbp destroyitems (to destroy items on list)\\n" ..
                             "/bfbp help (for all commands)")
    descriptionLabel.layoutIndex = GetLayoutIndex()
    descriptionLabel:SetJustifyH("LEFT")
    descriptionLabel:SetWidth(380) -- Set a fixed width to prevent overflow.

    -- Managed Item Lists Section (New Tabbed Interface)
    local listsHeader = CreateHeader("Managed Item Lists")
    listsHeader.layoutIndex = GetLayoutIndex() -- Ensure it's placed after the description label.

    -- Frame to contain the tab buttons.
    local tabFrame = CreateFrame("Frame", addonName .. "ListTabs", OptionsFrame)
    tabFrame:SetHeight(30) -- Height for the tab bar.
    -- Width can be set explicitly or determined by OptionsFrame. For now, let it be flexible.
    -- tabFrame:SetWidth(400)
    tabFrame.layoutIndex = GetLayoutIndex()

    -- Tab Button for Sell List
    local sellListTab = CreateFrame("Button", addonName .. "SellListTab", tabFrame, "CharacterFrameTabButtonTemplate")
    sellListTab:SetID(1)
    sellListTab:SetText("Sell List")
    sellListTab:SetPoint("LEFT", tabFrame, "LEFT", 5, 0)
    -- PanelTemplates_TabResize(sellListTab, 0) -- Auto-size tab width to text

    -- Tab Button for Destroy List
    local destroyListTab = CreateFrame("Button", addonName .. "DestroyListTab", tabFrame, "CharacterFrameTabButtonTemplate")
    destroyListTab:SetID(2)
    destroyListTab:SetText("Destroy List")
    destroyListTab:SetPoint("LEFT", sellListTab, "RIGHT", -14, 0) -- Overlap slightly for standard tab look
    -- PanelTemplates_TabResize(destroyListTab, 0) -- Auto-size tab width to text

    -- ScrollFrame to display the list of items.
    -- Uses UIPanelScrollFrameTemplate for standard WoW scrollbar appearance.
    local listScrollFrame = CreateFrame("ScrollFrame", addonName .. "ListScrollFrame", OptionsFrame, "UIPanelScrollFrameTemplate")
    listScrollFrame:SetSize(400, 180) -- Width and height of the scrollable area.
    listScrollFrame.layoutIndex = GetLayoutIndex()
    listScrollFrame.bottomPadding = 10 -- Space below the scroll frame.

    -- Child frame for the ScrollFrame, which will contain the actual list items.
    -- Its height will be dynamically adjusted based on content.
    local scrollChild = CreateFrame("Frame", addonName .. "ListScrollChild", listScrollFrame)
    scrollChild:SetSize(listScrollFrame:GetWidth() - 25, 10) -- Width accounts for scrollbar, initial height is small.
    listScrollFrame:SetScrollChild(scrollChild)

    -- Function to populate the scrollChild with items from the selected list.
    local function DisplayList(listType)
        scrollChild:ReleaseChildren() -- Clear any existing items.
        local yOffset = -5 -- Initial vertical offset for the first item.
        local totalContentHeight = 0
        local itemLineHeight = 18 -- Height allocated for each item line.

        local listData
        local listName = "Unknown List"
        if listType == "sell" then
            listData = ByFireBePurgedDB.sellList
            listName = "Sell List"
        elseif listType == "destroy" then
            listData = ByFireBePurgedDB.destroyList
            listName = "Destroy List"
        else
            -- Should not happen, but good to have a fallback.
            scrollChild:SetHeight(itemLineHeight)
            listScrollFrame:UpdateScrollChildRect()
            return
        end

        if not listData or next(listData) == nil then
            -- Display a message if the list is empty.
            local emptyText = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            emptyText:SetPoint("TOPLEFT", 10, yOffset)
            emptyText:SetText("The " .. listName .. " is currently empty.")
            emptyText:SetJustifyH("LEFT")
            emptyText:SetWidth(scrollChild:GetWidth() - 20)
            totalContentHeight = itemLineHeight
        else
            -- Iterate over items in the list and create text entries for them.
            for itemID, _ in pairs(listData) do
                local itemName, itemLink, itemRarity = GetItemInfo(itemID)
                itemName = itemName or "Item ID: " .. tostring(itemID) -- Fallback if GetItemInfo fails.

                local itemText = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                itemText:SetPoint("TOPLEFT", 10, yOffset)
                itemText:SetText(itemName)
                itemText:SetJustifyH("LEFT")
                itemText:SetWidth(scrollChild:GetWidth() - 20)

                -- Optionally, color item name by rarity
                if itemRarity then
                    local r, g, b = GetItemQualityColor(itemRarity)
                    itemText:SetTextColor(r, g, b)
                end

                -- TODO: Consider adding a small 'Remove' button next to each item.
                -- This would require additional logic for handling removal and refreshing the list.

                yOffset = yOffset - itemLineHeight          -- Move down for the next item.
                totalContentHeight = totalContentHeight + itemLineHeight -- Accumulate total height.
            end
        end

        -- Update the height of the scroll child to fit all items.
        scrollChild:SetHeight(math.max(itemLineHeight, totalContentHeight))
        -- Tell the scroll frame to update its view of the child's dimensions.
        listScrollFrame:UpdateScrollChildRect()

        -- Update the scrollbar's state.
        local scrollBar = _G[listScrollFrame:GetName() .. "ScrollBar"]
        if scrollBar then
            -- Parameters: scrollbar, total content height, visible frame height, height per scroll step.
            FauxScrollFrame_Update(scrollBar, totalContentHeight, listScrollFrame:GetHeight(), itemLineHeight)
        end
    end

    -- Script for Sell List tab click.
    sellListTab:SetScript("OnClick", function(self)
        PanelTemplates_SetTab(tabFrame, self:GetID()) -- Visually select this tab.
        DisplayList("sell")                           -- Populate list with sell items.
    end)

    -- Script for Destroy List tab click.
    destroyListTab:SetScript("OnClick", function(self)
        PanelTemplates_SetTab(tabFrame, self:GetID()) -- Visually select this tab.
        DisplayList("destroy")                        -- Populate list with destroy items.
    end)

    -- Initialize the tab system.
    -- Sets the total number of tabs and selects the first tab by default.
    PanelTemplates_SetNumTabs(tabFrame, 2)
    PanelTemplates_SetTab(tabFrame, 1) -- Select the "Sell List" tab (ID 1) initially.
    DisplayList("sell")                -- Populate the list for the initially selected tab.

    -- Final layout pass for the OptionsFrame.
    -- This arranges all child elements according to their layoutIndex and padding.
    OptionsFrame:Layout()

    print(addonName .. ": Settings panel UI created.") -- Message updated
    return OptionsFrame -- Return the created panel
end
