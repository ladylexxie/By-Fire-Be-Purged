local addonName, addonTable = ...

local BFBP = BFBP or {}

BFBP.DB = BFBP.DB or {
    sellList = {},
    destroyList = {},
    settings = {}
}

BFBP.Config = {
    debugMode = false,
    autoSell = true,
    autoDestroy = false
}

-- Database interaction functions
function BFBP:AddItemToList(list, itemID)
    if not itemID or type(itemID) ~= "number" then
        if self.Config.debugMode then print(addonName .. ": Invalid itemID for AddItem:", itemID) end
        return
    end

    if not list or type(list) ~= "string" then
        if self.Config.debugMode then print(addonName .. ": Invalid list name for AddItem:", list) end
        return
    end

    BFBP.DB[list] = BFBP.DB[list] or {}
    if not BFBP.DB[list][itemID] then
        BFBP.DB[list][itemID] = true
        local _, link = C_Item.GetItemInfo(itemID)
        print(addonName ..
        ": Added item " .. (link or "Unknown Item") .. " (ID: " .. itemID .. ") to the " .. list .. ".")
    else
        print(addonName .. ": Item ID " .. itemID .. " is already in the " .. list .. ".")
    end
end

function BFBP:RemoveItemFromList(list, itemID)
    if not itemID or type(itemID) ~= "number" then
        if self.Config.debugMode then print(addonName .. ": Invalid itemID for RemoveItem:", itemID) end
        return
    end

    if not list or type(list) ~= "string" then
        if self.Config.debugMode then print(addonName .. ": Invalid list name for RemoveItem:", list) end
        return
    end

    BFBP.DB[list] = BFBP.DB[list] or {}
    if BFBP.DB[list][itemID] then
        BFBP.DB[list][itemID] = nil
        local _, link = C_Item.GetItemInfo(itemID)
        print(addonName ..
        ": Removed item " .. (link or "Unknown Item") .. " (ID: " .. itemID .. ") from the " .. list .. ".")
    else
        print(addonName .. ": Item ID " .. itemID .. " is not in the " .. list .. ".")
    end
end

function BFBP:ListItems(list)
    if not list or type(list) ~= "string" then
        if self.Config.debugMode then print(addonName .. ": Invalid list name for ListItems:", list) end
        return
    end

    if list == "sellList" then
        print(addonName .. ": Items to sell:")
    elseif list == "destroyList" then
        print(addonName .. ": Items to destroy:")
    else
        print(addonName .. ": Unknown list: " .. list)
        return
    end

    if not BFBP.DB[list] or next(BFBP.DB[list]) == nil then
        print(" - No items in this list.")
        return
    end

    for itemID in pairs(BFBP.DB[list]) do
        local _, link = C_Item.GetItemInfo(itemID)
        print(" - " .. (link or "Unknown Item") .. " (ID: " .. itemID .. ")")
    end
end

function BFBP:SellItems()
    if not MerchantFrame or not MerchantFrame:IsShown() then return end
    if not BFBP.Config.autoSell then return end -- Check if auto-selling is enabled

    if self.Config.debugMode then print(addonName .. ": Attempting to sell items.") end

    -- Ensure items table exists in BFBP.DB
    if not BFBP.DB.sellList then
        if self.Config.debugMode then print(addonName .. ": sellList does not exist in BFBP.DB.") end
        return
    end

    local itemsSold = 0
    for itemID in pairs(BFBP.DB.sellList) do
        -- WoW API functions for container interaction
        local useContainerItemFunc = C_Container and C_Container.UseContainerItem
        local getContainerItemLinkFunc = C_Container and C_Container.GetContainerItemLink
        local getItemInfoInstantFunc = C_Item and C_Item.GetItemInfoInstant
        local getContainerNumSlotsFunc = C_Container and C_Container.GetContainerNumSlots

        if not useContainerItemFunc or not getContainerItemLinkFunc or not getItemInfoInstantFunc or not getContainerNumSlotsFunc then
            if self.Config.debugMode then print(addonName ..
                ": Required C_Container or C_Item API functions not available.") end
            return
        end

        for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
            local numSlots = getContainerNumSlotsFunc(bag)
            if numSlots then
                for slot = 1, numSlots do
                    local itemLink = getContainerItemLinkFunc(bag, slot)
                    if itemLink then
                        local currentItemID = getItemInfoInstantFunc(itemLink)
                        if currentItemID == itemID then
                            local itemName, _, _, _, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(itemLink) -- Get more info for print
                            print(addonName .. ": Selling " .. (itemName or itemLink))
                            useContainerItemFunc(bag, slot)
                            itemsSold = itemsSold + 1
                            -- IMPORTANT: Selling an item may change slot positions or counts.
                            -- For simplicity, this example doesn't re-scan or adjust,
                            -- but for very robust selling of many items, you might need to handle this.
                            -- Often, the game handles these updates well enough for sequential sales.
                        end
                    end
                end
            end
        end
    end
    if itemsSold > 0 then
        print(addonName .. ": Finished selling. Sold " .. itemsSold .. " item(s).")
    elseif self.Config.debugMode then
        print(addonName .. ": No items from the sell list found in bags to sell.")
    end
