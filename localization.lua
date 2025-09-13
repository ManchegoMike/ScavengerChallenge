-- FILE: localization.lua

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

-- To test a specific locale, hard-code it here and uncomment the line.
--locale = "deDE"

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

-- English (enUS)
ns["enUS"] = {
    all_equipped_ok = "All equipped items are OK",
    allow_help = "Allow an item you specify",
    auction_disallowed = "You cannot use the auction house",
    bad_item_link_s = function(s) return "Unable to parse item link: " .. s end,
    bank_disallowed = "You cannot use the bank",
    bank_help = function(level) return "Allow or disallow using the bank (decide before level " .. level .. ")" end,
    bank_off = "Using the bank is now forbidden",
    bank_on = "Using the bank is now allowed",
    cannot_equip_s = function(link) return "You cannot use " .. link end,
    disallow_help = "Disallow an item you specify",
    hearth_disallowed = "You cannot hearth - please destroy your hearthstone",
    hearth_help = function(level) return "Allow or disallow using a hearthstone (decide before level " .. level .. ")" end,
    hearth_off = "Hearthing is now forbidden",
    hearth_on = "Hearthing is now allowed",
    id_name_link = "id/name/link",
    init_base = "No dying, no trading, no mail, no auction house, no quest rewards, no buying from vendors (with a few exceptions)",
    init_desc = function(hearthOK, bankOK) return L.init_base .. ", " .. (hearthOK and "hearthing OK" or "no hearthing") .. ", " .. (bankOK and "banking OK" or "no banking") end,
    init_tip = function(cmd) return "Initialized: type " .. cmd .. " for more info" end,
    item_not_found_s = function(s) return "Item not found: " .. s end,
    level_too_high = "Your level is too high to change that",
    mail_activated = "You can now use mail for one minute",
    mail_already_activated = "Mail is already activated for one minute",
    mail_deactivated = "One minute has elapsed: mail is now deactivated",
    mail_disallowed = "You cannot use mail",
    mail_help = "Allow using mail for one minute (for quests only)",
    now_allowed_s_i = function(link, id) return link .. " (" .. id .. ") now allowed" end,
    now_disallowed_s_i = function(link, id) return link .. " (" .. id .. ") now disallowed" end,
    prefix = "SCAVENGER: ", -- One space at the end
    trade_activated = "You can now trade for one minute",
    trade_already_activated = "Trading is already activated for one minute",
    trade_deactivated = "One minute has elapsed: trading is now deactivated",
    trade_disallowed = "You cannot trade",
    trade_help = "Allow trading for one minute (for emergencies only)",
    unequip_n_quest_items = function(n) return "Unequip " .. n .. " quest items" end,
    unequip_quest_item_s = function(link) return "Unequip quest item " .. link end,
}

-- German (deDE)
ns["deDE"] = {
    title = "DIE SCAVENGER-HERAUSFORDERUNG",
    prefix = "SCAVENGER: ",
    description = "Hardcore, selbst gefunden (kein Post, kein Auktionshaus, kein Handeln), keine Questbelohnungen, keine Käufe bei Händlern außer für eine Angelrute und ein Reittier ab Stufe 40.",
    help_header = "Befehle:",
    help_allow  = "/scav allow {id/name/link}",
    help_allow_desc = "Ermöglicht einen angegebenen Gegenstand (per ID, Name oder Link).",
    help_disallow  = "/scav disallow {id/name/link}",
    help_disallow_desc = "Untersagt einen angegebenen Gegenstand (per ID, Name oder Link).",
    init_tip = function(cmd) return "Initialisiert – gib " .. cmd .. " für mehr Infos ein" end,
    all_ok = "Alle angelegten Gegenstände sind in Ordnung",
    unequip_quest_item_s = function(link) return "Questgegenstand ablegen: " .. link end,
    unequip_n_quest_items = function(n) return "Lege " .. n .. " Questgegenstände ab" end,
    item_not_found_s = function(s) return "Gegenstand nicht gefunden: " .. s end,
    bad_item_link_s = function(s) return "Gegenstandslink ungültig: " .. s end,
    now_allowed_s_i = function(link, id) return link .. " (" .. id .. ") ist jetzt erlaubt" end,
    now_disallowed_s_i = function(link, id) return link .. " (" .. id .. ") ist jetzt verboten" end,
    cannot_equip_s = function(link) return "Du kannst " .. link .. " nicht nutzen" end,
}

