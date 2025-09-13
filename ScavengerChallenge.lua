local ADDONNAME, ns = ...
if not ns then
    _G[ADDONNAME] = _G[ADDONNAME] or {}
    ns = _G[ADDONNAME]
end

local L = ns.L
local adapter = ns.adapter

local dbg = true -- This should only be true if debugging.
local function printnothing() end
local pdb = dbg and print or printnothing

-- Frame/State -----------------------------------------------------------------

local _initialized = false
local _allowMail = false
local _allowTrade = false
local _currentMerchantPage = nil    -- Current page (Wrath/Classic UI); nil when not at merchant; -1 for buyback page
local _targetingQuestNpc = false    -- Toggled by quest events
local _itemsInBags = {}             -- A table of all items in bags; when player gets a new item, this is checked to figure out which item is new
local _hearthTicker

-- Constants -------------------------------------------------------------------

local ERROR_SOUND_FILE = SOUNDKIT.ALARM_CLOCK_WARNING_3
local HEARTHSTONE_ID = 6948
local HEARTH_SPELL_ID = 8690

-- Slash Commands --------------------------------------------------------------

SLASH_SCAVENGERCHALLENGE1, SLASH_SCAVENGERCHALLENGE2 = '/scavenger', '/scav'
SlashCmdList["SCAVENGERCHALLENGE"] = function(str)
    ns.parseCommand(str)
end

-- SavedVariables init ---------------------------------------------------------

function ns.initDB(force)
    if force or ScavengerUserData == nil then ScavengerUserData = {} end
    if ScavengerUserData.ForbiddenItems == nil then ScavengerUserData.ForbiddenItems = {} end
    if ScavengerUserData.AllowedItems == nil then ScavengerUserData.AllowedItems = {} end
    if ScavengerUserData.AllowHearth == nil then ScavengerUserData.AllowHearth = false end
    if ScavengerUserData.AllowBank == nil then ScavengerUserData.AllowBank = false end
end

-- Sound wrapper ---------------------------------------------------------------

local function playError()
    if _initialized then adapter:playSound(ERROR_SOUND_FILE) end
end

-- Utility UI text -------------------------------------------------------------

local function colorText(hex6, s)   return "|cFF" .. hex6 .. s .. "|r" end
local function info(s)              print(colorText('c0c0c0', L.prefix) .. colorText('ffffff', s)) end
local function fail(s)              print(colorText('ff0000', L.prefix) .. colorText('ffffff', s)) end
local function success(s)           print(colorText('0080ff', L.prefix) .. colorText('00ff00', s)) end
local function flash(s,sound)       UIErrorsFrame:AddMessage(s, 1.0, 0.5, 0.0, GetChatTypeIndex('SYSTEM'), 8); if sound ~= false then playError() end end

-- Command parsing -------------------------------------------------------------

