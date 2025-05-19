local addonName, private = ... -- Standard addon object and private table
local ByFireBePurged = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName) -- For localized strings

-- Default database values
local defaults = {
    profile = {
        autoSell = true,
        debugMode = false,
        sellList = {}, -- { [itemID] = true, ... }
        destroyList = {} -- { [itemID] = true, ... }
    }
}

-- Forward declare for use in callbacks if needed, though direct calls should be fine
local AceGUI = nil

function ByFireBePurged:OnInitialize()
    -- Called when the addon is first loaded, before OnEnable
    self.db = LibStub("AceDB-3.0"):New("ByFireBePurgedDB", defaults, true) -- true for profile-based
    self.tempGuiInputValues = {} -- Initialize temporary storage for AceConfig GUI inputs (may be deprecated with standalone GUI)
    self.guiFrame = nil -- Will hold our standalone AceGUI frame
    self.L = L -- Make L accessible via self if needed, though it's an upvalue here
    AceGUI = LibStub("AceGUI-3.0") -- Initialize AceGUI upvalue

    -- Register options panel (now only for general settings)
    LibStub("AceConfig-3.0"):RegisterOptionsTable(L["ADDON_NAME"], self:GetOptionsTable(), "/bfbp")
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(L["ADDON_NAME"], L["ADDON_NAME"])

    -- Register slash command
    self:RegisterChatCommand("bfbp", "SlashCommandHandler")
    self:RegisterChatCommand("byfirebepurged", "SlashCommandHandler") -- Alias

    self:Print(L["ADDON_NAME"] .. " initialized. Type /bfbp for options.")
end

function ByFireBePurged:OnEnable()
    -- Called when the addon is enabled
    self:Print(L["ADDON_NAME"] .. " enabled.")
end

function ByFireBePurged:OnDisable()
    -- Called when the addon is disabled
    self:Print(L["ADDON_NAME"] .. " disabled.")
end

function ByFireBePurged:SlashCommandHandler(input)
    input = input:trim()
    if input == "" or input:lower() == "config" then
        self:ToggleStandaloneGUI()
    elseif input:lower() == "help" then
        -- TODO: Implement more detailed help if needed
        self:Print("Available commands:")
        self:Print("/bfbp config - Toggles the item list management window.")
        self:Print("/bfbp help - Shows this help message.")
    else
        -- For now, just open the GUI if any other unrecognized input is given
        -- Or, you could parse for add/remove commands here directly in future
        self:Print(L["FEEDBACK_INVALID_COMMAND"]:format(input) .. " Try /bfbp help or /bfbp config.")
        self:ToggleStandaloneGUI()
    end
end

-- Helper to create the content (input boxes, buttons, scrollframe) for a list type
-- This function is effectively replaced by _PopulateColumnWithControls and can be removed or heavily refactored.
-- For now, it's unused by the new two-column layout.
-- function ByFireBePurged:_CreateListContentWidgets(listType, parentContainer) ... end

