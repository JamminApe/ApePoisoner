-- ====================================
-- ApePoisoner : UI.lua
-- Poison Application + Dynamic Icon + Countdown
-- ====================================

-- ── Timer queue ───────────────────────────────────────────────────────────
local timerQueue = {}
local timerFrame = CreateFrame("Frame")
timerFrame:SetScript("OnUpdate", function(self, elapsed)
    if #timerQueue == 0 then return end
    for i = #timerQueue, 1, -1 do
        local t = timerQueue[i]
        t.remaining = t.remaining - elapsed
        if t.remaining <= 0 then
            local fn = t.fn
            table.remove(timerQueue, i)
            pcall(fn)
        end
    end
end)

local function After(delay, fn)
    table.insert(timerQueue, { remaining = delay, fn = fn })
end

-- ── Main button ───────────────────────────────────────────────────────────
local btn = CreateFrame("Button", "AscensionPoisonerButton", UIParent, "SecureActionButtonTemplate")
btn:SetMovable(true)
btn:SetClampedToScreen(true)
btn:SetSize(48, 48)
btn:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
btn:EnableMouse(true)
btn:SetNormalTexture("Interface\\Icons\\Ability_Rogue_DualWield")

local pt = btn:CreateTexture(nil, "HIGHLIGHT")
pt:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
pt:SetBlendMode("ADD")
pt:SetAllPoints(btn)

-- ── Countdown text on button face ─────────────────────────────────────────
local countText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
countText:SetPoint("CENTER", btn, "CENTER", 0, 0)
countText:SetTextColor(1, 1, 0, 1)
countText:SetText("")

-- ── Glow (parented to UIParent so it can exceed button bounds) ────────────
local glowFrame = CreateFrame("Frame", nil, UIParent)
glowFrame:SetFrameStrata("MEDIUM")
glowFrame:SetSize(80, 80)
glowFrame:SetPoint("CENTER", btn, "CENTER", 0, 0)
glowFrame:SetAlpha(0)

local glow = glowFrame:CreateTexture(nil, "OVERLAY")
glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
glow:SetBlendMode("ADD")
glow:SetVertexColor(0.2, 1.0, 0.2, 1.0)
glow:SetAllPoints(glowFrame)

local glowAnimating = false
local glowAlpha     = 0
local glowDirection = 1
local GLOW_SPEED    = 0.5   -- pulses per second (lower = slower)
local GLOW_MIN      = 0.10
local GLOW_MAX      = 0.90

local function UpdateGlowFrame()
    if not AscPoisonerDB then return end
    local scale  = AscPoisonerDB.scale or 1.0
    local glowPx = (48 * scale) * 2.1
    glowFrame:SetSize(glowPx, glowPx)
    glowFrame:ClearAllPoints()
    glowFrame:SetPoint("CENTER", btn, "CENTER", 0, 0)
end

local function ShowPoisonGlow()
    if not glowAnimating then
        glowAnimating = true
        glowAlpha     = GLOW_MIN
        glowDirection = 1
        glowFrame:SetAlpha(glowAlpha)
        UpdateGlowFrame()
    end
end

local function HidePoisonGlow()
    glowAnimating = false
    glowFrame:SetAlpha(0)
end

-- ── Dedicated tick frame: glow + countdown (never pauses on hover) ────────
local uiTickFrame = CreateFrame("Frame")
uiTickFrame:SetScript("OnUpdate", function(self, elapsed)
    if glowAnimating then
        glowAlpha = glowAlpha + (glowDirection * GLOW_SPEED) * elapsed
        if glowAlpha >= GLOW_MAX then
            glowAlpha = GLOW_MAX; glowDirection = -1
        elseif glowAlpha <= GLOW_MIN then
            glowAlpha = GLOW_MIN; glowDirection = 1
        end
        glowFrame:SetAlpha(glowAlpha)
    end

    if AscPoisonerState then
        local remaining = math.max(AscPoisonerState.mhExpire or 0, AscPoisonerState.ohExpire or 0)
        if remaining > 0 then
            local m = math.floor(remaining / 60)
            local s = math.floor(remaining % 60)
            countText:SetText(m > 0 and string.format("%d:%02d", m, s) or tostring(s))
            if remaining > 120 then
                countText:SetTextColor(0, 1, 0, 1)
            elseif remaining > 60 then
                countText:SetTextColor(1, 1, 0, 1)
            else
                countText:SetTextColor(1, 0.2, 0.2, 1)
            end
        else
            countText:SetText("")
        end
    end
end)

-- ── Scale ─────────────────────────────────────────────────────────────────
function AscPoisoner_ApplyScale()
    if AscPoisonerDB and AscPoisonerDB.scale then
        btn:SetScale(AscPoisonerDB.scale)
        UpdateGlowFrame()
    end
end

-- ── Drag (Shift+LeftDrag, unless locked) ─────────────────────────────────
local isDragging = false