function ns.parseCommand(str)
    local _, _, arg1 = str:find("^allow +(.*)$")
    if arg1 then ns.allowOrDisallowItem(arg1, true, true); return end

    _, _, arg1 = str:find("^disallow +(.*)$")
    if arg1 then ns.allowOrDisallowItem(arg1, false, true); return end

    local function setHearth(tf)
        if tf == nil then
            ScavengerUserData.AllowHearth = not ScavengerUserData.AllowHearth
        else
            ScavengerUserData.AllowHearth = tf
        end
        if ScavengerUserData.AllowHearth then
            success(L.hearth_on)
        else
            success(L.hearth_off)
            ns.checkBags()
        end
    end

    p1, p2, match = str:find("^hearth *(%a*)$")
    if p1 then
        match = match:lower()
        if match == 'on' then
            setHearth(true)
        elseif match == 'off' then
            setHearth(false)
        else
            setHearth(nil)
        end
        return
    end

    local function setBank(tf)
        if tf == nil then
            ScavengerUserData.AllowBank = not ScavengerUserData.AllowBank
        else
            ScavengerUserData.AllowBank = tf
        end
        if ScavengerUserData.AllowBank then
            success(L.bank_on)
        else
            success(L.bank_off)
        end
    end

    p1, p2, match = str:find("^bank *(%a*)$")
    if p1 then
        match = match:lower()
        if match == 'on' then
            setBank(true)
        elseif match == 'off' then
            setBank(false)
        else
            setBank(nil)
        end
        return
    end

    p1, p2, match = str:find("^mail$")
    if p1 then
        if _allowMail then
            fail(L.mail_already_activated)
        else
            _allowMail = true
            success(L.mail_activated)
            C_Timer.After(60, function()
                _allowMail = false
                success(L.mail_deactivated)
            end)
        end
        return
    end

    p1, p2, match = str:find("^trade$")
    if p1 then
        if _allowTrade then
            fail(L.trade_already_activated)
        else
            _allowTrade = true
            success(L.trade_activated)
            C_Timer.After(60, function()
                _allowTrade = false
                success(L.trade_deactivated)
            end)
        end
        return
    end

    local function currentlyOnOrOff(tf)
        return " (" .. (tf and L.currently_on or L.currently_off) .. ")"
    end

    print(' ')
    success(L.init_desc(ScavengerUserData.AllowHearth, ScavengerUserData.AllowBank))
    print(' ')
    print(colorText('ffff00', "/scav hearth")                                   .. " — " .. L.hearth_help .. currentlyOnOrOff(ScavengerUserData.AllowHearth))
    print(colorText('ffff00', "/scav bank")                                     .. " — " .. L.bank_help .. currentlyOnOrOff(ScavengerUserData.AllowBank))
    print(colorText('ffff00', "/scav mail")                                     .. " — " .. L.mail_help)
    print(colorText('ffff00', "/scav trade")                                    .. " — " .. L.trade_help)
    print(colorText('ffff00', "/scav allow {" .. L.id_name_link .. "}")         .. " — " .. L.allow_help)
    print(colorText('ffff00', "/scav disallow {" .. L.id_name_link .. "}")      .. " — " .. L.disallow_help)
    print(' ')
end

-- Item helpers ----------------------------------------------------------------

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

-- Equipped item checks --------------------------------------------------------

function ns.equippedItemsWarnings()
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

function ns.checkEquippedItems(showMessageIfAllOk)
    local msgs = ns.equippedItemsWarnings()
    if #msgs == 0 then
        if showMessageIfAllOk then success(L.all_equipped_ok) end
    else
        for _, msg in ipairs(msgs) do fail(msg) end
        if #msgs == 1 then flash(msgs[1]) else flash(L.unequip_n_quest_items(#msgs)) end
        playError()
    end
end

function ns.initItemsInBags()                                                                       --pdb("initItemsInBags")
    _itemsInBags = {}
    for bag = 0, NUM_BAG_SLOTS do
        local slots = adapter:getContainerNumSlots(bag)
        for slot = 1, slots do
            local id = adapter:getContainerItemId(bag, slot)
            if id then
                _itemsInBags[id] = 1                                                                --pdb(adapter:getContainerItemLink(bag, slot))
            end
        end
    end                                                                                             --pdb(" ")
end

function ns.checkBags()
    _itemsInBags = {}
    for bag = 0, NUM_BAG_SLOTS do
        local slots = adapter:getContainerNumSlots(bag)
        for slot = 1, slots do
            local id = adapter:getContainerItemId(bag, slot)
            if id and id == HEARTHSTONE_ID then
                fail(L.hearth_disallowed)
                flash(L.hearth_disallowed)
            end
        end
    end
end

-- Merchant filtering (Wrath/Classic UI only) ----------------------------------

local function showMerchantItem(id)
    return ScavengerUserData.AllowedItems[id]
end

local function hideOrShowMerchantItems(pageNumber)
    -- Only attempt on classic-style Merchant UI (Retail’s new UI may not use these frames)
    if not pageNumber or not MERCHANT_ITEMS_PER_PAGE or not MerchantFrame then return end

    if pageNumber > 0 then
        -- Hide all buttons
        for i = 1, MERCHANT_ITEMS_PER_PAGE do
            local btn = _G["MerchantItem" .. i]
            if btn then btn:Hide() end
        end
        -- Show buttons for allowed items
        C_Timer.After(0.05, function()
            for i = 1, MERCHANT_ITEMS_PER_PAGE do
                local index = (pageNumber - 1) * MERCHANT_ITEMS_PER_PAGE + i
                local link = GetMerchantItemLink(index)
                local btn = _G["MerchantItem" .. i]
                if btn and link then
                    local id = adapter:parseItemLink(link)
                    if showMerchantItem(id) then
                        btn:Show()
                    end
                end
            end
        end)
    else -- pageNumber <= 0 means the buyback tab
         -- Show all buttons
        for i = 1, 12 do
            local btn = _G["MerchantItem" .. i]
            if btn then btn:Show() end
        end
    end
