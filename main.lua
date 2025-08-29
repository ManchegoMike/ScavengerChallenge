local ADDONNAME, ns = ...
if not ns then
    _G[ADDONNAME] = _G[ADDONNAME] or {}
    ns = _G[ADDONNAME]
end

local L = ns.L
local adapter = ns.adapter

-- Frame/State ---------------------------------------------------------------
local scav = CreateFrame('Frame', ADDONNAME .. "_Frame")
local _initialized = false
local _merchantPage = nil         -- current page (Wrath/Classic UI); nil when not at merchant
local _targetingQuestNpc = false  -- toggled by quest events

-- Constants ----------------------------------------------------------------
local ERROR_SOUND_FILE = "Interface\\AddOns\\" .. ADDONNAME .. "\\Sounds\\ding.wav"

-- Slash Commands ------------------------------------------------------------
SLASH_SCAVENGERCHALLENGE1, SLASH_SCAVENGERCHALLENGE2 = '/scavenger', '/scav'
SlashCmdList["SCAVENGERCHALLENGE"] = function(str)
    ns.parseCommand(str)
end

-- SavedVariables init -------------------------------------------------------
function ns.initDB(force)
    if force or not ScavengerUserData then
        ScavengerUserData = {
            AllowedItems = {},
            ForbiddenItems = {},
        }
    end
end

-- Utility UI text -----------------------------------------------------------
local function colorText(hex6, text) return "|cFF" .. hex6 .. text .. "|r" end
local function info(text)    print(colorText('c0c0c0', L.prefix) .. colorText('ffffff', text)) end
local function fail(text)    print(colorText('ff0000', L.prefix) .. colorText('ffffff', text)) end
local function success(text) print(colorText('0080ff', L.prefix) .. colorText('00ff00', text)) end
local function flash(text)   UIErrorsFrame:AddMessage(text, 1.0, 0.5, 0.0, GetChatTypeIndex('SYSTEM'), 8) end

-- Sound wrapper -------------------------------------------------------------
local function playError()
    if _initialized then adapter:playSound(ERROR_SOUND_FILE) end
end

-- Localization-safe loot pattern -------------------------------------------
-- Build a pattern from LOOT_ITEM_SELF (e.g., "You receive item: %s.")
local function buildLootSelfPattern()
    local gl = LOOT_ITEM_SELF or "You receive item: %s."
    -- Escape magic chars, then replace "%s" with "(.*)"
    gl = gl:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])","%%%1")
    gl = gl:gsub("%%%%s","(.*)")
    return "^" .. gl .. "$"
end
local LOOT_SELF_PATTERN = buildLootSelfPattern()

-- Core init -----------------------------------------------------------------
function ns.init()
    ns.initDB()

    -- Seed initial allow/disallow like your original addon
    if ScavengerUserData.AllowedItems == nil or next(ScavengerUserData.AllowedItems) == nil then
        ScavengerUserData.AllowedItems = {}
        for _,id in ipairs({1262,1939,1941,1942,2901,4471,6256,6529,6530,6532,7005}) do
            ScavengerUserData.AllowedItems[id] = 1
        end
    end
    if ScavengerUserData.ForbiddenItems == nil or next(ScavengerUserData.ForbiddenItems) == nil then
        ScavengerUserData.ForbiddenItems = {}
        for _,id in ipairs({11291}) do
            ScavengerUserData.ForbiddenItems[id] = 1
        end
    end

    adapter:after(2.0, function()
        _initialized = true
        success(L.init_tip(colorText('ffd000', '/scav')))
        ns.checkInventory()
    end)
end

-- Command parsing -----------------------------------------------------------
function ns.parseCommand(str)
    local _, _, arg1 = str:find("^allow +(.*)$")
    if arg1 then ns.allowOrDisallowItem(arg1, true, true); return end

    _, _, arg1 = str:find("^disallow +(.*)$")
    if arg1 then ns.allowOrDisallowItem(arg1, false, true); return end

    print(' ')
    print(colorText('ff8000', L.title))
    print(L.description)
    print(' ')
    print(colorText('ffff00', L.help_allow));       print("   " .. L.help_allow_desc)
    print(colorText('ffff00', L.help_disallow));    print("   " .. L.help_disallow_desc)
    print(' ')
end

-- Item helpers --------------------------------------------------------------
function ns.allowOrDisallowItem(itemStr, allow, userCommand)
    local name, link = GetItemInfo(itemStr)
    if not name then
        fail(L.item_not_found_s(itemStr))
        return false
    end
    local itemId, text = adapter:parseItemLink(link)
    if not itemId or not text then
        fail(L.bad_item_link_s('"' .. tostring(link) .. '"'))
        return false
    end

    if allow then
        ScavengerUserData.AllowedItems[itemId] = 1
        ScavengerUserData.ForbiddenItems[itemId] = nil
        if userCommand then info(L.now_allowed_s_i(link, itemId)) end
    else
        ScavengerUserData.AllowedItems[itemId] = nil
        ScavengerUserData.ForbiddenItems[itemId] = 1
        if userCommand then info(L.now_disallowed_s_i(link, itemId)) end
    end
    return true