end

function BFBP:DestroyItems()
    if self.Config.debugMode then print(addonName .. ": Attempting to destroy items from destroyList.") end

    if not BFBP.DB.destroyList or next(BFBP.DB.destroyList) == nil then
        if self.Config.debugMode then print(addonName .. ": destroyList is empty or does not exist.") end
        return
    end

    local itemsDestroyedThisRun = 0
    -- Required API functions
    local pickupContainerItemFunc = C_Container and C_Container.PickupContainerItem
    local deleteCursorItemFunc = DeleteCursorItem -- This is a global function
    local getContainerItemLinkFunc = C_Container and C_Container.GetContainerItemLink
    local getItemInfoInstantFunc = C_Item and C_Item.GetItemInfoInstant
    local getContainerNumSlotsFunc = C_Container and C_Container.GetContainerNumSlots
    local clearCursorFunc = ClearCursor     -- To clear cursor if something goes wrong
    local cursorHasItemFunc = CursorHasItem -- To check if cursor has an item

    if not pickupContainerItemFunc or not deleteCursorItemFunc or not getContainerItemLinkFunc
        or not getItemInfoInstantFunc or not getContainerNumSlotsFunc or not clearCursorFunc or not cursorHasItemFunc then
        print(addonName .. ": Error - Required API functions for destroying items are not available.")
        return
    end

    for itemIDToDestroy in pairs(BFBP.DB.destroyList) do
        -- Loop through bags for each itemID.
        -- We iterate bags from backpack to other bags.
        for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
            local rescanCurrentBag = true -- Flag to control re-scanning the current bag

            while rescanCurrentBag do
                rescanCurrentBag = false -- Assume no rescan needed for this pass
                local numSlots = getContainerNumSlotsFunc(bag)

                if numSlots and numSlots > 0 then
                    for slot = 1, numSlots do
                        local itemLink = getContainerItemLinkFunc(bag, slot)
                        if itemLink then
                            local currentItemID = getItemInfoInstantFunc(itemLink)
                            if currentItemID == itemIDToDestroy then
                                local itemName, _, _, _, _, _, _, _, _, _ = C_Item.GetItemInfo(itemLink)
                                print(addonName ..
                                ": Attempting to destroy " ..
                                (itemName or itemLink) .. " (Bag: " .. bag .. ", Slot: " .. slot .. ")")

                                pickupContainerItemFunc(bag, slot)

                                if cursorHasItemFunc() then
                                    deleteCursorItemFunc()
                                    itemsDestroyedThisRun = itemsDestroyedThisRun + 1
                                    print(addonName .. ": Destroyed " .. (itemName or itemLink))

                                    -- Item was destroyed, inventory shifted. Need to rescan this bag.
                                    rescanCurrentBag = true
                                    break -- Exit the slot loop to restart it for the current bag
                                else
                                    print(addonName .. ": Failed to pick up " .. (itemName or itemLink) .. " to cursor.")
                                    if cursorHasItemFunc() then -- Should not happen if pickup failed, but as a safeguard
                                        clearCursorFunc()
                                    end
                                end
                            end
                        end
                    end -- End of slot loop
                else
                    -- No slots in this bag, or bag not found, so stop trying to rescan it.
                    rescanCurrentBag = false
                end

                -- If rescanCurrentBag is true, the while loop continues for the same bag.
                -- If false, it breaks, and we move to the next bag (or next itemIDToDestroy).
            end -- End of while rescanCurrentBag
        end     -- End of bag loop
    end         -- End of itemIDToDestroy loop

    if itemsDestroyedThisRun > 0 then
        print(addonName .. ": Finished destroying. Destroyed " .. itemsDestroyedThisRun .. " item(s) in this run.")
    else
        print(addonName .. ": No items from the destroy list found in bags to destroy in this run.")
    end

    -- Ensure cursor is cleared if it somehow ended up with an item
    if cursorHasItemFunc() and clearCursorFunc then
        print(addonName .. ": Clearing unexpected item from cursor after destroy operation.")
        clearCursorFunc()
    end
end