end

-- Event wiring ----------------------------------------------------------------

local eventFrame = CreateFrame('Frame', ADDONNAME .. "_Events")

eventFrame:SetScript('OnUpdate', function(self, elapsed)
    if _currentMerchantPage then
        local page = (MerchantFrame and MerchantFrame.selectedTab == 1) and (MerchantFrame.page or -1) or -1
        if page ~= _currentMerchantPage then                                                        --pdb('PAGE', page)
            _currentMerchantPage = page
            hideOrShowMerchantItems(page)
        end
    end
end)

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:RegisterEvent("MERCHANT_CLOSED")
eventFrame:RegisterEvent("QUEST_ACCEPTED")
eventFrame:RegisterEvent("QUEST_TURNED_IN")
eventFrame:RegisterEvent("QUEST_DETAIL")
eventFrame:RegisterEvent("QUEST_PROGRESS")
eventFrame:RegisterEvent("QUEST_COMPLETE")
eventFrame:RegisterEvent("QUEST_FINISHED")
eventFrame:RegisterEvent("CHAT_MSG_LOOT")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("BANKFRAME_OPENED")
eventFrame:RegisterEvent("MAIL_SHOW")
eventFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
eventFrame:RegisterEvent("TRADE_SHOW")
eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
eventFrame:RegisterEvent("UNIT_SPELLCAST_STOP")
eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")

