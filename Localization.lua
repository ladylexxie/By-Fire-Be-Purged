local addonName, private = ...
local L = LibStub("AceLocale-3.0"):NewLocale("ByFireBePurged", "enUS", true)
if not L then return end

L["ADDON_NAME"] = "By Fire Be Purged"
L["SETTINGS"] = "Settings"
L["SETTINGS_GENERAL"] = "General Settings"
L["SETTINGS_ENABLE_AUTO_SELL"] = "Enable Automatic Selling"
L["SETTINGS_ENABLE_AUTO_SELL_TOOLTIP"] = "If checked, automatically sells items from your 'sell list' when you visit a merchant."
L["SETTINGS_ENABLE_DEBUG_MODE"] = "Enable Debug Mode"
L["SETTINGS_ENABLE_DEBUG_MODE_TOOLTIP"] = "If checked, prints detailed operational messages to chat for troubleshooting."
L["SELL_LIST"] = "Sell List"
L["DESTROY_LIST"] = "Destroy List"
L["LIST_EMPTY"] = "List is empty."
L["SLASH_COMMANDS_HEADER"] = "Slash Commands:"
L["SLASH_COMMANDS_DESCRIPTION"] = ("Use slash commands to manage your lists:\\n" ..
    "/bfbp add <sell|destroy> <itemLink|itemID>\\n" ..
    "/bfbp list <sell|destroy|all>\\n" ..
    "/bfbp remove <sell|destroy> <itemLink|itemID>\\n" ..
    "/bfbp destroyitems (to destroy items on list)\\n" ..
    "/bfbp help (for all commands)")

-- GUI List Management
L["GUI_ADD_ITEM_LABEL"] = "Item ID or drag & drop to add:"

-- Feedback Messages
L["FEEDBACK_ITEM_ADDED"] = "Item added to %s: %s"
L["FEEDBACK_ITEM_REMOVED"] = "Item removed from %s: %s"
L["FEEDBACK_INVALID_ITEM_FORMAT"] = "Invalid item format: %s"
L["FEEDBACK_ITEM_INFO_FAILED"] = "Could not retrieve item information for ID: %d"
L["FEEDBACK_ITEM_ALREADY_IN_LIST"] = "Item already in %s: %s"
L["FEEDBACK_INVALID_COMMAND"] = "Invalid command: %s"
L["FEEDBACK_ITEM_NOT_FOUND_IN_LIST_SPECIFIC"] = "Item %s not found in %s. Use 'X' button to remove items."

-- List Names for Feedback
L["SELL_LIST_NAME"] = "Sell List"
L["DESTROY_LIST_NAME"] = "Destroy List"

-- Standalone GUI
L["GUI_ITEM_LIST_MANAGEMENT_TITLE"] = "Item List Management"