-- Event handler for the addon
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:RegisterEvent("ADDON_LOADED") -- Keep this if you have initialization logic for ADDON_LOADED

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "MERCHANT_SHOW" then
        if BFBP.Config.autoSell then -- Check the config before selling
            BFBP:SellItems()
        end
    elseif event == "ADDON_LOADED" then
        if select(1, ...) == addonName then
            -- Initialize database if it's not already initialized by defaults
            BFBP.DB.sellList = BFBP.DB.sellList or {}
            BFBP.DB.destroyList = BFBP.DB.destroyList or {}
            BFBP.DB.settings = BFBP.DB.settings or {}
            print(addonName .. " loaded. Type /bfbp help for commands.")
        end
    end
end)

-- Slash commands
SLASH_BFBP1 = "/bfbp"
SlashCmdList["BFBP"] = function(msg)
    local parts = {}
    for part in msg:gmatch("%S+") do table.insert(parts, part) end
    local cmd = parts[1] and parts[1]:lower() or "help"
    local list = parts[2] and parts[2]:lower()
    local itemArg = parts[3] -- This could be an itemID or itemLink

    if cmd == "add" then
        if not list or not itemArg then
            print(addonName .. ": Usage: /bfbp add <sell||destroy> <itemID||itemLink>")
            return
        end
        local itemID = tonumber(itemArg)
        if not itemID then -- Try to get ID from itemLink
            local foundItemID = C_Item.GetItemInfoInstant(itemArg)
            if foundItemID then
                itemID = foundItemID
            else
                print(addonName .. ": Invalid itemID or itemLink: " .. itemArg)
                return
            end
        end

        if list == "sell" then
            BFBP:AddItemToList("sellList", itemID)
        elseif list == "destroy" then
            BFBP:AddItemToList("destroyList", itemID)
        else
            print(addonName .. ": Invalid list type. Use 'sell' or 'destroy'.")
        end
    elseif cmd == "remove" then
        if not list or not itemArg then
            print(addonName .. ": Usage: /bfbp remove <sell||destroy> <itemID||itemLink>")
            return
        end
        local itemID = tonumber(itemArg)
        if not itemID then -- Try to get ID from itemLink
            local foundItemID = C_Item.GetItemIDFromLink(itemArg)
            if foundItemID then
                itemID = foundItemID
            else
                print(addonName .. ": Invalid itemID or itemLink: " .. itemArg)
                return
            end
        end

        if list == "sell" then
            BFBP:RemoveItemFromList("sellList", itemID)
        elseif list == "destroy" then
            BFBP:RemoveItemFromList("destroyList", itemID)
        else
            print(addonName .. ": Invalid list type. Use 'sell' or 'destroy'.")
        end
    elseif cmd == "list" then
        if not list then
            print(addonName .. ": Usage: /bfbp list <sell||destroy||all>")
            return
        end
        if list == "sell" then
            BFBP:ListItems("sellList")
        elseif list == "destroy" then
            BFBP:ListItems("destroyList")
        elseif list == "all" then
            BFBP:ListItems("sellList")
            BFBP:ListItems("destroyList")
        else
            print(addonName .. ": Invalid list type. Use 'sell', 'destroy', or 'all'.")
        end
    elseif cmd == "destroyitems" then -- New command to trigger destruction
        BFBP:DestroyItems()
    elseif cmd == "sellitems" then    -- Manual trigger for selling, if needed
        if MerchantFrame and MerchantFrame:IsShown() then
            BFBP:SellItems()
        else
            print(addonName .. ": You need to have a merchant window open to use sellitems.")
        end
    elseif cmd == "help" or cmd == "" then
        print(addonName .. ": Commands:")
        print("  /bfbp add <sell||destroy> <itemID||itemLink> - Add item to list.")
        print("  /bfbp remove <sell||destroy> <itemID||itemLink> - Remove item from list.")
        print("  /bfbp list <sell||destroy||all> - List items in specified list(s).")
        print("  /bfbp sellitems - Manually attempts to sell items from sellList (merchant window must be open).")
        print("  /bfbp destroyitems - Attempts to destroy all items in the destroyList.")
        print("  /bfbp toggle <debug||autosell> - Toggles the specified setting.")
    elseif cmd == "toggle" then
        local setting = list -- reusing 'list' variable for the setting name
        if setting == "debug" then
            BFBP.Config.debugMode = not BFBP.Config.debugMode
            print(addonName .. ": Debug mode " .. (BFBP.Config.debugMode and "enabled" or "disabled") .. ".")
        elseif setting == "autosell" then
            BFBP.Config.autoSell = not BFBP.Config.autoSell
            print(addonName ..
            ": Auto sell on merchant visit " .. (BFBP.Config.autoSell and "enabled" or "disabled") .. ".")
        else
            print(addonName .. ": Unknown setting to toggle: " .. (setting or "nil") .. ". Use 'debug' or 'autosell'.")
        end
    else
        print(addonName .. ": Unknown command '" .. cmd .. "'. Type /bfbp help for commands.")
    end
end

print(addonName .. " initialized. Use /bfbp for commands.")
