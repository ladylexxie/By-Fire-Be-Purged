local addonName, private = ...
local L = LibStub("AceLocale-3.0"):NewLocale("ByFireBePurged", "enUS", true, true)
if not L then return end

L["ADDON_NAME"] = "By Fire Be Purged"
L["SETTINGS"] = "Settings"
L["SETTINGS_GENERAL"] = "General Settings"
L["SETTINGS_ENABLE_AUTO_SELL"] = "Enable Automatic Selling"
L["SETTINGS_ENABLE_AUTO_SELL_TOOLTIP"] = "If checked, automatically sells items from your 'sell list' when you visit a merchant."
L["SETTINGS_ENABLE_ITEM_DESTRUCTION"] = "Enable Item Destruction"
L["SETTINGS_ENABLE_ITEM_DESTRUCTION_TOOLTIP"] = "If checked, enables the /bfbp destroy command to destroy items from your 'destroy list'."
L["SETTINGS_ENABLE_DEBUG_MODE"] = "Enable Debug Mode"
L["SETTINGS_ENABLE_DEBUG_MODE_TOOLTIP"] = "If checked, prints detailed operational messages to chat for troubleshooting."
L["SETTINGS_GUI_INFO_MSG"] = "List management is now handled by the standalone GUI. Type /bfbp to open it."

L["SELL_LIST"] = "Sell List"
L["DESTROY_LIST"] = "Destroy List"
L["LIST_EMPTY"] = "This list is empty."

-- General Messages
L["MSG_INITIALIZED"] = "initialized. Type /bfbp for options."
L["MSG_ENABLED"] = "enabled."
L["MSG_DISABLED"] = "disabled."

-- Slash Commands
L["SLASH_COMMANDS_HEADER"] = "Slash Commands"
L["SLASH_COMMANDS_DESCRIPTION"] = ("Use slash commands to manage your lists:\n" ..
    "/bfbp - Opens the item list management GUI.\n" ..
    "/bfbp destroy - Attempts to destroy all items in your bags that are on the destroy list."
)
L["HELP_HEADER"] = "Available commands:"
L["HELP_CONFIG_CMD"] = "/bfbp - Shows the item list management window."
L["HELP_DESTROY_CMD"] = "/bfbp destroy - Attempts to destroy all items currently in your destroy list."
L["HELP_HELP_CMD"] = "/bfbp help - Shows this help message."

-- GUI List Management
L["GUI_ITEM_LIST_MANAGEMENT_TITLE"] = "Item List Management"
L["GUI_ADD_ITEM_LABEL"] = "Item ID or drag & drop to add:"

-- Feedback Messages (many suffixed with _MSG or _FORMATTED for clarity)
L["FEEDBACK_INVALID_COMMAND_FORMATTED"] = "Invalid command: %s. Try /bfbp help or /bfbp."
L["FEEDBACK_INVALID_ITEM_FORMAT_GENERIC"] = "Invalid item format: %s. Please use item ID or item link."
L["FEEDBACK_ITEM_INFO_FAILED_GENERIC"] = "Failed to get item info for ID: %s."
L["FEEDBACK_ITEM_ALREADY_IN_LIST_FORMATTED"] = "%2$s is already in %1$s."
L["FEEDBACK_ITEM_ADDED_FORMATTED"] = "Item added to %1$s: %2$s"
L["FEEDBACK_ITEM_NOT_FOUND_IN_LIST_FORMATTED"] = "%1$s not found in %2$s."
L["FEEDBACK_ITEM_REMOVED_FORMATTED"] = "Removed %2$s from %1$s."
L["FEEDBACK_INVALID_ITEM_FORMAT_PARSE_ERROR"] = "Invalid item format: %s"
L["NOTE_REMOVE_VIA_X_BUTTON"] = "Note: Items are typically removed using the 'X' button next to them in the list."

L["FEEDBACK_ITEM_SOLD_MSG"] = "Sold %s."
L["FEEDBACK_ITEM_NOT_SELLABLE_MSG"] = "%s is not sellable or has no value."
L["FEEDBACK_TRANSACTION_COMPLETE_MSG"] = "Sold %d item(s) from the sell list."