btn:SetScript("OnMouseDown", function(self, button)
    if AscPoisonerDB.lockButton then return end
    if button == "LeftButton" and IsShiftKeyDown() then
        isDragging = true
        self:StartMoving()
    end
end)

btn:SetScript("OnMouseUp", function(self, button)
    if isDragging then
        isDragging = false
        self:StopMovingOrSizing()
        local anchor, _, _, x, y = self:GetPoint()
        AscPoisonerDB.buttonPos = { anchor = anchor or "CENTER", x = x or 0, y = y or -120 }
        UpdateGlowFrame()
    end
end)

-- ── Restore saved position ────────────────────────────────────────────────
After(0, function()
    if AscPoisonerDB and AscPoisonerDB.buttonPos then
        local p = AscPoisonerDB.buttonPos
        btn:ClearAllPoints()
        btn:SetPoint(p.anchor or "CENTER", UIParent, p.anchor or "CENTER", p.x or 0, p.y or -120)
        UpdateGlowFrame()
    end
end)

-- ── Profile + slot helper ─────────────────────────────────────────────────
-- Left Click  = Main Hand (slot 16)
-- Right Click = Off Hand  (slot 17)
local function GetCurrentSelection(mouseButton)
    local profile = IsShiftKeyDown() and "shift" or "normal"
    local weapon  = (mouseButton == "RightButton") and "oh" or "mh"
    return profile, weapon
end

-- ── Update button icon ────────────────────────────────────────────────────
function AscPoisoner_UpdateButtonIcon(mouseButton)
    if not AscPoisonerDB or not AscPoisonerDB.assignments then return end
    local profile, weapon = GetCurrentSelection(mouseButton or "LeftButton")
    local poisonName = AscPoisonerDB.assignments[profile] and AscPoisonerDB.assignments[profile][weapon]
    if poisonName then
        for _, p in ipairs(AscPoisonerPoisons) do
            if p.name == poisonName then
                btn:SetNormalTexture(p.icon)
                return
            end
        end
    end
    btn:SetNormalTexture("Interface\\Icons\\Ability_Rogue_DualWield")
end

-- ── PreClick: build secure macro ─────────────────────────────────────────
btn:SetScript("PreClick", function(self, mouseButton)
    -- Config modifier: check whichever key the player has configured
    local mod = AscPoisonerDB.configModifier or "Alt"
    local modPressed = (mod == "Alt"   and IsAltKeyDown())
                    or (mod == "Ctrl"  and IsControlKeyDown())
                    or (mod == "Shift" and IsShiftKeyDown())
    if modPressed then
        if AscensionPoisonerConfig then AscensionPoisonerConfig:Show() end
        self:SetAttribute("type", nil)
        return
    end

    if not AscPoisonerDB or not AscPoisonerDB.assignments then
        self:SetAttribute("type", nil)
        return
    end

    local profile, weapon = GetCurrentSelection(mouseButton)
    local poisonName = AscPoisonerDB.assignments[profile] and AscPoisonerDB.assignments[profile][weapon]

    AscPoisoner_UpdateButtonIcon(mouseButton)

    if not poisonName then
        PlaySound("igQuestFailed")
        print("|cffff3333ApePoisoner:|r No poison assigned for "
            .. (weapon == "mh" and "Main Hand" or "Off Hand")
            .. " (" .. profile .. " profile).")
        self:SetAttribute("type", nil)
        return
    end

    local data = nil
    for _, p in ipairs(AscPoisonerPoisons) do
        if p.name == poisonName then data = p; break end
    end

    if not data then
        PlaySound("igQuestFailed")
        print("|cffff3333ApePoisoner:|r Unknown poison: " .. poisonName)
        self:SetAttribute("type", nil)
        return
    end

    if not IsSpellKnown(data.spellID) then
        PlaySound("igQuestFailed")
        print("|cffff3333ApePoisoner:|r You haven't learned " .. poisonName .. " yet.")
        self:SetAttribute("type", nil)
        return
    end

    local slot = (weapon == "mh") and 16 or 17

    -- Cast by spell name (Ascension does not support /cast <id>)
    self:SetAttribute("type", "macro")
    self:SetAttribute("macrotext", string.format("/cast %s\n/use %d", data.name, slot))
end)