eventFrame:SetScript("OnEvent", function(self, event, ...)

    if event == 'PLAYER_LOGIN' then

        ns.initDB()

        if ScavengerUserData.AllowedItems == nil or next(ScavengerUserData.AllowedItems) == nil then
            ScavengerUserData.AllowedItems = {}
            -- Allow fishing pole (6256) & mounts
            -- Sadly we can't query the WoW API about mounts. They return class 15 subclass 0, which is "junk", so we have to check for them all individually.
            for _,id in ipairs({6256,1132,2414,5655,5656,5665,5668,5864,5872,5873,8563,8588,8591,8592,8595,8629,8631,8632,13321,13322,13331,13332,13333,15277,15290,211498,211499,213170,216492,216570}) do
                ScavengerUserData.AllowedItems[id] = 1
            end
        end
        if ScavengerUserData.ForbiddenItems == nil or next(ScavengerUserData.ForbiddenItems) == nil then
            ScavengerUserData.ForbiddenItems = {}
        end

        C_Timer.After(2.0, function()
            _initialized = true
            success(L.init_desc(ScavengerUserData.AllowHearth, ScavengerUserData.AllowBank))
            success(L.init_tip(colorText('ffd000', '/scav')))
            ns.initItemsInBags()
            ns.checkEquippedItems(true)
            ns.checkBags()
        end)

    elseif event == 'PLAYER_EQUIPMENT_CHANGED' then

        C_Timer.After(0.3, ns.checkEquippedItems)

    elseif event == 'PLAYER_TARGET_CHANGED' then -- This fires before MERCHANT_xxx or QUEST_xxx.

        _targetingQuestNpc = false

    elseif event == 'PLAYER_REGEN_DISABLED' then -- Player is entering combat

        C_Timer.After(0.3, function()
            ns.checkEquippedItems()
        end)

    elseif event == 'BANKFRAME_OPENED' then

        if not ScavengerUserData.AllowBank then
            CloseBankFrame()
            fail(L.bank_disallowed)
            flash(L.bank_disallowed)
        end

    elseif event == 'MAIL_SHOW' then

        if not _allowMail then
            CloseMail()
            fail(L.mail_disallowed)
            flash(L.mail_disallowed)
        end

    elseif event == 'TRADE_SHOW' then

        if not _allowTrade then
            CancelTrade()
            fail(L.trade_disallowed)
            flash(L.trade_disallowed)
        end

    elseif event == 'AUCTION_HOUSE_SHOW' then

        CloseAuctionHouse()
        fail(L.auction_disallowed)
        flash(L.auction_disallowed)

    elseif event == 'MERCHANT_SHOW' then

        _currentMerchantPage = 0

    elseif event == 'MERCHANT_CLOSED' then

        _currentMerchantPage = nil

    elseif event == 'UNIT_SPELLCAST_START' then

        local unit, _, spellId = ...
        if unit == "player" and spellId == HEARTH_SPELL_ID then

            adapter:playSound(SOUNDKIT.RAID_WARNING)
            flash(L.hearth_disallowed, false)
            fail(L.hearth_disallowed)

            if _hearthTicker then _hearthTicker:Cancel() end

            -- Ring a warning bell every second during the hearth cast.
            local count = 0
            _hearthTicker = C_Timer.NewTicker(1, function()
                count = count + 1
                adapter:playSound(SOUNDKIT.RAID_WARNING)
                flash(L.hearth_disallowed, false)
                if count >= 10 then
                    _hearthTicker:Cancel()
                    _hearthTicker = nil
                end
            end)

        end

    elseif event == 'UNIT_SPELLCAST_STOP' or
           event == 'UNIT_SPELLCAST_INTERRUPTED' then

        if _hearthTicker then
            _hearthTicker:Cancel()
            _hearthTicker = nil
        end

    elseif event == 'QUEST_ACCEPTED' or
           event == 'QUEST_COMPLETE' or
           event == 'QUEST_DETAIL' or
           event == 'QUEST_TURNED_IN' or
           event == 'QUEST_PROGRESS' then

            _targetingQuestNpc = true

    elseif event == 'CHAT_MSG_LOOT' or
           event == 'BAG_UPDATE_DELAYED' or
           event == 'QUEST_FINISHED' then                                                           --pdb(event)

        -- QUEST_FINISHED is the only event that works for Project Epoch in
        -- terms of catching when the player has received a quest item.
        -- Strangely, when you get a quest item, not only does it *not* say
        -- "You receive item: ____" (it says "Received item: ___", which is
        -- non-standard), but it also doesn't fire any other QUEST_ event,
        -- nor CHAT_MSG_LOOT or BAG_UPDATE_DELAYED. I mean, it's adding an item
        -- to the bags: how does it not fire the event? Since there's no way
        -- to parse which item came in, we have to remember everything that's
        -- in the bags, then compare it to what's there now, and do processing
        -- on every newly found item. Like a lot of things in programming,
        -- being forced to do it this way by a wacky API actually makes the
        -- code better in the long run, since we're no longer doing backflips
        -- to parse "You receive item: ____" in various languages.

        if _initialized then
            if event == 'QUEST_FINISHED' then _targetingQuestNpc = true end
            local msg = ...
            local isQuestContext = _targetingQuestNpc
            C_Timer.After(0.3, function()
                -- Look in bags for any item we haven't seen before in this session.
                for bag = 0, NUM_BAG_SLOTS do
                    local slots = adapter:getContainerNumSlots(bag)
                    for slot = 1, slots do
                        local id = adapter:getContainerItemId(bag, slot)
                        if id and not _itemsInBags[id] then
                            -- This is an item we haven't seen before in the bags.
                            _itemsInBags[id] = 1                                                    --pdb("isQuestContext")
                            if isQuestContext then
                                -- Here we check if the item is a quest item,
                                -- which means it's something required for the
                                -- quest, and is not a quest reward. If it isn't
                                -- a quest item, it's a (forbidden) reward.
                                local link = adapter:getContainerItemLink(bag, slot)                --pdb("new item=", link, id)
                                local isQuestItem = adapter:getContainerItemQuestInfo(bag, slot)    --pdb("isQuestItem=", isQuestItem)
                                if not isQuestItem then
                                    ScavengerUserData.ForbiddenItems[id] = 1
                                    _targetingQuestNpc = false
                                    fail(L.cannot_equip_s(link))
                                    flash(L.cannot_equip_s(link))
                                    playError()
                                end
                            end
                        end
                    end
                end
                ns.checkBags()
            end)
        end

    end

end)
