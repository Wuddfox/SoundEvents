--------------------------------------------------------------
-- SoundEvents Options Panel (Classic-safe + perfect alignment)
--------------------------------------------------------------
local ADDON_NAME = "SoundEvents"

--------------------------------------------------------------
-- Utility functions
--------------------------------------------------------------
local function CreateCheckbox(parent, name, label, tooltip, getFunc, setFunc)
    local cb = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
    cb.Text:SetText(label)
    cb.tooltipText = label
    cb.tooltipRequirement = tooltip
    cb:SetScript("OnClick", function(self) setFunc(self:GetChecked()) end)
    cb:SetScript("OnShow", function(self) self:SetChecked(getFunc()) end)
    return cb
end

local function CreateDropdown(parent, name, label, getFunc, setFunc, choicesProvider)
    local dd = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetText(label)
    title:SetPoint("BOTTOMLEFT", dd, "TOPLEFT", 16, 3)
    title:SetJustifyH("LEFT")

    UIDropDownMenu_Initialize(dd, function(_, level)
    local info = UIDropDownMenu_CreateInfo()
    for _, choice in ipairs(choicesProvider()) do
        info.text = choice
        info.value = choice
        info.func = function()
            UIDropDownMenu_SetSelectedValue(dd, choice)
            setFunc(choice)
            CloseDropDownMenus()
        end
        -- ✅ Set the checkmark only on the selected value
        info.checked = (getFunc() == choice)
        UIDropDownMenu_AddButton(info, level)
    end
end)

    dd:SetScript("OnShow", function()
        local val = getFunc()
        UIDropDownMenu_SetSelectedValue(dd, val)
        UIDropDownMenu_SetText(dd, val)
    end)

    return dd
end

--------------------------------------------------------------
-- Main panel and scroll frame
--------------------------------------------------------------
local panelParent = _G.InterfaceOptionsFramePanelContainer or UIParent
local panel = CreateFrame("Frame", ADDON_NAME.."OptionsPanel", panelParent)
panel.name = ADDON_NAME

local scrollFrame = CreateFrame("ScrollFrame", ADDON_NAME.."ScrollFrame", panel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 10, -10)
scrollFrame:SetPoint("BOTTOMRIGHT", -34, 10)
scrollFrame:SetClipsChildren(true)

local scrollChild = CreateFrame("Frame", ADDON_NAME.."ScrollChild", scrollFrame)
scrollChild:SetWidth(600)
scrollChild:SetHeight(2000)
scrollFrame:SetScrollChild(scrollChild)


--------------------------------------------------------------
-- Alignment frame (left column anchor)
--------------------------------------------------------------
local alignFrame = CreateFrame("Frame", nil, scrollChild)
alignFrame:SetPoint("TOPLEFT", 40, 0) -- left margin from window edge
alignFrame:SetWidth(1)
alignFrame:SetHeight(1)

--------------------------------------------------------------
-- Title
--------------------------------------------------------------
local title = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", alignFrame, "TOPLEFT", 0, -16)
title:SetText("SoundEvents Settings (scroll down for more settings)")

local lastAnchor = title


--------------------------------------------------------------
-- Master Enable Toggle
--------------------------------------------------------------
local masterCB = CreateCheckbox(scrollChild, "SE_MasterCB", "Enable All Sounds",
    "Globally enable or disable all SoundEvents playback",
    function() return SoundEventsDB and SoundEventsDB.masterEnable end,
    function(val) SoundEventsDB.masterEnable = val end
)
masterCB:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, -20)
lastAnchor = masterCB

--------------------------------------------------------------
-- Debug Checkbox
--------------------------------------------------------------
local debugCB = CreateCheckbox(scrollChild, "SE_DebugCB", "Enable Debug Messages", nil,
    function() return SoundEventsDB and SoundEventsDB.debug end,
    function(val)
        SoundEventsDB.debug = val
        print("|cff33ff99SoundEvents:|r Debug mode", val and "|cff00ff00enabled|r." or "|cffff0000disabled|r.")
    end
)
debugCB:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, -20)
lastAnchor = debugCB