-- ── PostClick: refresh state + confirmation message ───────────────────────
btn:SetScript("PostClick", function(self, mouseButton)
    After(0.3, function()
        if not GetWeaponEnchantInfo or not AscPoisonerState then return end

        local mhHas, mhTime, _, ohHas, ohTime = GetWeaponEnchantInfo()
        AscPoisonerState.mhExpire = mhHas and (mhTime / 1000) or 0
        AscPoisonerState.ohExpire = ohHas and (ohTime / 1000) or 0

        if not mhHas and not ohHas then
            AscPoisonerState.expWarned     = false
            AscPoisonerState.noPoisonTimer = 0
            AscPoisonerState.noPoisonLoops = 0
        end

        local profile, weapon = GetCurrentSelection(mouseButton)
        local poisonName = AscPoisonerDB.assignments[profile] and AscPoisonerDB.assignments[profile][weapon]
        if not poisonName then return end

        local slot        = (weapon == "mh") and 16 or 17
        local weaponLabel = (weapon == "mh") and "Main Hand" or "Off Hand"
        local itemLink    = GetInventoryItemLink("player", slot)
        if itemLink then
            print(string.format("|cff00ff00ApePoisoner:|r %s applied to %s %s", poisonName, weaponLabel, itemLink))
        end

        if AscPoisoner_UpdateUI then AscPoisoner_UpdateUI() end
    end)
end)

-- ── Tooltip ───────────────────────────────────────────────────────────────
local function ShowTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("|cffffd700ApePoisoner|r", 1, 1, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cff00ff00Left Click:|r  Apply Main-hand Poison", 1, 1, 1)
    GameTooltip:AddLine("|cff00ff00Right Click:|r Apply Off-hand Poison",  1, 1, 1)
    GameTooltip:AddLine("|cffaaaaaa Shift:|r Use alternate (Shift) profile", 0.8, 0.8, 0.8)
    local mod = AscPoisonerDB and AscPoisonerDB.configModifier or "Alt"
    GameTooltip:AddLine("|cffaaaaaa " .. mod .. "+Click:|r Open configuration", 0.6, 1, 0.6)
    GameTooltip:AddLine("|cffaaaaaa Shift+Drag:|r Move button",              0.8, 0.8, 0.8)
    GameTooltip:AddLine(" ")

    if AscPoisonerState and AscPoisonerState.mhExpire > 0 then
        local m = math.floor(AscPoisonerState.mhExpire / 60)
        local s = math.floor(AscPoisonerState.mhExpire % 60)
        GameTooltip:AddLine(string.format("MH: |cff00ff00%d:%02d remaining|r", m, s), 1, 1, 1)
    else
        GameTooltip:AddLine("MH: |cffff3333No poison|r", 1, 1, 1)
    end

    if AscPoisonerState and AscPoisonerState.ohExpire > 0 then
        local m = math.floor(AscPoisonerState.ohExpire / 60)
        local s = math.floor(AscPoisonerState.ohExpire % 60)
        GameTooltip:AddLine(string.format("OH: |cff00ff00%d:%02d remaining|r", m, s), 1, 1, 1)
    else
        GameTooltip:AddLine("OH: |cffff3333No poison|r", 1, 1, 1)
    end

    if AscPoisonerDB and AscPoisonerDB.assignments then
        GameTooltip:AddLine(" ")
        local norm = AscPoisonerDB.assignments.normal
        local shft = AscPoisonerDB.assignments.shift
        GameTooltip:AddLine("|cffffd700Normal profile:|r", 1, 1, 1)
        GameTooltip:AddLine("  MH: " .. (norm.mh or "|cff888888None|r"), 1, 1, 1)
        GameTooltip:AddLine("  OH: " .. (norm.oh or "|cff888888None|r"), 1, 1, 1)
        GameTooltip:AddLine("|cffffd700Shift profile:|r", 1, 1, 1)
        GameTooltip:AddLine("  MH: " .. (shft.mh or "|cff888888None|r"), 1, 1, 1)
        GameTooltip:AddLine("  OH: " .. (shft.oh or "|cff888888None|r"), 1, 1, 1)
    end

    GameTooltip:Show()
end

btn:SetScript("OnEnter", function(self)
    ShowTooltip(self)
    AscPoisoner_UpdateUI()
end)

btn:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
    GameTooltip:ClearLines()
    AscPoisoner_UpdateUI()
end)

-- ── UpdateUI ──────────────────────────────────────────────────────────────
function AscPoisoner_UpdateUI()
    if InCombatLockdown() then return end

    if not AscPoisonerDB or not AscPoisonerDB.enabled then
        btn:SetAlpha(0)
        btn:EnableMouse(false)
        HidePoisonGlow()
        countText:SetText("")
        return
    end

    btn:EnableMouse(true)
    AscPoisoner_ApplyScale()

    if not AscPoisonerDB.fade then
        btn:SetAlpha(1)
        HidePoisonGlow()
        return
    end

    local poisoned = AscPoisonerState and (AscPoisonerState.mhExpire > 0 or AscPoisonerState.ohExpire > 0)
    if poisoned then
        btn:SetAlpha(0.3)
        HidePoisonGlow()
    else
        btn:SetAlpha(1)
        ShowPoisonGlow()
    end
end

-- ── Initial setup ─────────────────────────────────────────────────────────
After(0, function()
    AscPoisoner_ApplyScale()
    AscPoisoner_UpdateUI()
    UpdateGlowFrame()
end)