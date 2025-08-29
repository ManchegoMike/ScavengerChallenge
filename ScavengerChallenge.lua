local ADDONNAME, S = ...

local dbg = true -- This should only be true if debugging.
local function printnothing() end
local pdb = dbg and print or printnothing

-- Constants
local PREFIX = "SCAVENGER: "
local ERROR_SOUND_FILE = "Interface\\AddOns\\" .. ADDONNAME .. "\\Sounds\\ding.wav"
local PLAYER_GUID = UnitGUID('player')

-- Localization (i18n) strings. The string after each '=' sign will need to be changed if not US English.
local L = {
    ["You receive item"] = "You receive item",  -- The message you get when you get a quest reward or buy something from a merchant.
}

local scavenger = CreateFrame('frame', ADDONNAME)

SLASH_SCAVENGERCHALLENGE1, SLASH_SCAVENGERCHALLENGE2 = '/scavenger', '/scav'
SlashCmdList["SCAVENGERCHALLENGE"] = function(str)
    scavenger:parseCommand(str)
end

-- Internal states
local _initialized = false              -- Is the addon active and initialized?
local _merchantPage = nil               -- The current merchant page being viewed. Nil if not at a merchant. Set in OnUpdate function.
local _targetingQuestNpc = false        -- Is the player currently targeting a quest giver?

scavenger:SetScript('OnUpdate', function(self, elapsed)
    if _merchantPage then
        local page = (MerchantFrame.selectedTab == 1) and MerchantFrame.page or -1
        if page ~= _merchantPage then
            _merchantPage = page                                                --pdb("page: ", page)
            self:hideOrShowMerchantItems(page)
        end
    end
end)

scavenger:RegisterEvent("PLAYER_LOGIN")
scavenger:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
scavenger:RegisterEvent("MERCHANT_SHOW")
scavenger:RegisterEvent("MERCHANT_CLOSED")
scavenger:RegisterEvent("QUEST_ACCEPTED")
scavenger:RegisterEvent("QUEST_TURNED_IN")
scavenger:RegisterEvent("QUEST_DETAIL")
scavenger:RegisterEvent("QUEST_PROGRESS")
scavenger:RegisterEvent("QUEST_COMPLETE")
scavenger:RegisterEvent("PLAYER_TARGET_CHANGED")
scavenger:RegisterEvent("CHAT_MSG_LOOT")

scavenger:SetScript("OnEvent", function(self, event, ...)
    local arg = {...}

    if event == 'PLAYER_LOGIN' then

        scavenger:init()

    elseif event == 'PLAYER_EQUIPMENT_CHANGED' then                             --pdb('PLAYER_EQUIPMENT_CHANGED')

        C_Timer.After(0.3, function()
            self:checkInventory()
        end)

    elseif event == 'MERCHANT_SHOW' then

        -- Start the OnUpdate code
        _merchantPage = 0

    elseif event == 'MERCHANT_CLOSED' then

        -- Stop the OnUpdate code
        _merchantPage = nil

    elseif event == 'QUEST_ACCEPTED'
        or event == 'QUEST_TURNED_IN'
        or event == 'QUEST_COMPLETE'
        or event == 'QUEST_DETAIL'
        or event == 'QUEST_PROGRESS' then                                       --pdb('QUEST_xxx')

        _targetingQuestNpc = true

    elseif event == 'PLAYER_TARGET_CHANGED' then                                --pdb('PLAYER_TARGET_CHANGED')

        -- This event always seems to happen before MERCHANT_xxx or QUEST_xxx.
        _targetingQuestNpc = false

    elseif event == 'CHAT_MSG_LOOT' then                                        --pdb('CHAT_MSG_LOOT: ', arg[1])

        local isQuest = _targetingQuestNpc
        C_Timer.After(0.3, function()
            local _,_,link = arg[1]:find(L['You receive item'] .. ": (.*)%.")
            if link then
                if isQuest then
                    local itemId, itemText = self:parseItemLink(link)
                    if itemId then
                        ScavengerUserData.ForbiddenItems[itemId] = 1            --pdb("FORBIDDEN")
                        _targetingQuestNpc = false
                        self:fail(link .. " cannot be equipped")
                    end
                end
            else                                                                --pdb("not a match")
            end
        end)

    end
end)

function scavenger:init()
    self:initDB()
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
    C_Timer.After(2.0, function()
        _initialized = true
        self:success("Initialized: type " .. self:colorText('ffd000', '/scav') .. " for more info")
        self:checkInventory()
    end)
end

function scavenger:initDB(force)
    if force or not ScavengerUserData then
        ScavengerUserData = {
            AllowedItems = {},
            ForbiddenItems = {},
        }
    end
end

function scavenger:playSound(path)
    if not _initialized then return end
    PlaySoundFile(path, "Master")
end

