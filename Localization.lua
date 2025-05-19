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
