local addonName = ...
local ByFireBePurged = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

-- Default database values
local defaults = {
    profile = {
        autoSell = true,
        enableItemDestruction = false,
        debugMode = false,
        sellList = {},
        destroyList = {}
    }
}

local AceGUI = nil

-- Helper to print messages with a fiery colored addon name
function ByFireBePurged:PrintFiery(message)
    if not self.L or not self.L["ADDON_NAME"] then -- Fallback if L or ADDON_NAME isn't loaded yet
        _G.print(("(%s): %s"):format(addonName, message)) -- Use global print
        return
    end
    local fieryPrefix = "|cFFFF7F00" .. self.L["ADDON_NAME"] .. "|r: "
    _G.print(fieryPrefix .. message) -- Use global print
end

function ByFireBePurged:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("ByFireBePurgedDB", defaults, true)
    self.tempGuiInputValues = {}
    self.guiFrame = nil
    self.L = L -- Ensure self.L is set for PrintFiery
    AceGUI = LibStub("AceGUI-3.0")

    -- Register options panel
    LibStub("AceConfig-3.0"):RegisterOptionsTable(L["ADDON_NAME"], self:GetOptionsTable(), "/bfbp")
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(L["ADDON_NAME"], L["ADDON_NAME"])

    -- Register slash command
    self:RegisterChatCommand("bfbp", "SlashCommandHandler")
    self:RegisterChatCommand("byfirebepurged", "SlashCommandHandler")

    self:PrintFiery(L["MSG_INITIALIZED"])
end

function ByFireBePurged:OnEnable()
    self:PrintFiery(L["MSG_ENABLED"])
    self:RegisterEvent("MERCHANT_SHOW", "SellTrashItems")
end

function ByFireBePurged:OnDisable()
    self:PrintFiery(L["MSG_DISABLED"])
    self:UnregisterEvent("MERCHANT_SHOW")
end

function ByFireBePurged:SlashCommandHandler(input)
    input = input:trim():lower()
    if input == "" then
        self:ToggleStandaloneGUI()
    elseif input == "help" then
        self:Print(L["HELP_HEADER"])
        self:Print(L["HELP_CONFIG_CMD"])
        self:Print(L["HELP_DESTROY_CMD"])
        self:Print(L["HELP_HELP_CMD"])
    elseif input == "destroy" then
        self:ExecuteDestroyListItems()
    else
        self:PrintFiery(L["FEEDBACK_INVALID_COMMAND_FORMATTED"]:format(input))
        self:ToggleStandaloneGUI()
    end
end

function ByFireBePurged:CreateStandaloneGUI()
    if self.guiFrame then return end

    if not AceGUI then AceGUI = LibStub("AceGUI-3.0") end

    -- Main Frame
    self.guiFrame = AceGUI:Create("Frame")
    if not self.guiFrame then
        self:PrintFiery(L["ERROR_GUI_FRAME_CREATE"])
        return
    end

    self.guiFrame:SetTitle(self.L["GUI_ITEM_LIST_MANAGEMENT_TITLE"])
    self.guiFrame:SetStatusText(self.L["ADDON_NAME"])
    self.guiFrame:SetLayout("Fill")
    self.guiFrame:SetWidth(600)
    self.guiFrame:SetHeight(450)
    self.guiFrame:EnableResize(false)

    self.guiFrame.columnControls = {
        sellList = {},
        destroyList = {}
    }

    -- Container for the two columns
    local columnContainer = AceGUI:Create("SimpleGroup")
    if not columnContainer then
        self:PrintFiery(L["ERROR_COLUMN_CONTAINER_CREATE"])
        self.guiFrame = nil
        return
    end
    columnContainer:SetLayout("Manual")
    columnContainer:SetFullWidth(true)
    columnContainer:SetFullHeight(true)
    self.guiFrame:AddChild(columnContainer)

    local backdropInfo = {
        bgFile = "Interface\\Buttons\\WHITE8X8",
    }
    local backgroundColor = {0.05, 0.05, 0.05, 0.7}
    local borderColor = {0, 0, 0, 0.8}
    local borderThickness = 1

    -- Sell List Column
    local sellColumnGroup = AceGUI:Create("SimpleGroup")
    if not sellColumnGroup then
        self:PrintFiery(L["ERROR_SELL_COLUMN_CREATE"])
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
        self:PrintFiery(L["ERROR_DESTROY_COLUMN_CREATE"])
        self.guiFrame = nil
        return
    end

    destroyColumnGroup:SetLayout("Flow")
    destroyColumnGroup:SetWidth(275)
    destroyColumnGroup:SetFullHeight(true)
    columnContainer:AddChild(destroyColumnGroup)
    destroyColumnGroup:SetPoint("TOPLEFT", sellColumnGroup.frame, "TOPRIGHT", 15, 0)

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

