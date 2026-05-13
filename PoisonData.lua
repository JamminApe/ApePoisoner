-- ====================================
-- ApePoisoner : PoisonData.lua
-- Shared static poison data + DB init
-- ====================================

AscPoisonerPoisons = {
    { name = "Instant Poison",      spellID = 2060001, icon = "Interface\\Icons\\Ability_Poisons" },
    { name = "Deadly Poison",       spellID = 2060011, icon = "Interface\\Icons\\Ability_Rogue_DualWield" },
    { name = "Wound Poison",        spellID = 2060021, icon = "Interface\\Icons\\INV_Misc_Herb_16" },
    { name = "Crippling Poison",    spellID = 2060031, icon = "Interface\\Icons\\Ability_PoisonSting" },
    { name = "Mind-numbing Poison", spellID = 2060032, icon = "Interface\\Icons\\Spell_Nature_NullifyDisease" },
    { name = "Anesthetic Poison",   spellID = 2060033, icon = "Interface\\Icons\\Spell_Nature_SlowPoison" },
}

AscPoisonerDB = AscPoisonerDB or {}

if AscPoisonerDB.assignments == nil then
    AscPoisonerDB.assignments = {
        normal = { mh = nil, oh = nil },
        shift  = { mh = nil, oh = nil },
    }
end
if AscPoisonerDB.scale        == nil then AscPoisonerDB.scale        = 1.0   end
if AscPoisonerDB.fade         == nil then AscPoisonerDB.fade         = false end
if AscPoisonerDB.soundEnabled == nil then AscPoisonerDB.soundEnabled = true  end
if AscPoisonerDB.lockButton   == nil then AscPoisonerDB.lockButton   = false end
if AscPoisonerDB.enabled      == nil then AscPoisonerDB.enabled      = true  end
if AscPoisonerDB.buttonPos    == nil then AscPoisonerDB.buttonPos    = nil   end
if AscPoisonerDB.configModifier == nil then AscPoisonerDB.configModifier = "Alt" end