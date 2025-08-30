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

-- IMPORTANT: We do NOT hard-code "You receive item" here.
-- We will use the global LOOT_ITEM_SELF pattern at runtime for localization-safe parsing.

-- English (enUS)
ns["enUS"] = {
    title = "THE SCAVENGER CHALLENGE",
    prefix = "SCAVENGER: ", -- One space at the end
    description = "Hardcore, self-found (no mail, no auction house, no trading), cannot use quest rewards, cannot buy from merchants except reagents and gathering tools.",
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
    cannot_equip_s = function(link) return "You cannot use " .. link end,
}

-- German (deDE)
ns["deDE"] = {
    title = "DIE SCAVENGER-HERAUSFORDERUNG",
    prefix = "SCAVENGER: ",
    description = "Hardcore, selbst gefunden (kein Post, kein Auktionshaus, kein Handel), keine Questbelohnung, keine Käufe bei Händlern außer Reagenzien und Sammelwerkzeugen.",
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
    description = "Modo difícil, encontrado por uno mismo (sin correo, sin casa de subastas, sin comercio), no se pueden usar recompensas de misión, no se puede comprar a mercaderes salvo componentes y herramientas de recolección.",
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
    description = "Mode hardcore, trouvé soi-même (pas de courrier, pas d’hôtel des ventes, pas d’échanges), pas de récompense de quête, pas d’achat auprès des marchands sauf composants et outils de collecte.",
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
    description = "Hardcore, trovato personalmente (niente posta, niente casa d’aste, niente scambi), non puoi usare ricompense di missioni, non puoi comprare dai mercanti tranne reagenti e strumenti di raccolta.",
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
    description = "Хардкор, найдено самостоятельно (без почты, без аукциона, без обмена), нельзя использовать награды за задание, нельзя покупать у торговцев, кроме реагентов и инструментов сбора.",
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
    description = "硬核，自行獲得（無郵件、無拍賣場、無交易），不能使用任務獎勵，僅能購買施法材料與採集工具。",
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
    description = "하드코어, 자급자족 (우편, 경매장, 거래 금지), 퀘스트 보상 사용 불가, 상인에게서는 재료와 채집 도구만 구매 가능.",
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