-- Function to populate a column with its title, input fields, and scroll frame
function ByFireBePurged:_PopulateColumnWithControls(listType, parentColumnGroup, controlsTable)
    local AceGUI = LibStub("AceGUI-3.0")
    local L = self.L

    -- Column Title
    local title = AceGUI:Create("Label")
    local titleText = (listType == "sellList" and L["SELL_LIST"]) or (listType == "destroyList" and L["DESTROY_LIST"]) or listType
    title:SetText(titleText)
    title:SetFontObject(GameFontNormalLarge)
    title:SetFullWidth(true)
    if title.SetJustifyH then
        title:SetJustifyH("CENTER")
    elseif title.fontstring and title.fontstring.SetJustifyH then
        title.fontstring:SetJustifyH("CENTER")
    else
        if listType == "sellList" then self:PrintFiery(L["DEBUG_JUSTIFY_H_FAIL"]) end
    end
    parentColumnGroup:AddChild(title)

    -- Add Item InputBox
    local addBox = AceGUI:Create("EditBox")
    if not addBox then self:PrintFiery(L["ERROR_ADD_BOX_CREATE"]:format(listType)); return end
    addBox:SetLabel(L["GUI_ADD_ITEM_LABEL"])
    addBox:SetFullWidth(true)
    addBox:SetCallback("OnEnterPressed", function(widget) self:HandleGUIAddItem(listType, widget) end)
    parentColumnGroup:AddChild(addBox)
    controlsTable.addBox = addBox

    -- Spacer
    local spacer = AceGUI:Create("Label")
    spacer:SetText(" ")
    spacer:SetHeight(5)
    parentColumnGroup:AddChild(spacer)

    -- ScrollFrame for items
    local scroll = AceGUI:Create("ScrollFrame")
    if not scroll then self:PrintFiery(L["ERROR_SCROLL_FRAME_CREATE"]:format(listType)); return end
    scroll:SetLayout("Flow")
    scroll:SetFullWidth(true)
    scroll:SetHeight(300)
    parentColumnGroup:AddChild(scroll)
    controlsTable.scrollContainer = scroll
end

function ByFireBePurged:ToggleStandaloneGUI()
    if not self.guiFrame then
        self:CreateStandaloneGUI()
    end

    if not self.guiFrame then
        self:PrintFiery(L["ERROR_GUI_FRAME_INIT_FAIL"])
        return
    end

    if self.guiFrame:IsShown() then
        self.guiFrame:Hide()
    else
        self.guiFrame:Show()
        if self.guiFrame.columnControls.sellList.scrollContainer then
            self:_RefreshColumnItemsDisplay("sellList", self.guiFrame.columnControls.sellList.scrollContainer)
        else
            self:PrintFiery(L["MSG_SELL_LIST_SCROLL_REFRESH_FAIL"])
        end

        if self.guiFrame.columnControls.destroyList.scrollContainer then
            self:_RefreshColumnItemsDisplay("destroyList", self.guiFrame.columnControls.destroyList.scrollContainer)
        else
            self:PrintFiery(L["MSG_DESTROY_LIST_SCROLL_REFRESH_FAIL"])
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
        self:PrintFiery(L["ERROR_SCROLL_CONTAINER_REFRESH_FAIL"]:format(listType))
        return
    end
    scrollContainerWidget:ReleaseChildren()

    if not AceGUI then AceGUI = LibStub("AceGUI-3.0") end
    local listData = self.db.profile[listType]
    local count = 0

    if listData and next(listData) then
        for itemID, _ in pairs(listData) do
            local itemName, itemLink, _, _, _, _, _, _, _ = C_Item.GetItemInfo(itemID)
            local displayItemName = itemLink or itemName or ("ItemID: " .. itemID)

            -- Create a container for the item text and its remove button
            local itemEntryGroup = AceGUI:Create("SimpleGroup")
            if itemEntryGroup then
                itemEntryGroup:SetLayout("Flow")
                itemEntryGroup:SetFullWidth(true)

                local itemLabel = AceGUI:Create("Label")
                if itemLabel then
                    itemLabel:SetText(displayItemName)
                    itemEntryGroup:AddChild(itemLabel)
                else
                    self:PrintFiery(L["ERROR_ITEM_LABEL_CREATE"]:format(itemID, listType))
                end

                local removeButton = AceGUI:Create("Button")
                if removeButton then
                    removeButton:SetText("X")
                    removeButton:SetWidth(45)
                    removeButton:SetCallback("OnClick", function()
                        self.db.profile[listType][itemID] = nil
                        self:_RefreshColumnItemsDisplay(listType, scrollContainerWidget)
                    end)
                    itemEntryGroup:AddChild(removeButton)
                else
                    self:PrintFiery(L["ERROR_REMOVE_BUTTON_CREATE"]:format(itemID, listType))
                end

                scrollContainerWidget:AddChild(itemEntryGroup)
                count = count + 1
            else
                self:PrintFiery(L["ERROR_ITEM_ENTRY_GROUP_CREATE"]:format(itemID, listType))
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
            self:PrintFiery(L["ERROR_EMPTY_LABEL_CREATE"]:format(listType))
        end
    end
    scrollContainerWidget:DoLayout()
