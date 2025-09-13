-- FILE: adapter.lua
-- Allows using the same source code for both WoW Classic and older versions,
-- such as WotLK 3.3.5 clients like you see in Project Epoch.

local ADDONNAME, ns = ...
if not ns then
    -- Namespace not available in Wrath, so we fallback:
    _G[ADDONNAME] = _G[ADDONNAME] or {}
    ns = _G[ADDONNAME]
end

ns.adapter = ns.adapter or {}
local adapter = ns.adapter

-- Feature detection -----------------------------------------------------------

adapter.isModern  = false
adapter.isWotLK   = false
adapter.isVanilla = false

if type(C_Timer) == "table" then
    adapter.isModern = true
elseif type(select) ~= "function" then
    adapter.isVanilla = true
elseif type(UnitAura) == "function" then
    adapter.isWotLK = true
end

-- Debug table dump ------------------------------------------------------------

function adapter:dumpTable(tbl)
    if type(DevTools_Dump) == 'function' then
        DevTools_Dump(tbl); print(' ')
        return
    end
    local function recursiveDump(t, indent)
        indent = indent or ""
        for k, v in pairs(t) do
            if type(v) == "table" then
                print(indent .. '[' .. tostring(k) .. '] = {')
                recursiveDump(v, indent .. '  ')
                print(indent .. "}")
            elseif type(v) == "string" then
                print(indent .. '[' .. tostring(k) .. '] = "' .. v .. '"')
            else
                print(indent .. '[' .. tostring(k) .. '] = ' .. tostring(v))
            end
        end
    end
    recursiveDump(tbl); print(' ')
end

-- Bags ------------------------------------------------------------------------

function adapter:getContainerNumSlots(bagIndex)
    if C_Container and type(C_Container.GetContainerNumSlots) == "function" then
        return C_Container.GetContainerNumSlots(bagIndex)
    else
        return GetContainerNumSlots(bagIndex)
    end
end

function adapter:getContainerItemLink(bagIndex, slotIndex)
    if C_Container and type(C_Container.GetContainerItemLink) == "function" then
        return C_Container.GetContainerItemLink(bagIndex, slotIndex)
    else
        return GetContainerItemLink(bagIndex, slotIndex)
    end
end

function adapter:getContainerItemId(bagIndex, slotIndex)
    if C_Container and type(C_Container.GetContainerItemID) == "function" then
        return C_Container.GetContainerItemID(bagIndex, slotIndex)
    else
        return GetContainerItemID(bagIndex, slotIndex)
    end
end

-- Return a consistent tuple: isQuestItem, questID, isActive
function adapter:getContainerItemQuestInfo(bagIndex, slotIndex)
    if C_Container and type(C_Container.GetContainerItemQuestInfo) == "function" then
        local info = C_Container.GetContainerItemQuestInfo(bagIndex, slotIndex)
        -- Retail normally returns a table; normalize to 3 values
        if type(info) == "table" then
            return info.isQuestItem or false, info.questID, info.isActive or false
        else
            -- Some builds return multiple values; pass them through
            local isQuestItem, questID, isActive = info
            return isQuestItem or false, questID, isActive or false
        end
    elseif type(GetContainerItemQuestInfo) == "function" then
        -- Wrath/Classic
        local isQuestItem, questID, isActive = GetContainerItemQuestInfo(bagIndex, slotIndex)
        return isQuestItem or false, questID, isActive or false
    else
        return false, nil, false
    end
end

-- Sound playback --------------------------------------------------------------

function adapter:playSound(soundRef, channel)
    channel = channel or "Master"
    if type(soundRef) == "string" then
        if type(PlaySoundFile) == "function" then
            local ok = pcall(function() PlaySoundFile(soundRef, channel) end)
            if ok then return end
            pcall(function() PlaySoundFile(soundRef) end)
            return
        end
        if type(PlaySound) == "function" then
            pcall(function() PlaySound(soundRef) end)
            return
        end
    elseif type(soundRef) == "number" and type(PlaySound) == "function" then
        local ok = pcall(function() PlaySound(soundRef, channel) end)
        if ok then return end
        pcall(function() PlaySound(soundRef) end)
        return
    end
end

-- Merchant item iteration helper ----------------------------------------------

function adapter:forEachMerchantItem(callback)
    if type(GetMerchantNumItems) ~= "function" then return end
    local num = GetMerchantNumItems()
    for idx = 1, num do
        local name, _, _, _, _, _, extendedCost = GetMerchantItemInfo(idx)
        local link = GetMerchantItemLink(idx)
        callback(idx, name, link, extendedCost)
    end
end

-- Parse item link into id & text ----------------------------------------------

function adapter:parseItemLink(link)
    if not link then return nil end
    local _, _, id, text = tostring(link):find(".*|.*|Hitem:(%d+):.*|h%[(.*)%]|h|r")
    return id and tonumber(id) or nil, text
end

-- Find an item in the player's bags -------------------------------------------

function adapter:findItemIdInBags(itemId)
    for bag = 0, NUM_BAG_SLOTS do
        local slots = adapter:getContainerNumSlots(bag)
        for slot = 1, slots do
            local link = adapter:getContainerItemLink(bag, slot)
            if link then
                local id, name = adapter:parseItemLink(link)
                if id then
                    if id == itemId then
                        return bag, slot
                    end
                end
            end
        end
    end
    return nil
end

function adapter:findItemLinkInBags(itemLink)
    for bag = 0, NUM_BAG_SLOTS do
        local slots = adapter:getContainerNumSlots(bag)
        for slot = 1, slots do
            local link = adapter:getContainerItemLink(bag, slot)
            if link and link == itemLink then
                return bag, slot
            end
        end
    end
    return nil
end