--------------------------------------------------------------
-- Replace Mode
--------------------------------------------------------------
local replaceCB = CreateCheckbox(scrollChild, "SE_ReplaceCB", "Replace Mode (not implemented yet)",
    "Mute Blizzard sounds and only play custom ones",
    function() return SoundEventsDB and SoundEventsDB.replaceMode end,
    function(val)
        SoundEventsDB.replaceMode = val
        if val then
            print("|cff33ff99SoundEvents:|r Replace mode |cff00ff00ON|r (Blizzard sounds will be muted).")
        else
            print("|cff33ff99SoundEvents:|r Replace mode |cffff0000OFF|r (layer or soft-mute fallback will apply).")
        end
    end
)
replaceCB:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, -12)
lastAnchor = replaceCB

--------------------------------------------------------------
-- Layer Mode
--------------------------------------------------------------
local layerCB = CreateCheckbox(scrollChild, "SE_LayerCB", "Layer With Original (standard playback mode)",
    "Play custom sound in addition to Blizzard's",
    function() return SoundEventsDB and SoundEventsDB.layerWithOriginal end,
    function(val)
        SoundEventsDB.layerWithOriginal = val
        if val then
            print("|cff33ff99SoundEvents:|r Now layering custom sounds with Blizzard’s.")
        else
            print("|cff33ff99SoundEvents:|r Layering disabled (soft-mute fallback active).")
        end
    end
)
layerCB:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, -12)
lastAnchor = layerCB

--------------------------------------------------------------
-- Volume Dropdown
--------------------------------------------------------------
local function VolumeChoices() return { "low", "high" } end

local volumeDD = CreateDropdown(
    scrollChild, "SE_VolumeDD", "Volume Level",
    function() return SoundEventsDB and SoundEventsDB.volumeTier or "medium" end,
    function(v)
        SoundEventsDB.volumeTier = v
        print("|cff33ff99SoundEvents:|r Volume tier set to |cffffff00" .. v .. "|r.")
    end,
    VolumeChoices
)
volumeDD:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, -28)
lastAnchor = volumeDD

--------------------------------------------------------------
-- Jump Sound Toggle + Dropdown
--------------------------------------------------------------
local jumpCB = CreateCheckbox(scrollChild, "SE_JumpCB", "Enable Jump Sound", nil,
    function() return SoundEventsDB and SoundEventsDB.enableJump end,
    function(val)
        SoundEventsDB.enableJump = val
        print("|cff33ff99SoundEvents:|r Jump sound", val and "|cff00ff00enabled|r." or "|cffff0000disabled|r.")
    end
)
jumpCB:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, -20)
lastAnchor = jumpCB

local jumpDD = CreateDropdown(
    scrollChild, "SE_JumpDD", "Jump Sound",
    function() return SoundEventsDB and SoundEventsDB.jumpSound end,
    function(v)
        SoundEventsDB.jumpSound = v
        print("|cff33ff99SoundEvents:|r Jump sound set to |cffffff00" .. v .. "|r.")
    end,
    function() return (SoundEventsDB and SoundEventsDB.availableSounds) or {} end
)
jumpDD:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, -28)
lastAnchor = jumpDD

--------------------------------------------------------------
-- Mount Sound Toggle + Dropdown
--------------------------------------------------------------
local mountCB = CreateCheckbox(scrollChild, "SE_MountCB", "Enable Mount Sound", nil,
    function() return SoundEventsDB and SoundEventsDB.enableMount end,
    function(val)
        SoundEventsDB.enableMount = val
        print("|cff33ff99SoundEvents:|r Mount sound", val and "|cff00ff00enabled|r." or "|cffff0000disabled|r.")
    end
)
mountCB:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, -20)
lastAnchor = mountCB

local mountDD = CreateDropdown(
    scrollChild, "SE_MountDD", "Mount Sound",
    function() return SoundEventsDB and SoundEventsDB.mountSound end,
    function(v)
        SoundEventsDB.mountSound = v
        print("|cff33ff99SoundEvents:|r Mount sound set to |cffffff00" .. v .. "|r.")
    end,
    function() return (SoundEventsDB and SoundEventsDB.availableSounds) or {} end
)
mountDD:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, -24)
lastAnchor = mountDD


--------------------------------------------------------------
-- Section divider (below Mount dropdown)
--------------------------------------------------------------
local divider = scrollChild:CreateTexture(nil, "ARTWORK")
divider:SetColorTexture(0.5, 0.5, 0.5, 0.4)

-- Anchor directly under the Mount dropdown, with spacing
divider:SetPoint("TOPLEFT", mountDD, "BOTTOMLEFT", 0, -20)
divider:SetPoint("RIGHT", -40, 0)
divider:SetHeight(1)

lastAnchor = divider


