-- ====================================
-- ApePoisoner : Core.lua
-- Weapon enchant tracking + alerts
-- ====================================

local NO_POISON_FIRST_DELAY    = 30
local NO_POISON_REPEAT_TIME    = 120
local NO_POISON_MAX_LOOPS      = 3
local EXPIRATION_WARNING_TIME  = 120
local UPDATE_THROTTLE          = 1.0   -- check enchants at most once per second

AscPoisonerState = AscPoisonerState or {}
AscPoisonerState.mhExpire      = AscPoisonerState.mhExpire      or 0
AscPoisonerState.ohExpire      = AscPoisonerState.ohExpire      or 0
AscPoisonerState.expWarned     = AscPoisonerState.expWarned     or false
AscPoisonerState.noPoisonTimer = AscPoisonerState.noPoisonTimer or 0
AscPoisonerState.noPoisonLoops = AscPoisonerState.noPoisonLoops or 0
AscPoisonerState.initialized   = AscPoisonerState.initialized   or false
AscPoisonerState.throttleTimer = AscPoisonerState.throttleTimer or 0

-- ── Slash commands ─────────────────────────────────────────────────────────
SLASH_APEPOISONER1 = "/apep"
SlashCmdList["APEPOISONER"] = function(msg)
    msg = msg and msg:lower() or ""
    if msg == "enable" then
        AscPoisonerDB.enabled = true
        AscPoisonerState.noPoisonTimer = 0
        AscPoisonerState.noPoisonLoops = 0
        AscPoisonerState.expWarned     = false
        AscPoisonerState.initialized   = false
        print("|cff00ff00ApePoisoner ENABLED|r")
    elseif msg == "disable" then
        AscPoisonerDB.enabled = false
        print("|cffff0000ApePoisoner DISABLED|r")
    elseif msg == "config" then
        if AscensionPoisonerConfig then AscensionPoisonerConfig:Show() end
    else
        print("|cff00ff00ApePoisoner|r  /apep enable|cffffd700 – enable|r  /apep disable|cffffd700 – disable|r  /apep config|cffffd700 – settings|r")
    end
end

-- ── Keybinding handler ─────────────────────────────────────────────────────

function APEPOISONER_TOGGLE()
    if AscensionPoisonerConfig then
        if AscensionPoisonerConfig:IsShown() then
            AscensionPoisonerConfig:Hide()
        else
            AscensionPoisonerConfig:Show()
        end
    end
end

-- ── Internal helpers ───────────────────────────────────────────────────────
local function UpdateWeaponEnchants()
    local mhHas, mhTime, _, ohHas, ohTime = GetWeaponEnchantInfo()
    AscPoisonerState.mhExpire = mhHas and (mhTime / 1000) or 0
    AscPoisonerState.ohExpire = ohHas and (ohTime / 1000) or 0

    if mhHas or ohHas then
        -- Weapons are poisoned – reset no-poison nag
        AscPoisonerState.noPoisonTimer = 0
        AscPoisonerState.noPoisonLoops = 0
    end

    -- Reset expiration warning once both weapons have plenty of time left
    if (not mhHas or mhTime > EXPIRATION_WARNING_TIME * 1000)
    and (not ohHas or ohTime > EXPIRATION_WARNING_TIME * 1000) then
        AscPoisonerState.expWarned = false
    end
end

local function CheckExpirationWarning()
    if AscPoisonerState.expWarned then return end
    if not AscPoisonerDB.soundEnabled then return end
    local mhLow = AscPoisonerState.mhExpire > 0 and AscPoisonerState.mhExpire <= EXPIRATION_WARNING_TIME
    local ohLow = AscPoisonerState.ohExpire > 0 and AscPoisonerState.ohExpire <= EXPIRATION_WARNING_TIME
    if mhLow or ohLow then
        AscPoisonerState.expWarned = true
        pcall(PlaySoundFile, "Interface\\AddOns\\ApePoisoner\\Media\\AscPoisoner_ExpPoison.ogg")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff6600ApePoisoner:|r Your poisons are about to expire!", 1, 0.4, 0)
    end
end

local function CheckNoPoison(elapsed)
    if AscPoisonerState.noPoisonLoops >= NO_POISON_MAX_LOOPS then return end
    if AscPoisonerState.mhExpire > 0 or AscPoisonerState.ohExpire > 0 then return end

    AscPoisonerState.noPoisonTimer = AscPoisonerState.noPoisonTimer + elapsed
    local threshold = AscPoisonerState.noPoisonLoops == 0 and NO_POISON_FIRST_DELAY or NO_POISON_REPEAT_TIME

    if AscPoisonerState.noPoisonTimer >= threshold then
        AscPoisonerState.noPoisonTimer = 0
        AscPoisonerState.noPoisonLoops = AscPoisonerState.noPoisonLoops + 1
        if AscPoisonerDB.soundEnabled then
            pcall(PlaySoundFile, "Interface\\AddOns\\ApePoisoner\\Media\\AscPoisoner_NoPoison.ogg")
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cffff3333ApePoisoner:|r No poisons applied to weapons!", 1, 0.2, 0.2)
    end
end

-- ── Event frame ───────────────────────────────────────────────────────────
local coreFrame = CreateFrame("Frame")
coreFrame:RegisterEvent("PLAYER_LOGIN")
coreFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
coreFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")

coreFrame:SetScript("OnEvent", function(self, event, unit)
    if not AscPoisonerDB.enabled then return end
    if event == "UNIT_INVENTORY_CHANGED" and unit ~= "player" then return end
    UpdateWeaponEnchants()
    CheckExpirationWarning()
    AscPoisonerState.initialized = true
    -- Notify UI to refresh (e.g. cooldown bar)
    if AscPoisoner_UpdateUI then AscPoisoner_UpdateUI() end
end)

-- ── Throttled OnUpdate (1 s tick) ─────────────────────────────────────────
coreFrame:SetScript("OnUpdate", function(self, elapsed)
    if not AscPoisonerDB.enabled or not AscPoisonerState.initialized then return end

    AscPoisonerState.throttleTimer = AscPoisonerState.throttleTimer + elapsed
    if AscPoisonerState.throttleTimer < UPDATE_THROTTLE then return end
    AscPoisonerState.throttleTimer = 0

    UpdateWeaponEnchants()
    CheckExpirationWarning()
    CheckNoPoison(UPDATE_THROTTLE)  -- pass the fixed tick interval so nag timing is accurate

    if AscPoisoner_UpdateUI then AscPoisoner_UpdateUI() end
end)