end

function ByFireBePurged:HandleGUIAddItem(listType, inputWidget)
    local itemString = inputWidget:GetText()
    if not itemString or itemString:trim() == "" then return end

    local itemID, err = self:ParseItemInput(itemString)
    if err or not itemID then
        self:PrintFiery(err or L["FEEDBACK_INVALID_ITEM_FORMAT_GENERIC"]:format(itemString))
        return
    end

    local itemName, itemLink = C_Item.GetItemInfo(itemID)
    if not itemName then
        self:PrintFiery(L["FEEDBACK_ITEM_INFO_FAILED_GENERIC"]:format(itemID))
        return
    end

    local listNameKey = (listType == "sellList" and L["SELL_LIST_NAME"]) or (listType == "destroyList" and L["DESTROY_LIST_NAME"]) or listType

    if self.db.profile[listType][itemID] then
        self:PrintFiery(L["FEEDBACK_ITEM_ALREADY_IN_LIST_FORMATTED"]:format(listNameKey, itemLink or itemName))
        return
    end

    self.db.profile[listType][itemID] = true
    self:PrintFiery(L["FEEDBACK_ITEM_ADDED_FORMATTED"]:format(listNameKey, itemLink or itemName))
    inputWidget:SetText("")

    if listType == "sellList" and self.guiFrame and self.guiFrame.columnControls.sellList.scrollContainer then
        self:_RefreshColumnItemsDisplay("sellList", self.guiFrame.columnControls.sellList.scrollContainer)
    elseif listType == "destroyList" and self.guiFrame and self.guiFrame.columnControls.destroyList.scrollContainer then
        self:_RefreshColumnItemsDisplay("destroyList", self.guiFrame.columnControls.destroyList.scrollContainer)
    end
end

function ByFireBePurged:HandleGUIRemoveItem(listType, inputWidget)
    self:PrintFiery(L["NOTE_REMOVE_VIA_X_BUTTON"])
    local itemString = inputWidget:GetText()
    if not itemString or itemString:trim() == "" then return end

    local itemID, err = self:ParseItemInput(itemString)
    if err or not itemID then
        self:PrintFiery(err or L["FEEDBACK_INVALID_ITEM_FORMAT_GENERIC"]:format(itemString))
        return
    end

    local listNameKey = (listType == "sellList" and L["SELL_LIST_NAME"]) or (listType == "destroyList" and L["DESTROY_LIST_NAME"]) or listType
    local itemNameForMessage, itemLinkForMessage = C_Item.GetItemInfo(itemID)
    local displayItemName = itemLinkForMessage or itemNameForMessage or ("ItemID: " .. itemID)

    if not self.db.profile[listType][itemID] then
        self:PrintFiery(L["FEEDBACK_ITEM_NOT_FOUND_IN_LIST_FORMATTED"]:format(displayItemName, listNameKey))
        return
    end

    self.db.profile[listType][itemID] = nil
    self:PrintFiery(L["FEEDBACK_ITEM_REMOVED_FORMATTED"]:format(listNameKey, displayItemName))
    inputWidget:SetText("")

    if listType == "sellList" and self.guiFrame and self.guiFrame.columnControls.sellList.scrollContainer then
        self:_RefreshColumnItemsDisplay("sellList", self.guiFrame.columnControls.sellList.scrollContainer)
    elseif listType == "destroyList" and self.guiFrame and self.guiFrame.columnControls.destroyList.scrollContainer then
        self:_RefreshColumnItemsDisplay("destroyList", self.guiFrame.columnControls.destroyList.scrollContainer)
    end