function scavenger:parseCommand(str)
    local p1, p2, arg
    local override = true

    p1, p2, arg1 = str:find("^allow +(.*)$")
    if arg1 then
        self:allowOrDisallowItem(arg1, true, override)
        return
    end

    p1, p2, arg1 = str:find("^disallow +(.*)$")
    if arg1 then
        self:allowOrDisallowItem(arg1, false, override)
        return
    end

    print(' ')
    print(self:colorText('ff8000', "THE SCAVENGER CHALLENGE"))
    print("Hardcore, self-found, cannot use or equip quest reward items, cannot buy anything from merchants except spell reagents and gathering tools")
    print(' ')
    print(self:colorText('ffff00', "/scav allow {id/name/link}"))
    print("   Allows you to use the item you specify, either by id# or name or link.")
    print("   Example:  \"/scav allow 121\",  \"/scav allow Thug Boots\"")
    print(self:colorText('ffff00', "/scav disallow {id/name/link}"))
    print("   Disallows the item you specify, either by id# or name or link.")
    print("   Example:  \"/scav disallow 121\",  \"/scav disallow Thug Boots\"")
    print(' ')

end

function scavenger:colorText(hex6, text)
    return "|cFF" .. hex6 .. text .. "|r"
end

function scavenger:info(text)
    print(self:colorText('c0c0c0', PREFIX) .. self:colorText('ffffff', text))
end

function scavenger:fail(text)
    print(self:colorText('ff0000', PREFIX) .. self:colorText('ffffff', text))
end

function scavenger:success(text)
    print(self:colorText('0080ff', PREFIX) .. self:colorText('00ff00', text))
end

function scavenger:flash(text)
    UIErrorsFrame:AddMessage(text, 1.0, 0.5, 0.0, GetChatTypeIndex('SYSTEM'), 8);
end

function scavenger:parseItemLink(link)
    if not link then return nil end
    -- |cff9d9d9d|Hitem:3299::::::::20:257::::::|h[Fractured Canine]|h|r
    local _, _, id, text = link:find(".*|.*|Hitem:(%d+):.*|h%[(.*)%]|h|r")
    return tonumber(id), text
end

function scavenger:itemIsReagent(id)
    if not id then return false end
    local _, _, _, _, _, _, _, _, _, _, _, itemClassId, itemSubclassId = GetItemInfo(id)
    return (itemClassId == Enum.ItemClass.Reagent)
        or (itemClassId == Enum.ItemClass.Miscellaneous and itemSubclassId == Enum.ItemMiscellaneousSubclass.Reagent)
end

function scavenger:hideOrShowMerchantItems(pageNumber)
    if pageNumber > 0 then                                                      --pdb('-----'..pageNumber..'-----')
        for i = 1, MERCHANT_ITEMS_PER_PAGE do
            _G["MerchantItem" .. i]:Hide()
        end
        C_Timer.After(0.3, function()
            -- Do this after a slight delay. This solves the issue where the
            -- server sometimes doesn't load a merchant's data the first time.
            for i = 1, MERCHANT_ITEMS_PER_PAGE do
                local show = false
                local index = (pageNumber - 1) * MERCHANT_ITEMS_PER_PAGE + i
                local name, tex = GetMerchantItemInfo(index)
                local link = GetMerchantItemLink(index)
                if link then
                    local id = self:parseItemLink(link)                         --pdb('['..id..']', link)
                    if not ScavengerUserData.ForbiddenItems[id] and
                        (ScavengerUserData.AllowedItems[id] or self:itemIsReagent(id))
                    then
                        _G["MerchantItem" .. i]:Show()
                    end
                end
            end
        end)
    else -- buyback
        for i = 1, 12 do
            _G["MerchantItem" .. i]:Show()
        end
    end
end

function scavenger:allowOrDisallowItem(itemStr, allow, userCommand)
    local name, link, rarity, level, minLevel, type, subType, stackCount, equipLoc, texture, sellPrice, classId, subclassId, bindType, expacId, setId, isCraftingReagent = GetItemInfo(itemStr)
    if not name then
        self:fail("Item not found: " .. itemStr)
        return false
    end

    local itemId, text = self:parseItemLink(link)
    if not itemId or not text then
        self:fail("Unable to parse item link: \"" .. link .. '"')
        return false
    end

    if allow then
        ScavengerUserData.AllowedItems[itemId] = 1
        ScavengerUserData.ForbiddenItems[itemId] = nil
        if userCommand then self:info(link .. " (" .. itemId .. ") now allowed") end
    else
        ScavengerUserData.AllowedItems[itemId] = nil
        ScavengerUserData.ForbiddenItems[itemId] = 1
        if userCommand then self:info(link .. " (" .. itemId .. ") now disallowed") end
    end

    return true
end

function scavenger:inventoryWarnings()
    local msgs = {}
    for slot = 1, 18 do
        local itemId = GetInventoryItemID('player', slot)
        if itemId then
            if ScavengerUserData.ForbiddenItems[itemId] then
                local name, link = GetItemInfo(itemId)
                msgs[#msgs+1] = "Unequip quest item: " .. link
            end
        end
    end
    return msgs
end

function scavenger:checkInventory()
    local msgs = self:inventoryWarnings()
    if #msgs == 0 then
        self:success("All equipped items are OK")
    else
        for _, msg in ipairs(msgs) do
            self:fail(msg)
        end
        if #msgs == 1 then
            self:flash(msgs[1])
        else
            self:flash("Unequip " .. #msgs .. " quest items")
        end
        self:playSound(ERROR_SOUND_FILE)
    end
end