-- Spanish (esES)
ns["esES"] = {
    title = "EL DESAFÍO SCAVENGER",
    prefix = "SCAVENGER: ",
    description = "Hardcore, encontrado por ti mismo (sin correo, sin casa de subastas, sin intercambios), no se pueden usar recompensas de misiones, no se puede comprar nada a los comerciantes excepto una caña de pescar y una montura de nivel 40.",
    help_header = "Comandos:",
    help_allow  = "/scav allow {id/nombre/enlace}",
    help_allow_desc = "Permite un objeto especificado (por ID, nombre o enlace).",
    help_disallow  = "/scav disallow {id/nombre/enlace}",
    help_disallow_desc = "Prohíbe un objeto especificado (por ID, nombre o enlace).",
    init_tip = function(cmd) return "Inicializado: escribe " .. cmd .. " para más información" end,
    all_ok = "Todos los objetos equipados están permitidos",
    unequip_quest_item_s = function(link) return "Desequipa objeto de misión: " .. link end,
    unequip_n_quest_items = function(n) return "Desequipa " .. n .. " objetos de misión" end,
    item_not_found_s = function(s) return "Objeto no encontrado: " .. s end,
    bad_item_link_s = function(s) return "Enlace de objeto inválido: " .. s end,
    now_allowed_s_i = function(link, id) return link .. " (" .. id .. ") ahora permitido" end,
    now_disallowed_s_i = function(link, id) return link .. " (" .. id .. ") ahora prohibido" end,
    cannot_equip_s = function(link) return "No puedes usar " .. link end,
}

-- French (frFR)
ns["frFR"] = {
    title = "LE DÉFI SCAVENGER",
    prefix = "SCAVENGER : ",
    description = "Hardcore, trouvé par soi-même (pas de courrier, pas de maison de vente aux enchères, pas de commerce), impossible d'utiliser les récompenses de quête, impossible d'acheter quoi que ce soit chez les marchands sauf une canne à pêche et une monture de niveau 40.",
    help_header = "Commandes :",
    help_allow  = "/scav allow {id/nom/lien}",
    help_allow_desc = "Autorise un objet spécifié (par ID, nom ou lien).",
    help_disallow  = "/scav disallow {id/nom/lien}",
    help_disallow_desc = "Interdit un objet spécifié (par ID, nom ou lien).",
    init_tip = function(cmd) return "Initialisé : tapez " .. cmd .. " pour plus d’info" end,
    all_ok = "Tous les objets équipés sont valides",
    unequip_quest_item_s = function(link) return "Déséquipe l’objet de quête : " .. link end,
    unequip_n_quest_items = function(n) return "Déséquipe " .. n .. " objets de quête" end,
    item_not_found_s = function(s) return "Objet introuvable : " .. s end,
    bad_item_link_s = function(s) return "Lien d’objet invalide : " .. s end,
    now_allowed_s_i = function(link, id) return link .. " (" .. id .. ") autorisé maintenant" end,
    now_disallowed_s_i = function(link, id) return link .. " (" .. id .. ") interdit maintenant" end,
    cannot_equip_s = function(link) return "Vous ne pouvez pas utiliser " .. link end,
}

-- Italian (itIT)
ns["itIT"] = {
    title = "LA SFIDA SCAVENGER",
    prefix = "SCAVENGER: ",
    description = "Hardcore, trovato da soli (niente posta, niente casa d'aste, niente scambi), non è possibile usare le ricompense delle missioni, non si può acquistare nulla dai mercanti tranne una canna da pesca e una cavalcatura di livello 40.",
    help_header = "Comandi:",
    help_allow  = "/scav allow {id/nome/link}",
    help_allow_desc = "Permetti un oggetto specificato (ID, nome o link).",
    help_disallow  = "/scav disallow {id/nome/link}",
    help_disallow_desc = "Proibisci un oggetto specificato (ID, nome o link).",
    init_tip = function(cmd) return "Inizializzato: digita " .. cmd .. " per più info" end,
    all_ok = "Tutti gli oggetti equipaggiati sono validi",
    unequip_quest_item_s = function(link) return "Rimuovi oggetto di missione: " .. link end,
    unequip_n_quest_items = function(n) return "Rimuovi " .. n .. " oggetti di missione" end,
    item_not_found_s = function(s) return "Oggetto non trovato: " .. s end,
    bad_item_link_s = function(s) return "Link dell’oggetto non valido: " .. s end,
    now_allowed_s_i = function(link, id) return link .. " (" .. id .. ") ora consentito" end,
    now_disallowed_s_i = function(link, id) return link .. " (" .. id .. ") ora vietato" end,
    cannot_equip_s = function(link) return "Non può usare " .. link end,
}