end

-- Helper function to parse item ID from string (link or ID)
function ByFireBePurged:ParseItemInput(itemString)
    if not itemString or type(itemString) ~= "string" then
        return nil, L["FEEDBACK_INVALID_ITEM_FORMAT_PARSE_ERROR"]:format(tostring(itemString))
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
        return nil, L["FEEDBACK_INVALID_ITEM_FORMAT_PARSE_ERROR"]:format(itemString)
    end
end

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
                    enableItemDestruction = {
                        type = "toggle",
                        name = L["SETTINGS_ENABLE_ITEM_DESTRUCTION"],
                        desc = L["SETTINGS_ENABLE_ITEM_DESTRUCTION_TOOLTIP"],
                        order = 2,
                        get = function(info) return self.db.profile.enableItemDestruction end,
                        set = function(info, value) self.db.profile.enableItemDestruction = value end,
                    },
                    debugMode = {
                        type = "toggle",
                        name = L["SETTINGS_ENABLE_DEBUG_MODE"],
                        desc = L["SETTINGS_ENABLE_DEBUG_MODE_TOOLTIP"],
                        order = 3,
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
                        name = L["SETTINGS_GUI_INFO_MSG"],
                        order = 12,
                        fontSize = "medium",
                    }
                }
            }
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
                formattedString = formattedString .. itemLink .. "\n"
            elseif itemName then
                formattedString = formattedString .. itemName .. " (ID: " .. tostring(itemID) .. ")\n"
            else
                formattedString = formattedString .. "Unknown Item (ID: " .. tostring(itemID) .. ")\n"
            end
            count = count + 1
        end
    end
    if count == 0 then
        return L["LIST_EMPTY"]
    end
    return formattedString
end

-- Function to automatically sell items from the sell list
function ByFireBePurged:SellTrashItems()
    if not self.db.profile.autoSell then
        if self.db.profile.debugMode then
            self:PrintFiery(L["DEBUG_AUTO_SELL_DISABLED_MSG"])
        end
        return
    end

    if self.db.profile.debugMode then
        self:PrintFiery(L["DEBUG_MERCHANT_EVENT_SELL_START_MSG"])
    end

    local itemsSoldCount = 0
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID and self.db.profile.sellList[itemID] then
                local itemName, itemLink, _, _, _, _, _, _, _, itemSellPrice = C_Item.GetItemInfo(itemID)
                local displayName = itemLink or itemName or ("ItemID: " .. itemID)

                if itemSellPrice and itemSellPrice > 0 then
                    C_Container.UseContainerItem(bag, slot)
                    if self.db.profile.debugMode then
                        self:PrintFiery(L["FEEDBACK_ITEM_SOLD_MSG"]:format(displayName))
                    end
                    itemsSoldCount = itemsSoldCount + 1
                elseif self.db.profile.debugMode then
                    self:PrintFiery(L["FEEDBACK_ITEM_NOT_SELLABLE_MSG"]:format(displayName))
                end
            end
        end
    end

    if itemsSoldCount > 0 then
        self:PrintFiery(L["FEEDBACK_TRANSACTION_COMPLETE_MSG"]:format(itemsSoldCount))
    elseif self.db.profile.debugMode then
        self:PrintFiery(L["DEBUG_NO_SELLABLE_ITEMS_FOUND_MSG"])
    end
end