L["FEEDBACK_API_FUNCTIONS_MISSING_FOR_DESTROY_MSG"] = "Error: Required API functions for destroying items are not available."
L["FEEDBACK_ATTEMPTING_TO_DESTROY_ITEM_MSG"] = "Attempting to destroy: %s (Bag: %d, Slot: %d)"
L["FEEDBACK_ITEM_DESTROYED_SUCCESS_MSG"] = "Destroyed: %s."
L["FEEDBACK_ITEM_PICKUP_FAILED_MSG"] = "Failed to pick up %s to cursor."
L["FEEDBACK_DESTROY_RUN_COMPLETE_MSG"] = "Destroy command: %d item(s) successfully destroyed from the list."
L["FEEDBACK_NO_ITEMS_DESTROYED_IN_RUN_MSG"] = "Destroy command: No items from the destroy list found/destroyed in this run."
L["FEEDBACK_CURSOR_CLEARED_UNEXPECTED_MSG"] = "Destroy command: Cleared unexpected item from cursor after operation."
L["FEEDBACK_ITEM_DESTRUCTION_TOGGLE_OFF_MSG"] = "Item Destruction command is currently disabled in settings."
L["FEEDBACK_DESTROY_LIST_IS_EMPTY_MSG"] = "Your destroy list is currently empty. Add items via /bfbp."

-- Debug Messages (many suffixed with _MSG for clarity)
L["DEBUG_AUTO_SELL_DISABLED_MSG"] = "Auto-sell is disabled. No items will be sold."
L["DEBUG_MERCHANT_EVENT_SELL_START_MSG"] = "MERCHANT_SHOW event: Attempting to sell items."
L["DEBUG_NO_SELLABLE_ITEMS_FOUND_MSG"] = "No items from the sell list found in bags or no items were sellable."
L["DEBUG_ITEM_DESTRUCTION_DISABLED_MSG"] = "Item Destruction feature is disabled in settings. Destruction command will not run."
L["DEBUG_DESTROY_LIST_EMPTY_MSG"] = "Destroy list is empty. Nothing to destroy."
L["DEBUG_MANUAL_DESTROY_SCAN_START_MSG"] = "Slash command: Scanning for items to destroy from the destroy list."
L["DEBUG_JUSTIFY_H_FAIL"] = "DEBUG: Could not set JustifyH for title label. Neither widget:SetJustifyH nor widget.fontstring:SetJustifyH available."

-- Error Messages (many specific to GUI creation/operation)
L["ERROR_GUI_FRAME_CREATE"] = "Error: Main GUI Frame could not be created."
L["ERROR_COLUMN_CONTAINER_CREATE"] = "Error creating columnContainer (SimpleGroup) for GUI."
L["ERROR_SELL_COLUMN_CREATE"] = "Error creating sellColumnGroup."
L["ERROR_DESTROY_COLUMN_CREATE"] = "Error creating destroyColumnGroup."
L["ERROR_ADD_BOX_CREATE"] = "Error creating AddBox for %s"
L["ERROR_SCROLL_FRAME_CREATE"] = "Error creating ScrollFrame for %s"
L["ERROR_GUI_FRAME_INIT_FAIL"] = "Error: GUI Frame could not be initialized."
L["MSG_SELL_LIST_SCROLL_REFRESH_FAIL"] = "Sell list scroll container not found for refresh."
L["MSG_DESTROY_LIST_SCROLL_REFRESH_FAIL"] = "Destroy list scroll container NOT FOUND for refresh."
L["ERROR_SCROLL_CONTAINER_REFRESH_FAIL"] = "Error: Attempted to refresh a nil scroll container for %s"
L["ERROR_ITEM_LABEL_CREATE"] = "Error creating itemLabel for %s in %s"
L["ERROR_REMOVE_BUTTON_CREATE"] = "Error creating removeButton for %s in %s"
L["ERROR_ITEM_ENTRY_GROUP_CREATE"] = "Error creating itemEntryGroup for %s in %s"
L["ERROR_EMPTY_LABEL_CREATE"] = "Error creating emptyLabel for %s"

-- List Names for Feedback (These might be used by the GUI directly or formatted strings above)
L["SELL_LIST_NAME"] = "Sell List"
L["DESTROY_LIST_NAME"] = "Destroy List"