function ByFireBePurged:CreateStandaloneGUI()
    if self.guiFrame then return end -- Already created

    -- Ensure AceGUI is loaded (it's set in OnInitialize, but good practice for standalone calls if any)
    if not AceGUI then AceGUI = LibStub("AceGUI-3.0") end

    -- Main Frame
    self.guiFrame = AceGUI:Create("Frame")
    if not self.guiFrame then
        self:Print("Error: Main GUI Frame could not be created.")
        return
    end

    self.guiFrame:SetTitle(self.L["GUI_ITEM_LIST_MANAGEMENT_TITLE"])
    self.guiFrame:SetStatusText(self.L["ADDON_NAME"])
    self.guiFrame:SetLayout("Fill") -- Main frame will fill with its content (the column container)
    self.guiFrame:SetWidth(600) -- Increased width for two columns
    self.guiFrame:SetHeight(450)
    self.guiFrame:EnableResize(false)

    -- Store widgets per list for easy access (e.g., input boxes, scroll frames)
    self.guiFrame.columnControls = {
        sellList = {},
        destroyList = {}
    }

    -- Container for the two columns
    local columnContainer = AceGUI:Create("SimpleGroup")
    if not columnContainer then
        self:Print("Error creating columnContainer (SimpleGroup) for GUI.")
        self.guiFrame = nil -- Invalidate frame if critical part fails
        return
    end
    columnContainer:SetLayout("Manual") -- Changed to Manual layout
    columnContainer:SetFullWidth(true)
    columnContainer:SetFullHeight(true)
    self.guiFrame:AddChild(columnContainer)

    local backdropInfo = {
        bgFile = "Interface\\Buttons\\WHITE8X8",
        -- edgeFile = "Interface\\Tooltip\\UI-Tooltip-Border", -- Not used in this texture method
        -- tile = true, tileSize = 16, edgeSize = 16, -- Not directly used, SetAllPoints handles fill
        -- insets = { left = 3, right = 3, top = 3, bottom = 3 } -- Not used
    }
    local backgroundColor = {0.05, 0.05, 0.05, 0.7} -- Darkened background
    local borderColor = {0, 0, 0, 0.8}               -- Black border
    local borderThickness = 1 -- Pixel thickness for the border

    -- Sell List Column
    local sellColumnGroup = AceGUI:Create("SimpleGroup")
    if not sellColumnGroup then
        self:Print("Error creating sellColumnGroup.")
        self.guiFrame = nil
        return
    end
    sellColumnGroup:SetLayout("Flow") -- Content flows vertically
    sellColumnGroup:SetWidth(275)     -- Further reduced width to prevent overflow
    sellColumnGroup:SetFullHeight(true)
    columnContainer:AddChild(sellColumnGroup) -- Add child FIRST, then set point relative to parent
    sellColumnGroup:SetPoint("TOPLEFT", 0, 0) -- Relative to parent's content frame

    -- Attempt to add background texture directly
    -- Outer texture for border
    local borderSell = sellColumnGroup.frame:CreateTexture(nil, "BACKGROUND", nil, -8) -- Draw layer behind background
    borderSell:SetTexture(backdropInfo.bgFile)
    borderSell:SetAllPoints(true) -- Fill the entire frame for the border
    borderSell:SetVertexColor(unpack(borderColor))

    -- Inner texture for main background (slightly smaller than border)
    local bgSell = sellColumnGroup.frame:CreateTexture(nil, "BACKGROUND", nil, -7) -- Draw layer on top of border texture
    bgSell:SetTexture(backdropInfo.bgFile)
    bgSell:SetPoint("TOPLEFT", sellColumnGroup.frame, "TOPLEFT", borderThickness, -borderThickness)
    bgSell:SetPoint("BOTTOMRIGHT", sellColumnGroup.frame, "BOTTOMRIGHT", -borderThickness, borderThickness)
    bgSell:SetVertexColor(unpack(backgroundColor))

    self:_PopulateColumnWithControls("sellList", sellColumnGroup, self.guiFrame.columnControls.sellList)


    -- Destroy List Column
    local destroyColumnGroup = AceGUI:Create("SimpleGroup")
    if not destroyColumnGroup then
        self:Print("Error creating destroyColumnGroup.")
        self.guiFrame = nil
        return
    end

    destroyColumnGroup:SetLayout("Flow") -- Content flows vertically
    destroyColumnGroup:SetWidth(275) -- Further reduced width
    destroyColumnGroup:SetFullHeight(true)
    columnContainer:AddChild(destroyColumnGroup) -- Add child FIRST
    destroyColumnGroup:SetPoint("TOPLEFT", sellColumnGroup.frame, "TOPRIGHT", 15, 0) -- Correct: Use .frame

    -- Attempt to add background texture directly
    -- Outer texture for border
    local borderDestroy = destroyColumnGroup.frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    borderDestroy:SetTexture(backdropInfo.bgFile)
    borderDestroy:SetAllPoints(true)
    borderDestroy:SetVertexColor(unpack(borderColor))

    -- Inner texture for main background
    local bgDestroy = destroyColumnGroup.frame:CreateTexture(nil, "BACKGROUND", nil, -7)
    bgDestroy:SetTexture(backdropInfo.bgFile)
    bgDestroy:SetPoint("TOPLEFT", destroyColumnGroup.frame, "TOPLEFT", borderThickness, -borderThickness)
    bgDestroy:SetPoint("BOTTOMRIGHT", destroyColumnGroup.frame, "BOTTOMRIGHT", -borderThickness, borderThickness)
    bgDestroy:SetVertexColor(unpack(backgroundColor))

    self:_PopulateColumnWithControls("destroyList", destroyColumnGroup, self.guiFrame.columnControls.destroyList)

    self.guiFrame:Hide()
end

-- New function to populate a column with its title, input fields, and scroll frame
function ByFireBePurged:_PopulateColumnWithControls(listType, parentColumnGroup, controlsTable)
    local AceGUI = LibStub("AceGUI-3.0")
    local L = self.L

    -- Column Title
    local title = AceGUI:Create("Label")
    local titleText = (listType == "sellList") and L["SELL_LIST"] or L["DESTROY_LIST"]
    title:SetText(titleText)
    title:SetFontObject(GameFontNormalLarge) -- Make title stand out
    title:SetFullWidth(true)
    if title.SetJustifyH then
        title:SetJustifyH("CENTER")
    elseif title.fontstring and title.fontstring.SetJustifyH then
        title.fontstring:SetJustifyH("CENTER")
    else
        if listType == "sellList" then self:Print("DEBUG: Could not set JustifyH for title label. Neither widget:SetJustifyH nor widget.fontstring:SetJustifyH available.") end
    end
    parentColumnGroup:AddChild(title)

    -- Add Item InputBox
    local addBox = AceGUI:Create("EditBox")
    if not addBox then self:Print("Error creating AddBox for " .. listType); return end
    addBox:SetLabel(L["GUI_ADD_ITEM_LABEL"])
    addBox:SetFullWidth(true)
    addBox:SetCallback("OnEnterPressed", function(widget) self:HandleGUIAddItem(listType, widget) end)
    parentColumnGroup:AddChild(addBox)
    controlsTable.addBox = addBox

    -- Add Item Button
    -- local addButton = AceGUI:Create("Button")
    -- if not addButton then self:Print("Error creating AddButton for " .. listType); return end
    -- addButton:SetText(L["Add Item"])
    -- addButton:SetFullWidth(true) -- Make button take full width of column segment
    -- parentColumnGroup:AddChild(addButton)
    -- addButton:SetCallback("OnClick", function() self:HandleGUIAddItem(listType, controlsTable.addBox) end)
    -- controlsTable.addButton = addButton -- Though not strictly needed if addBox is primary ref

    -- Spacer (optional, for visual separation)
    local spacer = AceGUI:Create("Label")
    spacer:SetText(" ") -- Empty text for spacing
    spacer:SetHeight(5)
    parentColumnGroup:AddChild(spacer)

    -- ScrollFrame for items
    local scroll = AceGUI:Create("ScrollFrame")
    if not scroll then self:Print("Error creating ScrollFrame for " .. listType); return end
    scroll:SetLayout("Flow") -- Items in scroll frame will flow top-to-bottom
    scroll:SetFullWidth(true)
    -- Let ScrollFrame take up remaining height. This is tricky with Flow layout.
    -- A fixed height or more complex layout might be needed if it doesn't fill well.
    scroll:SetHeight(300) -- Set a fixed, substantial height for the scroll area
    parentColumnGroup:AddChild(scroll)
    controlsTable.scrollContainer = scroll
end

function ByFireBePurged:ToggleStandaloneGUI()
    if not self.guiFrame then
        self:CreateStandaloneGUI()
    end

    if not self.guiFrame then -- Check again in case CreateStandaloneGUI failed
        self:Print("Error: GUI Frame could not be initialized.")
        return
    end

    if self.guiFrame:IsShown() then
        self.guiFrame:Hide()
    else
        self.guiFrame:Show()
        -- Refresh both lists when GUI is shown
        if self.guiFrame.columnControls.sellList.scrollContainer then
            self:_RefreshColumnItemsDisplay("sellList", self.guiFrame.columnControls.sellList.scrollContainer)
        else
            self:Print("Sell list scroll container not found for refresh.")
        end

        if self.guiFrame.columnControls.destroyList.scrollContainer then
            self:_RefreshColumnItemsDisplay("destroyList", self.guiFrame.columnControls.destroyList.scrollContainer)
        else
            self:Print("Destroy list scroll container NOT FOUND for refresh.")
        end
    end
end

function ByFireBePurged:RefreshStandaloneGUILists()
    if not self.guiFrame or not self.guiFrame:IsShown() then return end

    -- Refresh both columns
    if self.guiFrame.columnControls.sellList.scrollContainer then
        self:_RefreshColumnItemsDisplay("sellList", self.guiFrame.columnControls.sellList.scrollContainer)
    end
    if self.guiFrame.columnControls.destroyList.scrollContainer then
        self:_RefreshColumnItemsDisplay("destroyList", self.guiFrame.columnControls.destroyList.scrollContainer)
    end
end

-- Internal helper to refresh content of one list column
function ByFireBePurged:_RefreshColumnItemsDisplay(listType, scrollContainerWidget)
    if not scrollContainerWidget then
        self:Print("Error: Attempted to refresh a nil scroll container for " .. listType)
        return
    end
    scrollContainerWidget:ReleaseChildren() -- Clear previous items

    -- Ensure AceGUI is available
    if not AceGUI then AceGUI = LibStub("AceGUI-3.0") end
    local listData = self.db.profile[listType]
    local count = 0
    local L = self.L -- For localization

    if listData and next(listData) then
        for itemID, _ in pairs(listData) do
            local itemName, itemLink, _, _, _, itemType, itemSubType, _, itemEquipLoc = C_Item.GetItemInfo(itemID)
            local displayItemName = itemLink or itemName or ("ItemID: " .. itemID)

            -- Create a container for the item text and its remove button
            local itemEntryGroup = AceGUI:Create("SimpleGroup")
            if itemEntryGroup then
                itemEntryGroup:SetLayout("Flow") -- Item name and X button side-by-side
                itemEntryGroup:SetFullWidth(true)

                local itemLabel = AceGUI:Create("Label")
                if itemLabel then
                    itemLabel:SetText(displayItemName)
                    -- Let Flow layout manage width or set to fill later if needed
                    itemEntryGroup:AddChild(itemLabel)
                else
                    self:Print("Error creating itemLabel for " .. itemID .. " in " .. listType)
                end

                local removeButton = AceGUI:Create("Button")
                if removeButton then
                    removeButton:SetText("X")
                    removeButton:SetWidth(45) -- Keep slightly wider for clickability / visibility
                    removeButton:SetCallback("OnClick", function()
                        self.db.profile[listType][itemID] = nil
                        self:_RefreshColumnItemsDisplay(listType, scrollContainerWidget) -- Refresh this specific column
                    end)
                    itemEntryGroup:AddChild(removeButton)
                else
                    self:Print("Error creating removeButton for " .. itemID .. " in " .. listType)
                end

                scrollContainerWidget:AddChild(itemEntryGroup)
                count = count + 1
            else
                self:Print("Error creating itemEntryGroup for " .. itemID .. " in " .. listType)
            end
        end
    end

    if count == 0 then
        local emptyLabel = AceGUI:Create("Label")
        if emptyLabel then
            emptyLabel:SetText(self.L["LIST_EMPTY"])
            emptyLabel:SetFullWidth(true)
            scrollContainerWidget:AddChild(emptyLabel)
        else
            self:Print("Error creating emptyLabel for " .. listType)
        end
    end
    scrollContainerWidget:DoLayout()
end

function ByFireBePurged:HandleGUIAddItem(listType, inputWidget)
    local itemString = inputWidget:GetText()
    if not itemString or itemString:trim() == "" then return end

    local itemID, err = self:ParseItemInput(itemString)
    if err or not itemID then
        self:Print(err or L["FEEDBACK_INVALID_ITEM_FORMAT"]:format(itemString))
        return
    end

    local itemName, itemLink = C_Item.GetItemInfo(itemID)
    if not itemName then
        self:Print(L["FEEDBACK_ITEM_INFO_FAILED"]:format(itemID))
        return
    end

    local listNameKey = (listType == "sellList" and L["SELL_LIST_NAME"]) or (listType == "destroyList" and L["DESTROY_LIST_NAME"]) or listType

    if self.db.profile[listType][itemID] then
        self:Print(L["FEEDBACK_ITEM_ALREADY_IN_LIST"]:format(listNameKey, itemLink or itemName))
        return
    end

    self.db.profile[listType][itemID] = true
    self:Print(L["FEEDBACK_ITEM_ADDED"]:format(listNameKey, itemLink or itemName))
    inputWidget:SetText("") -- Clear input
    -- Refresh the specific list that was modified
    if listType == "sellList" and self.guiFrame and self.guiFrame.columnControls.sellList.scrollContainer then
        self:_RefreshColumnItemsDisplay("sellList", self.guiFrame.columnControls.sellList.scrollContainer)
    elseif listType == "destroyList" and self.guiFrame and self.guiFrame.columnControls.destroyList.scrollContainer then
        self:_RefreshColumnItemsDisplay("destroyList", self.guiFrame.columnControls.destroyList.scrollContainer)
    end
end

function ByFireBePurged:HandleGUIRemoveItem(listType, inputWidget)
    -- This function is now effectively deprecated by the per-item 'X' buttons.
    -- We can leave it for now or remove it if no other part calls it.
    -- For safety, let's make it clear it's not the primary way to remove.
    self:Print("Note: Items are typically removed using the 'X' button next to them in the list.")
    local itemString = inputWidget:GetText()
    if not itemString or itemString:trim() == "" then return end

    local itemID, err = self:ParseItemInput(itemString)
    if err or not itemID then
        self:Print(err or L["FEEDBACK_INVALID_ITEM_FORMAT"]:format(itemString))
        return
    end

    local listNameKey = (listType == "sellList" and L["SELL_LIST_NAME"]) or (listType == "destroyList" and L["DESTROY_LIST_NAME"]) or listType
    local itemNameForMessage, itemLinkForMessage = C_Item.GetItemInfo(itemID) -- For message purposes
    local displayItemName = itemLinkForMessage or itemNameForMessage or ("ItemID: " .. itemID)

    if not self.db.profile[listType][itemID] then
        -- Instead, let's make it clear this input box is not the primary removal method
        self:Print(L["FEEDBACK_ITEM_NOT_FOUND_IN_LIST_SPECIFIC"]:format(displayItemName, listNameKey))
        return
    end

    self.db.profile[listType][itemID] = nil
    self:Print(L["FEEDBACK_ITEM_REMOVED"]:format(listNameKey, displayItemName))
    inputWidget:SetText("") -- Clear input
    -- Refresh the specific list that was modified
    if listType == "sellList" and self.guiFrame and self.guiFrame.columnControls.sellList.scrollContainer then
        self:_RefreshColumnItemsDisplay("sellList", self.guiFrame.columnControls.sellList.scrollContainer)
    elseif listType == "destroyList" and self.guiFrame and self.guiFrame.columnControls.destroyList.scrollContainer then
        self:_RefreshColumnItemsDisplay("destroyList", self.guiFrame.columnControls.destroyList.scrollContainer)
    end
end

-- Helper function to parse item ID from string (link or ID)
function ByFireBePurged:ParseItemInput(itemString)
    if not itemString or type(itemString) ~= "string" then
        return nil, L["FEEDBACK_INVALID_ITEM_FORMAT"]:format(tostring(itemString))
    end

    itemString = itemString:trim()
    local itemID

    -- Try to match item link pattern (e.g., |cff...|Hitem:itemID:...|h...|h|r)
    local linkMatch = string.match(itemString, "|Hitem:(%d+):")
    if linkMatch then
        itemID = tonumber(linkMatch)
    end

    if not itemID then
        -- Try to match just a number (itemID)
        local plainID = string.match(itemString, "^%s*(%d+)%s*$")
        if plainID then
            itemID = tonumber(plainID)
        end
    end

    if itemID then
        return itemID
    else
        return nil, L["FEEDBACK_INVALID_ITEM_FORMAT"]:format(itemString)
    end
end

-- These functions are for the AceConfig panel, which we are phasing out for list management.
-- They can be removed or kept if there's any other use for them.
-- For now, I will leave them commented out or to be removed in a later step
-- if confirmed they are fully replaced by the standalone GUI's logic.

-- function ByFireBePurged:AddItemToListGUI(listType, tempInputKey, aceConfigPathToRefresh) ... end
-- function ByFireBePurged:RemoveItemFromListGUI(listType, tempInputKey, aceConfigPathToRefresh) ... end

function ByFireBePurged:GetOptionsTable()
    local options = {
        name = L["ADDON_NAME"] .. " " .. L["SETTINGS"],
        type = "group",
        args = {
            general = {
                type = "group",
                name = L["SETTINGS_GENERAL"],
                order = 1,
                args = {
                    autoSell = {
                        type = "toggle",
                        name = L["SETTINGS_ENABLE_AUTO_SELL"],
                        desc = L["SETTINGS_ENABLE_AUTO_SELL_TOOLTIP"],
                        order = 1,
                        get = function(info) return self.db.profile.autoSell end,
                        set = function(info, value) self.db.profile.autoSell = value end,
                    },
                    debugMode = {
                        type = "toggle",
                        name = L["SETTINGS_ENABLE_DEBUG_MODE"],
                        desc = L["SETTINGS_ENABLE_DEBUG_MODE_TOOLTIP"],
                        order = 2,
                        get = function(info) return self.db.profile.debugMode end,
                        set = function(info, value) self.db.profile.debugMode = value end,
                    },
                    slashHeader = {
                        type = "header",
                        name = L["SLASH_COMMANDS_HEADER"],
                        order = 10,
                    },
                    slashDesc = {
                        type = "description",
                        name = L["SLASH_COMMANDS_DESCRIPTION"],
                        order = 11,
                        fontSize = "medium",
                    },
                    guiInfo = {
                        type = "description",
                        name = "List management is now handled by the standalone GUI. Type /bfbp config to open it.",
                        order = 12,
                        fontSize = "medium",
                    }
                }
            },
            -- Removed "lists" group as it's moving to a standalone GUI
            -- lists = { ... }
        }
    }
    return options
end

function ByFireBePurged:FormatItemList(itemList)
    local formattedString = ""
    local count = 0
    if itemList and next(itemList) then
        for itemID, _ in pairs(itemList) do
            local itemName, itemLink = C_Item.GetItemInfo(itemID)
            if itemName and itemLink then
                formattedString = formattedString .. itemLink .. "\\n"
            elseif itemName then
                formattedString = formattedString .. itemName .. " (ID: " .. tostring(itemID) .. ")\\n"
            else
                formattedString = formattedString .. "Unknown Item (ID: " .. tostring(itemID) .. ")\\n"
            end
            count = count + 1
        end
    end
    if count == 0 then
        return L["LIST_EMPTY"]
    end
    return formattedString
end

-- Chat command handling for GUI interactions and direct list modification will be added later.
