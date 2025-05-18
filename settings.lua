local addonName = ...
local ByFireBePurged = {}

EventUtil.ContinueOnAddOnLoaded(addonName, function()
    ByFireBePurgedDB = ByFireBePurgedDB or {}
    ByFireBePurgedDB.sellList = ByFireBePurgedDB.sellList or {}
    ByFireBePurgedDB.destroyList = ByFireBePurgedDB.destroyList or {}
    ByFireBePurgedDB.autoSell = ByFireBePurgedDB.autoSell or true
    ByFireBePurgedDB.debugMode = ByFireBePurgedDB.debugMode or false

    ByFireBePurged:CreateSettingsPanel()
end)

function ByFireBePurged:CreateSettingsPanel()
    local OptionsFrame = CreateFrame("Frame", nil, nil, "VerticalLayoutFrame")
    OptionsFrame.spacing = 6
    OptionsFrame.padding = 6

    local iconTextureString = "|TInterface\\AddOns\\" .. addonName .. "\\Media\\logo.tga:18:18:0:0|t"
    ByFireBePurged.panelTitle = "By Fire Be Purged " .. iconTextureString

    -- Register the main category
    local category, layout = Settings.RegisterCanvasLayoutCategory(OptionsFrame, ByFireBePurged.panelTitle)
    category.ID = addonName
    Settings.RegisterAddOnCategory(category)

    local layoutIndex = 0
    local function GetLayoutIndex()
        layoutIndex = layoutIndex + 1
        return layoutIndex
    end

    -- Helper function to create UI elements
    local function CreateHeader(text)
        local headerFrame = CreateFrame("Frame", nil, OptionsFrame)
        headerFrame:SetSize(150, 30)
        local headerText = headerFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        headerText:SetPoint("TOPLEFT", 0, -5)
        headerText:SetText(text)
        local divider = headerFrame:CreateTexture(nil, "ARTWORK")
        divider:SetAtlas("Options_HorizontalDivider", true)
        divider:SetPoint("BOTTOMLEFT", -50, 0)
        headerFrame.layoutIndex = GetLayoutIndex()
        headerFrame.bottomPadding = 5
        return headerFrame
    end

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
                GameTooltip:SetText(text, 1, 1, 1)
                GameTooltip:AddLine(tooltipText, nil, nil, nil, true)
                GameTooltip:Show()
            end)
            checkButton:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
        end
        return checkButton
    end

    -- Addon Title Header
    CreateHeader("General Settings") -- You can use L.panelTitle here too if you prefer

    -- Create Checkboxes for your settings
    CreateCheckbox("Enable Automatic Selling", "autoSell", "If checked, automatically sells items from your 'sell list' when you visit a merchant.")
    CreateCheckbox("Enable Debug Mode", "debugMode", "If checked, prints detailed operational messages to chat for troubleshooting.")

    local descriptionLabel = OptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    descriptionLabel:SetText("Use slash commands to manage your sell and destroy lists:\n" ..
                             "/bfbp add <sell|destroy> <itemLink|itemID>\n" ..
                             "/bfbp list <sell|destroy|all>\n" ..
                             "/bfbp remove <sell|destroy> <itemLink|itemID>\n" ..
                             "/bfbp destroyitems (to destroy items on list)\n" ..
                             "/bfbp help (for all commands)")
    descriptionLabel.layoutIndex = GetLayoutIndex()
    descriptionLabel:SetJustifyH("LEFT")
    -- descriptionLabel:SetWidth(optionsFrame:GetWidth() - 2 * optionsFrame.padding) -- This might need adjustment or to be set after layout

    OptionsFrame:Layout()

    print(addonName .. ": Settings panel created.")
end