-- Renamed function, now triggered by slash command
function ByFireBePurged:ExecuteDestroyListItems()
    if not self.db.profile.enableItemDestruction then
        if self.db.profile.debugMode then
            self:PrintFiery(L["DEBUG_ITEM_DESTRUCTION_DISABLED_MSG"])
        end
        self:PrintFiery(L["FEEDBACK_ITEM_DESTRUCTION_TOGGLE_OFF_MSG"])
        return
    end

    if not next(self.db.profile.destroyList) then
        if self.db.profile.debugMode then
            self:PrintFiery(L["DEBUG_DESTROY_LIST_EMPTY_MSG"])
        end
        self:PrintFiery(L["FEEDBACK_DESTROY_LIST_IS_EMPTY_MSG"])
        return
    end

    if self.db.profile.debugMode then
        self:PrintFiery(L["DEBUG_MANUAL_DESTROY_SCAN_START_MSG"])
    end

    local pickupItemFunc = C_Container and C_Container.PickupContainerItem
    local deleteCursorFunc = _G.DeleteCursorItem
    local getNumSlotsFunc = C_Container and C_Container.GetContainerNumSlots
    local getItemIDInSlotFunc = C_Container and C_Container.GetContainerItemID
    local getItemDisplayInfoFunc = C_Item and C_Item.GetItemInfo
    local clearCursorAPI = _G.ClearCursor
    local hasItemCursorAPI = _G.CursorHasItem

    if not (pickupItemFunc and deleteCursorFunc and getNumSlotsFunc and getItemIDInSlotFunc and getItemDisplayInfoFunc and clearCursorAPI and hasItemCursorAPI) then
        self:PrintFiery(L["FEEDBACK_API_FUNCTIONS_MISSING_FOR_DESTROY_MSG"])
        return
    end

    local itemsDestroyedSuccessfully = 0

    for itemIDToDestroy, _ in pairs(self.db.profile.destroyList) do
        for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
            local numSlots = getNumSlotsFunc(bag) -- Initial number of slots for this bag
            local slot = 1
            while slot <= numSlots do
                local itemInSlotID = getItemIDInSlotFunc(bag, slot)

                if itemInSlotID and itemInSlotID == itemIDToDestroy then
                    local itemName, actualItemLink = getItemDisplayInfoFunc(itemInSlotID)
                    local displayName = actualItemLink or itemName or ("ItemID: " .. itemInSlotID)

                    if self.db.profile.debugMode then
                        self:PrintFiery(L["FEEDBACK_ATTEMPTING_TO_DESTROY_ITEM_MSG"]:format(displayName, bag, slot))
                    end

                    pickupItemFunc(bag, slot)

                    if hasItemCursorAPI() then
                        deleteCursorFunc()
                        itemsDestroyedSuccessfully = itemsDestroyedSuccessfully + 1
                        self:PrintFiery(L["FEEDBACK_ITEM_DESTROYED_SUCCESS_MSG"]:format(displayName))

                        -- Item was destroyed, inventory may have shifted.
                        -- Update numSlots as it might have changed (though less likely for simple item removal vs bag removal)
                        numSlots = getNumSlotsFunc(bag)
                        -- Do not increment slot; the current slot index will be re-evaluated with its new content (or empty state).
                        -- slot = slot + 1
                    else
                        self:PrintFiery(L["FEEDBACK_ITEM_PICKUP_FAILED_MSG"]:format(displayName))
                        if hasItemCursorAPI() then -- Safeguard if pickup failed but cursor somehow got an item
                            clearCursorAPI()
                        end
                        -- slot = slot + 1 -- Move to the next slot if pickup failed to avoid an infinite loop on a problematic slot.
                    end
                    slot = slot + 1
                else
                    slot = slot + 1 -- Item in slot does not match, or slot is empty; move to the next slot.
                end
            end -- End of slot loop (while)
        end -- End of bag loop
    end -- End of itemIDToDestroy loop

    if itemsDestroyedSuccessfully > 0 then
        self:PrintFiery(L["FEEDBACK_DESTROY_RUN_COMPLETE_MSG"]:format(itemsDestroyedSuccessfully))
    elseif self.db.profile.debugMode and itemsDestroyedSuccessfully == 0 then
        self:PrintFiery(L["FEEDBACK_NO_ITEMS_DESTROYED_IN_RUN_MSG"])
    end

    if hasItemCursorAPI() and clearCursorAPI then
        if self.db.profile.debugMode then
            self:PrintFiery(L["FEEDBACK_CURSOR_CLEARED_UNEXPECTED_MSG"])
        end
        clearCursorAPI()
    end
end
