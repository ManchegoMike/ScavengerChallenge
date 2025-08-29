local ADDONNAME, ns = ...
if not ns then
    _G[ADDONNAME] = _G[ADDONNAME] or {}
    ns = _G[ADDONNAME]
end

-- Localization table with enUS fallback (same pattern as Ironman)
local L = {}
ns.L = L
ns.enUS = {}
local locale = GetLocale() or "enUS"

setmetatable(L, {
    __index = function(t, k)
        local lt = ns[locale]
        if lt and lt[k] then
            rawset(t, k, lt[k]); return lt[k]
        elseif ns.enUS[k] then
            -- print("Fallback to enUS for key:", k)
            rawset(t, k, ns.enUS[k]); return ns.enUS[k]
        else
            -- print("Missing translation for key:", k)
            rawset(t, k, k); return k
        end
    end
})

-- IMPORTANT: We do NOT hardcode "You receive item" here.
-- We will use the global LOOT_ITEM_SELF pattern at runtime for localization-safe parsing.

ns["enUS"] = {
    title = "THE SCAVENGER CHALLENGE",
    prefix = "SCAVENGER: ",
    description = "Hardcore, self-found: cannot equip quest rewards; cannot buy from merchants except reagents and gathering tools.",

    help_header = "Commands:",
    help_allow  = "/scav allow {id/name/link}",
    help_allow_desc = "Allow an item you specify (by ID, name, or link).",
    help_disallow  = "/scav disallow {id/name/link}",
    help_disallow_desc = "Disallow an item you specify (by ID, name, or link).",

    init_tip = function(cmd) return "Initialized: type " .. cmd .. " for more info" end,
    all_ok = "All equipped items are OK",
    unequip_quest_item_s = function(link) return "Unequip quest item: " .. link end,
    unequip_n_quest_items = function(n) return "Unequip " .. n .. " quest items" end,

    item_not_found_s = function(s) return "Item not found: " .. s end,
    bad_item_link_s = function(s) return "Unable to parse item link: " .. s end,
    now_allowed_s_i = function(link, id) return link .. " (" .. id .. ") now allowed" end,
    now_disallowed_s_i = function(link, id) return link .. " (" .. id .. ") now disallowed" end,

    cannot_equip_s = function(link) return link .. " cannot be equipped" end,
}