--------------------------------------------------------------
-- Spell Sound Mapper
--------------------------------------------------------------
--------------------------------------------------------------
-- Spell Sound Mapper
--------------------------------------------------------------
local header = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
header:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, -40)
header:SetText("Spell Sound Mapper (experimental)")
lastAnchor = header

-- Instruction text
local mapperHelp = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
mapperHelp:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)
mapperHelp:SetText("Type the spell name in the box and select the sound to play, or click a mapping in the list to change it")
mapperHelp:SetJustifyH("LEFT")
lastAnchor = mapperHelp

-- Input + dropdown on one line
local spellInput = CreateFrame("EditBox", "SE_SpellInput", scrollChild, "InputBoxTemplate")
spellInput:SetSize(200, 25)
spellInput:SetPoint("TOPLEFT", mapperHelp, "BOTTOMLEFT", 0, -18) -- adjusted spacing
spellInput:SetAutoFocus(false)


local spellDD = CreateDropdown(
    scrollChild, "SE_SpellDD", "Sound",
    function() return nil end,
    function(v)
        if not SoundEventsDB.spellSounds then
            SoundEventsDB.spellSounds = {}
        end

        local spell = spellInput:GetText() or ""
        spell = spell:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("[%[%]]",""):match("^%s*(.-)%s*$")

        if not spell or spell == "" then
            print("SoundEvents: Please type a spell name before choosing a sound.")
            CloseDropDownMenus() -- ✅ safe close instead of SetText
            return
        end

        SoundEventsDB.spellSounds[spell] = v
        UpdateSpellList()
    end,
    function()
        return (SoundEventsDB and SoundEventsDB.availableSounds) or {}
    end
)

spellDD:SetPoint("TOPLEFT", spellInput, "TOPRIGHT", 10, -2)

-- Buttons
local addButton = CreateFrame("Button", "SE_AddSpell", scrollChild, "UIPanelButtonTemplate")
addButton:SetText("Add / Update")
addButton:SetSize(120, 22)
addButton:SetPoint("TOPLEFT", spellInput, "BOTTOMLEFT", 0, -8)

local removeButton = CreateFrame("Button", "SE_RemoveSpell", scrollChild, "UIPanelButtonTemplate")
removeButton:SetText("Remove")
removeButton:SetSize(80, 22)
removeButton:SetPoint("LEFT", addButton, "RIGHT", 10, 0)

-- Current Mappings
local listHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
listHeader:SetPoint("TOPLEFT", addButton, "BOTTOMLEFT", 0, -12)
listHeader:SetText("Current Mappings:")

local listContainer = CreateFrame("Frame", "SE_SpellList", scrollChild)
listContainer:SetPoint("TOPLEFT", listHeader, "BOTTOMLEFT", 0, -6)
listContainer:SetWidth(400)
local mappingLines = {}

-- ✅ Refresh list function
function UpdateSpellList()
    for _, f in ipairs(mappingLines) do f:Hide() end
    wipe(mappingLines)

        -- ✅ Use existing cleaned mappings (SoundEvents.lua already handles conversion)
    if not SoundEventsDB or not SoundEventsDB.spellSounds then return end
        --------------------------------------------------------------
        -- 4️⃣ Deduplicate by normalized spell name
        --------------------------------------------------------------
        local seenByName = {}
        local finalMap = {}

        for k, v in pairs(SoundEventsDB.spellSounds) do
            local id, name
            if type(k) == "number" then
                name = GetSpellInfo(k)
            elseif type(k) == "string" then
                id = select(7, GetSpellInfo(k))
                name = id and GetSpellInfo(id) or k
            end

            if name then
                local lower = name:lower()
                -- If an ID version already exists for this name, prefer it
                if not seenByName[lower] then
                    seenByName[lower] = true
                    finalMap[k] = v
                else
                    if SoundEventsDB.debug then
                        print("|cffff9999SoundEvents:|r Removed duplicate entry for " .. name)
                    end
                end
            else
                -- Keep unknowns just in case
                finalMap[k] = v
            end
        end

        SoundEventsDB.spellSounds = finalMap



    -- ✅ Grouped display by sound filename prefix
local groups = {
    warrior = {},
    mage    = {},
    misc    = {},
}

