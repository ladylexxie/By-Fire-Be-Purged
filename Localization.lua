local addonName, private = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true)
if not L then return end

L["BY_FIRE_BE_PURGED"] = "By Fire Be Purged"
L["Settings"] = "Settings"
L["General Settings"] = "General Settings"
L["Enable Automatic Selling"] = "Enable Automatic Selling"
L["Enable Automatic Selling_Tooltip"] = "If checked, automatically sells items from your 'sell list' when you visit a merchant."
L["Enable Debug Mode"] = "Enable Debug Mode"
L["Enable Debug Mode_Tooltip"] = "If checked, prints detailed operational messages to chat for troubleshooting."
L["Managed Item Lists"] = "Managed Item Lists"
L["Sell List"] = "Sell List"
L["Destroy List"] = "Destroy List"
L["Items in Sell List:"] = "Items in Sell List:"
L["Items in Destroy List:"] = "Items in Destroy List:"
L["List is empty."] = "List is empty."
L["Slash Commands:"] = "Slash Commands:"
L["Slash Command Description"] = ("Use slash commands to manage your lists:\n" ..
    "/bfbp add <sell|destroy> <itemLink|itemID>\n" ..
    "/bfbp list <sell|destroy|all>\n" ..
    "/bfbp remove <sell|destroy> <itemLink|itemID>\n" ..
    "/bfbp destroyitems (to destroy items on list)\n" ..
    "/bfbp help (for all commands)")

-- GUI List Management
L["Add Item ID or Link:"] = "Add Item ID or Link:"
L["Add Item"] = "Add Item"
L["Remove Item ID or Link:"] = "Remove Item ID or Link:"
L["Remove Item"] = "Remove Item"

-- Feedback Messages
L["Item added to %s: %s"] = "Item added to %s: %s"
L["Item removed from %s: %s"] = "Item removed from %s: %s"
L["Item not found in %s: %s"] = "Item not found in %s: %s"
L["Invalid item format: %s"] = "Invalid item format: %s"
L["Could not retrieve item information for ID: %d"] = "Could not retrieve item information for ID: %d"
L["Item already in %s: %s"] = "Item already in %s: %s"

-- List Names for Feedback
L["Sell List Name"] = "Sell List"
L["Destroy List Name"] = "Destroy List"

-- Standalone GUI
L["Item List Management"] = "Item List Management"