end

-- Inventory checks ----------------------------------------------------------
function ns.inventoryWarnings()
    local msgs = {}
    for slot = 1, 18 do
        local itemId = GetInventoryItemID('player', slot)
        if itemId and ScavengerUserData.ForbiddenItems[itemId] then
            local name, link = GetItemInfo(itemId)
            msgs[#msgs+1] = L.unequip_quest_item_s(link or ("item "..itemId))
        end
    end
    return msgs
end

function ns.checkInventory()
    local msgs = ns.inventoryWarnings()
    if #msgs == 0 then
        success(L.all_ok)
    else
        for _, msg in ipairs(msgs) do fail(msg) end
        if #msgs == 1 then flash(msgs[1]) else flash(L.unequip_n_quest_items(#msgs)) end
        playError()
    end
end

-- Merchant filtering (Wrath/Classic UI only) --------------------------------
local function hideOrShowMerchantItems(pageNumber)
    -- Only attempt on classic-style Merchant UI (Retail’s new UI may not use these frames)
    if not pageNumber or not MERCHANT_ITEMS_PER_PAGE or not MerchantFrame then return end

    if pageNumber > 0 then
        for i = 1, MERCHANT_ITEMS_PER_PAGE do
            local btn = _G["MerchantItem" .. i]
            if btn then btn:Hide() end
        end
        adapter:after(0.3, function()
            for i = 1, MERCHANT_ITEMS_PER_PAGE do
                local idx = (pageNumber - 1) * MERCHANT_ITEMS_PER_PAGE + i
                local link = GetMerchantItemLink(idx)
                local btn  = _G["MerchantItem" .. i]
                if btn and link then
                    local id = adapter:parseItemLink(link)
                    local allow = id and ( (not ScavengerUserData.ForbiddenItems[id]) and
                                           (ScavengerUserData.AllowedItems[id] or adapter:itemIsReagent(id)) )
                    if allow then btn:Show() end
                end
            end
        end)
    else
        for i = 1, 12 do
            local btn = _G["MerchantItem" .. i]
            if btn then btn:Show() end
        end
    end
end

-- Event wiring --------------------------------------------------------------
scav:SetScript('OnUpdate', function(self, elapsed)
    if _merchantPage then
        local page = (MerchantFrame and MerchantFrame.selectedTab == 1) and (MerchantFrame.page or -1) or -1
        if page ~= _merchantPage then
            _merchantPage = page
            hideOrShowMerchantItems(page)
        end
    end
end)

scav:RegisterEvent("PLAYER_LOGIN")
scav:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
scav:RegisterEvent("MERCHANT_SHOW")
scav:RegisterEvent("MERCHANT_CLOSED")
scav:RegisterEvent("QUEST_ACCEPTED")
scav:RegisterEvent("QUEST_TURNED_IN")
scav:RegisterEvent("QUEST_DETAIL")
scav:RegisterEvent("QUEST_PROGRESS")
scav:RegisterEvent("QUEST_COMPLETE")
scav:RegisterEvent("PLAYER_TARGET_CHANGED")
scav:RegisterEvent("CHAT_MSG_LOOT")

scav:SetScript("OnEvent", function(self, event, ...)
    if event == 'PLAYER_LOGIN' then
        ns.init()

    elseif event == 'PLAYER_EQUIPMENT_CHANGED' then
        adapter:after(0.3, ns.checkInventory)

    elseif event == 'MERCHANT_SHOW' then
        _merchantPage = 0

    elseif event == 'MERCHANT_CLOSED' then
        _merchantPage = nil

    elseif event == 'QUEST_ACCEPTED' or event == 'QUEST_TURNED_IN' or
           event == 'QUEST_COMPLETE' or event == 'QUEST_DETAIL' or
           event == 'QUEST_PROGRESS' then
        _targetingQuestNpc = true

    elseif event == 'PLAYER_TARGET_CHANGED' then
        -- This fires before MERCHANT_xxx or QUEST_xxx.
        _targetingQuestNpc = false

    elseif event == 'CHAT_MSG_LOOT' then
        local msg = ...
        local isQuestContext = _targetingQuestNpc
        adapter:after(0.3, function()
            -- Match localized "You receive item: %s." using LOOT_ITEM_SELF.
            local _, _, link = string.find(msg or "", LOOT_SELF_PATTERN)
            if link then
                if isQuestContext then
                    local itemId = adapter:parseItemLink(link)
                    if itemId then
                        ScavengerUserData.ForbiddenItems[itemId] = 1
                        _targetingQuestNpc = false
                        fail(L.cannot_equip_s(link))
                        flash(L.cannot_equip_s(link))
                        playError()
                    end
                end
            end
        end)
    end
end)
