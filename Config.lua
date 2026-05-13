-- ====================================
-- ApePoisoner : Config.lua
-- Settings panel
-- ====================================

AscensionPoisonerConfig = nil

local WEAPON_LABELS = { mh = "Main Hand", oh = "Off Hand" }

function CreateConfig()
    -- ── Standalone popup (Alt+Click / /apep config) ───────────────────────
    local popup = CreateFrame("Frame", "AscensionPoisonerConfigFrame", UIParent)
    AscensionPoisonerConfig = popup
    popup:SetWidth(420)
    popup:SetHeight(400)
    popup:SetPoint("CENTER")
    popup:SetFrameStrata("DIALOG")
    popup:SetMovable(true)
    popup:EnableMouse(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", function(self) self:StartMoving() end)
    popup:SetScript("OnDragStop",  function(self) self:StopMovingOrSizing() end)
    popup:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true, tileSize = 32, edgeSize = 32,
        insets   = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    popup:Hide()

    -- ── InterfaceOptions panel ────────────────────────────────────────────
    local panel = CreateFrame("Frame")
    panel.name  = "ApePoisoner"

    -- ── Close button (popup only) ─────────────────────────────────────────
    local close = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() popup:Hide() end)

    -- ── Shared state ──────────────────────────────────────────────────────
    local dropdowns = {}
    local fadeCB, soundCB, lockCB, slider, valText, modDD

    local function RefreshAll()
        for _, e in ipairs(dropdowns) do
            local saved = AscPoisonerDB.assignments
                       and AscPoisonerDB.assignments[e.profile]
                       and AscPoisonerDB.assignments[e.profile][e.weapon]
            local tr = _G[e.name .. "Text"]
            if tr then tr:SetText(saved or "None") end
        end
        if fadeCB  then fadeCB:SetChecked( AscPoisonerDB.fade         and true or false) end
        if soundCB then soundCB:SetChecked(AscPoisonerDB.soundEnabled and true or false) end
        if lockCB  then lockCB:SetChecked( AscPoisonerDB.lockButton   and true or false) end
        if slider  then
            slider:SetValue(AscPoisonerDB.scale or 1.0)
            if valText then valText:SetText(string.format("%.2f", slider:GetValue())) end
        end
        if modDD then
            local modText = _G[modDD:GetName() .. "Text"]
            if modText then modText:SetText(AscPoisonerDB.configModifier or "Alt") end
        end
    end

    -- ── Dropdown helper ───────────────────────────────────────────────────
    local function CreatePoisonDropdown(parent, uniqueName, xOff, yOff, profile, weapon)
        local dd = CreateFrame("Frame", uniqueName, parent, "UIDropDownMenuTemplate")
        dd:SetPoint("TOPLEFT", xOff, yOff)
        UIDropDownMenu_SetWidth(dd, 130)

        local ddBtn = _G[uniqueName .. "Button"]
        if ddBtn then
            ddBtn:SetScript("OnEnter", function(self)
                local assigned = AscPoisonerDB.assignments
                              and AscPoisonerDB.assignments[profile]
                              and AscPoisonerDB.assignments[profile][weapon]
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                GameTooltip:AddLine(WEAPON_LABELS[weapon] .. "  (" .. (profile == "shift" and "Shift" or "Normal") .. " Profile)", 1, 0.84, 0)
                if assigned then
                    for _, p in ipairs(AscPoisonerPoisons) do
                        if p.name == assigned then
                            GameTooltip:AddLine(" ")
                            GameTooltip:AddLine("Selected: |cff00ff00" .. p.name .. "|r", 1, 1, 1)
                            GameTooltip:AddTexture(p.icon)
                            break
                        end
                    end
                else
                    GameTooltip:AddLine("No poison selected", 0.7, 0.7, 0.7)
                end
                GameTooltip:Show()
            end)
            ddBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end

        UIDropDownMenu_Initialize(dd, function(self, level)
            local info = UIDropDownMenu_CreateInfo()
            info.text = "None"
            info.func = function()
                local tr = _G[uniqueName .. "Text"]
                if tr then tr:SetText("None") end
                if AscPoisonerDB.assignments and AscPoisonerDB.assignments[profile] then
                    AscPoisonerDB.assignments[profile][weapon] = nil
                end
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info, level)

            if AscPoisonerPoisons then
                for _, p in ipairs(AscPoisonerPoisons) do
                    local poison = p
                    local ni = UIDropDownMenu_CreateInfo()
                    ni.text  = poison.name
                    ni.value = poison.name
                    ni.icon  = poison.icon
                    ni.func  = function()
                        local tr = _G[uniqueName .. "Text"]
                        if tr then tr:SetText(poison.name) end
                        if AscPoisonerDB.assignments and AscPoisonerDB.assignments[profile] then
                            AscPoisonerDB.assignments[profile][weapon] = poison.name
                        end
                        CloseDropDownMenus()
                    end
                    UIDropDownMenu_AddButton(ni, level)
                end
            end
        end)

        table.insert(dropdowns, { dd = dd, name = uniqueName, profile = profile, weapon = weapon })
    end

    -- ── Checkbox helper ───────────────────────────────────────────────────
    local function MakeCB(parent, label, tip, xOff, cbY, relFrame, relPoint)
        local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
        if relFrame then
            cb:SetPoint("LEFT", relFrame, relPoint, xOff, 0)
        else
            cb:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff, cbY)
        end
        local lbl = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        lbl:SetPoint("LEFT", cb, "RIGHT", 4, 1)
        lbl:SetText(label)
        cb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(label, 1, 0.84, 0)
            GameTooltip:AddLine(tip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
        return cb
    end

    -- ── Content builder ───────────────────────────────────────────────────
    local function BuildContent(parent, yBase)
        -- Title
        local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -16)
        title:SetText("ApePoisoner")

        local y = yBase

        -- Profile header labels
        local nLbl = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        nLbl:SetPoint("TOPLEFT", 20, y)
        nLbl:SetText("Normal Profile")

        local sLbl = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        sLbl:SetPoint("TOPLEFT", 230, y)
        sLbl:SetText("Shift Profile")

        -- Row labels (MH and OH only)
        local function RowLabel(txt, yOff)
            local l = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            l:SetPoint("TOPLEFT", 10, yOff)
            l:SetText(txt)
            l:SetTextColor(0.8, 0.8, 0.8, 1)
        end
        RowLabel("MH", y - 22)
        RowLabel("OH", y - 62)

        -- Dropdowns (MH and OH only)
        local pfx = (parent == popup) and "" or "P"
        CreatePoisonDropdown(parent, "ApePoisonerDD1"..pfx,  20, y - 26, "normal", "mh")
        CreatePoisonDropdown(parent, "ApePoisonerDD2"..pfx,  20, y - 66, "normal", "oh")
        CreatePoisonDropdown(parent, "ApePoisonerDD4"..pfx, 230, y - 26,  "shift", "mh")
        CreatePoisonDropdown(parent, "ApePoisonerDD5"..pfx, 230, y - 66,  "shift", "oh")

        -- Checkboxes
        local cbY = y - 108
        fadeCB  = MakeCB(parent, "Fade",  "Fades button when poisoned; glows when unpoisoned.",     30, cbY)
        soundCB = MakeCB(parent, "Sound", "Plays audio alerts when poisons expire or are missing.", 55, cbY, fadeCB,  "RIGHT")
        lockCB  = MakeCB(parent, "Lock",  "Locks the button so Shift+Drag won't move it.",          55, cbY, soundCB, "RIGHT")
        fadeCB:SetChecked( AscPoisonerDB.fade         and true or false)
        soundCB:SetChecked(AscPoisonerDB.soundEnabled and true or false)
        lockCB:SetChecked( AscPoisonerDB.lockButton   and true or false)

        -- Slider
        slider = CreateFrame("Slider", "ApePoisonerScaleSlider", parent, "OptionsSliderTemplate")
        slider:SetWidth(200)
        slider:SetHeight(16)
        slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 30, y - 148)
        slider:SetMinMaxValues(0.5, 2.0)
        slider:SetValueStep(0.05)

        local slLow  = _G["ApePoisonerScaleSliderLow"]
        local slHigh = _G["ApePoisonerScaleSliderHigh"]
        local slText = _G["ApePoisonerScaleSliderText"]
        if slLow  then slLow:SetText("0.5")          end
        if slHigh then slHigh:SetText("2.0")          end
        if slText then slText:SetText("Button Scale") end

        valText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        valText:SetPoint("LEFT", slider, "RIGHT", 10, 0)
        valText:SetTextColor(1, 1, 0, 1)
        valText:SetText("1.00")

        slider:SetValue(AscPoisonerDB.scale or 1.0)
        valText:SetText(string.format("%.2f", slider:GetValue()))
        slider:SetScript("OnValueChanged", function()
            if valText then valText:SetText(string.format("%.2f", slider:GetValue())) end
        end)
        slider:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine("Button Scale", 1, 0.84, 0)
            GameTooltip:AddLine("Resize the poison button (0.5x – 2.0x).", 1, 1, 1)
            GameTooltip:Show()
        end)
        slider:SetScript("OnLeave", function() GameTooltip:Hide() end)

        -- Config open modifier key dropdown
        local modLbl = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        modLbl:SetPoint("TOPLEFT", parent, "TOPLEFT", 30, y - 180)
        modLbl:SetText("Config open modifier:")

        local modifiers = { "Alt", "Ctrl", "Shift" }
        local modDDName = "ApePoisonerModDD" .. ((parent == popup) and "" or "P")
        modDD = CreateFrame("Frame", modDDName, parent, "UIDropDownMenuTemplate")
        modDD:SetPoint("TOPLEFT", parent, "TOPLEFT", 170, y - 176)
        UIDropDownMenu_SetWidth(modDD, 80)

        local function SetModText(val)
            local tr = _G[modDDName .. "Text"]
            if tr then tr:SetText(val) end
        end

        UIDropDownMenu_Initialize(modDD, function(self, level)
            for _, m in ipairs(modifiers) do
                local mod = m
                local ni = UIDropDownMenu_CreateInfo()
                ni.text  = mod
                ni.value = mod
                ni.func  = function()
                    AscPoisonerDB.configModifier = mod
                    SetModText(mod)
                    CloseDropDownMenus()
                end
                UIDropDownMenu_AddButton(ni, level)
            end
        end)

        SetModText(AscPoisonerDB.configModifier or "Alt")

        local modDDBtn = _G[modDDName .. "Button"]
        if modDDBtn then
            modDDBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                GameTooltip:AddLine("Config Open Modifier", 1, 0.84, 0)
                GameTooltip:AddLine("Hold this key and click the button to open settings.", 1, 1, 1, true)
                GameTooltip:Show()
            end)
            modDDBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end

        -- Apply / Save
        local applyBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        applyBtn:SetWidth(150)
        applyBtn:SetHeight(28)
        applyBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", 30, y - 230)
        applyBtn:SetText("Apply / Save")
        applyBtn:SetScript("OnClick", function()
            AscPoisonerDB.fade         = fadeCB:GetChecked()  and true or false
            AscPoisonerDB.soundEnabled = soundCB:GetChecked() and true or false
            AscPoisonerDB.lockButton   = lockCB:GetChecked()  and true or false
            AscPoisonerDB.scale        = slider:GetValue()
            -- configModifier is saved immediately on selection, no need to re-save here
            if AscPoisoner_ApplyScale then AscPoisoner_ApplyScale() end
            if AscPoisoner_UpdateUI   then AscPoisoner_UpdateUI()   end
            print("|cff00ff00ApePoisoner:|r Settings saved.")
            popup:Hide()
        end)
    end

    BuildContent(popup, -44)
    popup:SetScript("OnShow", function() RefreshAll() end)

    BuildContent(panel, -44)
    panel:SetScript("OnShow", function() RefreshAll() end)

    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

-- ── Bootstrap ─────────────────────────────────────────────────────────────
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        local t = CreateFrame("Frame")
        t.left = 0.2
        t:SetScript("OnUpdate", function(self, elapsed)
            self.left = self.left - elapsed
            if self.left <= 0 then
                self:SetScript("OnUpdate", nil)
                CreateConfig()
            end
        end)
    end
end)