for id, sound in pairs(SoundEventsDB.spellSounds) do
    local name = GetSpellInfo(id) or ("#" .. id)
    if type(sound) == "string" then
        if sound:find("^warrior_") then
            table.insert(groups.warrior, { id = id, name = name, sound = sound })
        elseif sound:find("^mage_") then
            table.insert(groups.mage, { id = id, name = name, sound = sound })
        else
            table.insert(groups.misc, { id = id, name = name, sound = sound })
        end
    end
end

for _, list in pairs(groups) do
    table.sort(list, function(a,b) return a.name < b.name end)
end

local y = 0
local function addHeader(text)
    local hdr = listContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr:SetPoint("TOPLEFT", 0, -y)
    hdr:SetText("|cffFFD700—— " .. text .. " ——|r")
    table.insert(mappingLines, hdr)
    y = y + 18
end

local function addEntry(entry)
    local line = listContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    line:SetPoint("TOPLEFT", 0, -y)
    line:SetText(string.format("• |cff00ffff%s|r  |cffffff00%s|r", entry.name, entry.sound))
    table.insert(mappingLines, line)
    y = y + 16

    local btn = CreateFrame("Button", nil, listContainer)
    btn:SetPoint("TOPLEFT", line, "TOPLEFT", -2, 2)
    btn:SetPoint("BOTTOMRIGHT", line, "BOTTOMRIGHT", 2, -2)
    btn:SetScript("OnClick", function()
        spellInput:SetText(entry.name)
        UIDropDownMenu_SetSelectedValue(spellDD, entry.sound)
        UIDropDownMenu_SetText(spellDD, entry.sound)
    end)
    table.insert(mappingLines, btn)
end

if #groups.warrior > 0 then
    addHeader("Warrior")
    for _, e in ipairs(groups.warrior) do addEntry(e) end
    y = y + 8
end
if #groups.mage > 0 then
    addHeader("Mage")
    for _, e in ipairs(groups.mage) do addEntry(e) end
    y = y + 8
end
if #groups.misc > 0 then
    addHeader("Misc")
    for _, e in ipairs(groups.misc) do addEntry(e) end
end

listContainer:SetHeight(math.max(1, y))

end

if SoundEventsDB and SoundEventsDB.spellSounds then
    SoundEventsDB.spellSounds[""] = nil
end

C_Timer.After(0.2, UpdateSpellList)

-- ✅ Add/Update
addButton:SetScript("OnClick", function()
    if not SoundEventsDB then return end
    SoundEventsDB.spellSounds = SoundEventsDB.spellSounds or {}

    local raw = spellInput:GetText() or ""
    local spell = raw
        :gsub("|c%x%x%x%x%x%x%x%x", "")  -- remove color codes
        :gsub("|r", "")
        :gsub("[%[%]]", "")               -- remove brackets
        :match("^%s*(.-)%s*$")            -- trim

    local sound = UIDropDownMenu_GetSelectedValue(spellDD)
    if not spell or spell == "" then
        print("SoundEvents: Please enter a spell name.")
        return
    end
    if not sound or sound == "" then
        print("SoundEvents: Please choose a sound.")
        return
    end

    

    local id = select(7, GetSpellInfo(spell))
if not id then
    print("SoundEvents: unknown spell – check the name.")
    return
end
SoundEventsDB.spellSounds[id] = sound
print("SoundEvents: mapped", GetSpellInfo(id) or ("#" .. id), "-", sound)

    spellInput:SetText("")
    UIDropDownMenu_SetText(spellDD, "")
    UpdateSpellList()
end)

-- ✅ Remove
removeButton:SetScript("OnClick", function()
    if not SoundEventsDB or not SoundEventsDB.spellSounds then return end
    local raw = spellInput:GetText() or ""
    local id = select(7, GetSpellInfo(raw))
    if not id then
        print("SoundEvents: unknown spell name.")
        return
    end
    if SoundEventsDB.spellSounds[id] then
        SoundEventsDB.spellSounds[id] = nil
        print("SoundEvents: removed mapping for", GetSpellInfo(id) or ("#" .. id))
        spellInput:SetText("")
        UIDropDownMenu_SetText(spellDD, "")
        UpdateSpellList()
    else
        print("SoundEvents: no mapping found for", raw)
    end
end)




--------------------------------------------------------------
-- Register panel (Classic + Retail)
--------------------------------------------------------------
if Settings and Settings.RegisterCanvasLayoutCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, ADDON_NAME)
    Settings.RegisterAddOnCategory(category)
    _G.SoundEventsCategory = category
elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
    _G.SoundEventsCategory = panel
end


