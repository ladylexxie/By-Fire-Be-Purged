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

function ByFireBePurged:OnInitialize()
    -- Called when the addon is first loaded, before OnEnable
    self.db = LibStub("AceDB-3.0"):New("ByFireBePurgedDB", defaults, true) -- true for profile-based

    -- Register options panel
    LibStub("AceConfig-3.0"):RegisterOptionsTable(L["BY_FIRE_BE_PURGED"], self:GetOptionsTable(), "/bfbp")
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(L["BY_FIRE_BE_PURGED"], L["BY_FIRE_BE_PURGED"])

    self:Print(L["BY_FIRE_BE_PURGED"] .. " initialized.")
end

function ByFireBePurged:OnEnable()
    -- Called when the addon is enabled
    -- Register events, hooks etc. here if needed
    self:Print(L["BY_FIRE_BE_PURGED"] .. " enabled.")
end

function ByFireBePurged:OnDisable()
    -- Called when the addon is disabled
    -- Unregister events, hooks etc. here if needed
    self:Print(L["BY_FIRE_BE_PURGED"] .. " disabled.")
end

function ByFireBePurged:GetOptionsTable()
    local options = {
        name = L["BY_FIRE_BE_PURGED"] .. " " .. L["Settings"],
        type = "group",
        args = {
            general = {
                type = "group",
                name = L["General Settings"],
                order = 1,
                args = {
                    autoSell = {
                        type = "toggle",
                        name = L["Enable Automatic Selling"],
                        desc = L["Enable Automatic Selling_Tooltip"],
                        order = 1,
                        get = function(info) return self.db.profile.autoSell end,
                        set = function(info, value) self.db.profile.autoSell = value end,
                    },
                    debugMode = {
                        type = "toggle",
                        name = L["Enable Debug Mode"],
                        desc = L["Enable Debug Mode_Tooltip"],
                        order = 2,
                        get = function(info) return self.db.profile.debugMode end,
                        set = function(info, value) self.db.profile.debugMode = value end,
                    },
                    slashHeader = {
                        type = "header",
                        name = L["Slash Commands:"],
                        order = 10,
                    },
                    slashDesc = {
                        type = "description",
                        name = L["Slash Command Description"],
                        order = 11,
                        fontSize = "medium",
                    }
                }
            },
            lists = {
                type = "group",
                name = L["Managed Item Lists"],
                order = 2,
                args = {
                    sellListDisplay = {
                        type = "group",
                        name = L["Sell List"],
                        order = 1,
                        args = {
                            header = {
                                type = "header",
                                name = L["Items in Sell List:"],
                                order = 1,
                            },
                            desc = {
                                type = "description",
                                name = function() return self:FormatItemList(self.db.profile.sellList) end,
                                order = 2,
                                width = "full", -- Try to take full width
                                -- TODO: For a more interactive list (e.g., with remove buttons),
                                -- consider using AceGUI-3.0 to build a custom widget or frame.
                            },
                        },
                    },
                    destroyListDisplay = {
                        type = "group",
                        name = L["Destroy List"],
                        order = 2,
                        args = {
                            header = {
                                type = "header",
                                name = L["Items in Destroy List:"],
                                order = 1,
                            },
                            desc = {
                                type = "description",
                                name = function() return self:FormatItemList(self.db.profile.destroyList) end,
                                order = 2,
                                width = "full",
                                -- TODO: (Same as above)
                            },
                        },
                    },
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
                formattedString = formattedString .. itemLink .. "\\n" -- Use double backslash for newline in AceConfig description
            elseif itemName then
                formattedString = formattedString .. itemName .. " (ID: " .. tostring(itemID) .. ")\\n"
            else
                formattedString = formattedString .. "Unknown Item (ID: " .. tostring(itemID) .. ")\\n"
            end
            count = count + 1
        end
    end
    if count == 0 then
        return L["List is empty."]
    end
    return formattedString
end

-- TODO: Implement slash command handling using AceConsole-3.0
-- Example structure:
-- function ByFireBePurged:ChatCommand(input)
--     if not input or input:trim() == "" then
--         -- Show help or open options panel
--         LibStub("AceConfigDialog-3.0"):Open(L["BY_FIRE_BE_PURGED"])
--         return
--     end
--     -- Parse input further for add, remove, list commands
--     -- self:Print("Received command: " .. input)
-- end