-- Russian (ruRU)
ns["ruRU"] = {
    title = "ВЫЗОВ SCAVENGER",
    prefix = "SCAVENGER: ",
    description = "Хардкор, самостоятельно найдено (без почты, без аукциона, без обмена), нельзя использовать награды с квестов, нельзя покупать ничего у торговцев, кроме удочки и маунта 40 уровня.",
    help_header = "Команды:",
    help_allow  = "/scav allow {id/имя/ссылка}",
    help_allow_desc = "Разрешить указанный предмет (по ID, имени или ссылке).",
    help_disallow  = "/scav disallow {id/имя/ссылка}",
    help_disallow_desc = "Запретить указанный предмет (по ID, имени или ссылке).",
    init_tip = function(cmd) return "Инициализировано: введите " .. cmd .. " для справки" end,
    all_ok = "Все надетые предметы допустимы",
    unequip_quest_item_s = function(link) return "Сними предмет задания: " .. link end,
    unequip_n_quest_items = function(n) return "Сними " .. n .. " предмет(ов) задания" end,
    item_not_found_s = function(s) return "Предмет не найден: " .. s end,
    bad_item_link_s = function(s) return "Не удалось распознать ссылку на предмет: " .. s end,
    now_allowed_s_i = function(link, id) return link .. " (" .. id .. ") теперь разрешён" end,
    now_disallowed_s_i = function(link, id) return link .. " (" .. id .. ") теперь запрещён" end,
    cannot_equip_s = function(link) return "Вы не можете использовать " .. link end,
}

-- Traditional Chinese (zhTW)
ns["zhTW"] = {
    title = "拾荒者挑戰",
    prefix = "SCAVENGER：",
    description = "硬核，自行尋找（無郵件，無拍賣行，無交易），無法使用任務獎勳，無法向商人購買任何物品，除了釣魚竿和40級坐騎。",
    help_header = "指令：",
    help_allow  = "/scav allow {ID／名稱／連結}",
    help_allow_desc = "允許指定物品（依ID、名稱或連結）。",
    help_disallow  = "/scav disallow {ID／名稱／連結}",
    help_disallow_desc = "禁止指定物品（依ID、名稱或連結）。",
    init_tip = function(cmd) return "初始化完成：輸入 " .. cmd .. " 取得更多資訊" end,
    all_ok = "所有裝備的物品均合法",
    unequip_quest_item_s = function(link) return "請卸下任務物品：" .. link end,
    unequip_n_quest_items = function(n) return "請卸下 " .. n .. " 個任務物品" end,
    item_not_found_s = function(s) return "找不到物品：" .. s end,
    bad_item_link_s = function(s) return "無法解析物品連結：" .. s end,
    now_allowed_s_i = function(link, id) return link .. "（" .. id .. "）已允許使用" end,
    now_disallowed_s_i = function(link, id) return link .. "（" .. id .. "）已禁止使用" end,
    cannot_equip_s = function(link) return "你無法使用 " .. link end,
}

-- Korean (koKR)
ns["koKR"] = {
    title = "수집가 도전",
    prefix = "수집가: ", -- One space at the end
    description = "하드코어, 자가 발견 (우편, 경매장, 거래 불가), 퀘스트 보상 사용 불가, 상인에게서 물건을 구매할 수 없으며 40레벨 탈것과 낚싯대만 구매 가능합니다.",
    help_header = "명령어:",
    help_allow  = "/scav allow {ID/이름/링크}",
    help_allow_desc = "ID, 이름 또는 링크로 지정한 아이템을 허용합니다.",
    help_disallow  = "/scav disallow {ID/이름/링크}",
    help_disallow_desc = "ID, 이름 또는 링크로 지정한 아이템을 금지합니다.",
    init_tip = function(cmd) return "초기화됨: 자세한 정보는 " .. cmd .. " 명령어를 입력하세요." end,
    all_ok = "착용한 모든 아이템이 허용됩니다.",
    unequip_quest_item_s = function(link) return "퀘스트 아이템 해제: " .. link end,
    unequip_n_quest_items = function(n) return "퀘스트 아이템 " .. n .. "개를 해제하세요." end,
    item_not_found_s = function(s) return "아이템을 찾을 수 없습니다: " .. s end,
    bad_item_link_s = function(s) return "아이템 링크를 해석할 수 없습니다: " .. s end,
    now_allowed_s_i = function(link, id) return link .. " (" .. id .. ") 이(가) 허용되었습니다." end,
    now_disallowed_s_i = function(link, id) return link .. " (" .. id .. ") 이(가) 금지되었습니다." end,
    cannot_equip_s = function(link) return link .. "을(를) 사용할 수 없습니다." end,
}
