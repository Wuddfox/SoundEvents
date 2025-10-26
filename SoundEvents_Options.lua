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
-- Jump + Mount + Clearcasting (aligned and correctly spaced)
--------------------------------------------------------------

-- Container for Jump + Mount pair
local topRow = CreateFrame("Frame", nil, scrollChild)
topRow:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, -28)
topRow:SetWidth(600)
topRow:SetHeight(100)

--------------------------------------------------------------
-- Jump (left column)
--------------------------------------------------------------
local jumpCB = CreateCheckbox(topRow, "SE_JumpCB", "Enable Jump Sound", nil,
    function() return SoundEventsDB and SoundEventsDB.enableJump end,
    function(val)
        SoundEventsDB.enableJump = val
        print("|cff33ff99SoundEvents:|r Jump sound", val and "|cff00ff00enabled|r." or "|cffff0000disabled|r.")
    end
)
jumpCB:SetPoint("TOPLEFT", 0, -4)

local jumpDD = CreateDropdown(
    topRow, "SE_JumpDD", "Jump Sound",
    function() return SoundEventsDB and SoundEventsDB.jumpSound end,
    function(v)
        SoundEventsDB.jumpSound = v
        print("|cff33ff99SoundEvents:|r Jump sound set to |cffffff00" .. v .. "|r.")
    end,
    function() return (SoundEventsDB and SoundEventsDB.availableSounds) or {} end
)
jumpDD:SetPoint("TOPLEFT", jumpCB, "BOTTOMLEFT", -12, -14)
jumpDD:SetWidth(220)
UIDropDownMenu_SetWidth(jumpDD, 220)

--------------------------------------------------------------
-- Mount (right column)
--------------------------------------------------------------
local mountCB = CreateCheckbox(topRow, "SE_MountCB", "Enable Mount Sound", nil,
    function() return SoundEventsDB and SoundEventsDB.enableMount end,
    function(val)
        SoundEventsDB.enableMount = val
        print("|cff33ff99SoundEvents:|r Mount sound", val and "|cff00ff00enabled|r." or "|cffff0000disabled|r.")
    end
)
mountCB:SetPoint("TOPLEFT", jumpCB, "TOPLEFT", 260, 0) -- moved closer to Jump

local mountDD = CreateDropdown(
    topRow, "SE_MountDD", "Mount Sound",
    function() return SoundEventsDB and SoundEventsDB.mountSound end,
    function(v)
        SoundEventsDB.mountSound = v
        print("|cff33ff99SoundEvents:|r Mount sound set to |cffffff00" .. v .. "|r.")
    end,
    function() return (SoundEventsDB and SoundEventsDB.availableSounds) or {} end
)
mountDD:SetPoint("TOPLEFT", mountCB, "BOTTOMLEFT", -12, -14)
mountDD:SetWidth(220)
UIDropDownMenu_SetWidth(mountDD, 220)

--------------------------------------------------------------
-- Clearcasting (below both)
--------------------------------------------------------------
local clearcastCB = CreateCheckbox(scrollChild, "SE_ClearcastCB", "Enable Clearcasting Sound", nil,
    function() return SoundEventsDB and (SoundEventsDB.enableClearcasting ~= false) end,
    function(val)
        SoundEventsDB.enableClearcasting = val
        print("|cff33ff99SoundEvents:|r Clearcasting sound", val and "|cff00ff00enabled|r." or "|cffff0000disabled|r.")
    end
)
clearcastCB:SetPoint("TOPLEFT", topRow, "BOTTOMLEFT", 0, -8)

local clearcastDD = CreateDropdown(
    scrollChild, "SE_ClearcastDD", "Clearcasting Sound",
    function() return SoundEventsDB and SoundEventsDB.clearcastingSound end,
    function(v)
        SoundEventsDB.clearcastingSound = v
        print("|cff33ff99SoundEvents:|r Clearcasting sound set to |cffffff00" .. v .. "|r.")
    end,
    function() return (SoundEventsDB and SoundEventsDB.availableSounds) or {} end
)
clearcastDD:SetPoint("TOPLEFT", clearcastCB, "BOTTOMLEFT", -12, -14)
clearcastDD:SetWidth(220)
UIDropDownMenu_SetWidth(clearcastDD, 220)

lastAnchor = clearcastDD

--------------------------------------------------------------
-- Single section divider (below Clearcasting)
--------------------------------------------------------------
local divider = scrollChild:CreateTexture(nil, "ARTWORK")
divider:SetColorTexture(0.5, 0.5, 0.5, 0.4)
divider:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, -30)
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
spellDD:SetWidth(220)
UIDropDownMenu_SetWidth(spellDD, 220)
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
    --------------------------------------------------------------
    --  Group entries by prefix and sort alphabetically per group
    --------------------------------------------------------------
    local groups = {
        warrior = {},
        mage    = {},
        misc    = {},
    }

    for id, sound in pairs(SoundEventsDB.spellSounds or {}) do
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

    -- 🔤 Sort each group alphabetically by spell name
    for _, tbl in pairs(groups) do
        table.sort(tbl, function(a, b)
            return a.name:lower() < b.name:lower()
        end)
    end

    --------------------------------------------------------------
    --  Render each section with its own header
    --------------------------------------------------------------
    local function RenderGroup(header, tbl, startY)
        if #tbl == 0 then return startY end

        local headerFS = listContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        headerFS:SetPoint("TOPLEFT", 0, -startY)
        headerFS:SetText(header)
        table.insert(mappingLines, headerFS)

        startY = startY + 18
        for _, e in ipairs(tbl) do
            local line = listContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            line:SetPoint("TOPLEFT", 10, -startY)
            line:SetText(string.format("• |cff00ffff%s|r  |cffffff00%s|r", e.name, e.sound))
            table.insert(mappingLines, line)

            local btn = CreateFrame("Button", nil, listContainer)
            btn:SetPoint("TOPLEFT", line, "TOPLEFT", -2, 2)
            btn:SetPoint("BOTTOMRIGHT", line, "BOTTOMRIGHT", 2, -2)
            btn:SetScript("OnClick", function()
                spellInput:SetText(e.name)
                UIDropDownMenu_SetSelectedValue(spellDD, e.sound)
                UIDropDownMenu_SetText(spellDD, e.sound)
            end)
            table.insert(mappingLines, btn)

            startY = startY + 16
        end
        return startY + 10
    end

    local y = 0
    y = RenderGroup("Warrior Abilities", groups.warrior, y)
    y = RenderGroup("Mage Abilities", groups.mage, y)
    y = RenderGroup("Miscellaneous", groups.misc, y)

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

    ----------------------------------------------------------
    -- 🧩 Clean and validate input
    ----------------------------------------------------------
    local raw = spellInput:GetText() or ""
    local spell = raw
        :gsub("|c%x%x%x%x%x%x%x%x", "")  -- remove color codes
        :gsub("|r", "")
        :gsub("[%[%]]", "")               -- remove brackets
        :match("^%s*(.-)%s*$")            -- trim spaces

    local sound = UIDropDownMenu_GetSelectedValue(spellDD)
    if not spell or spell == "" then
        print("SoundEvents: Please enter a spell name.")
        return
    end
    if not sound or sound == "" then
        print("SoundEvents: Please choose a sound.")
        return
    end

    ----------------------------------------------------------
    -- 🌍 Resolve spell info
    ----------------------------------------------------------
    local spellName, _, _, _, _, _, baseId = GetSpellInfo(spell)
    if not spellName then
        print("SoundEvents: Unknown spell – check the name.")
        return
    end

    ----------------------------------------------------------
    -- 💾 Save both numeric ID and name-based mapping
    ----------------------------------------------------------
    local keyNumeric = baseId
    local keyName = spellName:lower()

    if keyNumeric then
        SoundEventsDB.spellSounds[keyNumeric] = sound
    end
    SoundEventsDB.spellSounds[keyName] = sound

    ----------------------------------------------------------
    -- 🧠 Feedback
    ----------------------------------------------------------
    print(string.format(
        "|cff33ff99SoundEvents:|r Mapped %s → %s%s",
        spellName,
        sound,
        keyNumeric and ("  (ID " .. keyNumeric .. " + name '" .. keyName .. "')") or ""
    ))

    ----------------------------------------------------------
    -- 🧹 Refresh UI
    ----------------------------------------------------------
    spellInput:SetText("")
    UIDropDownMenu_SetText(spellDD, "")
    UpdateSpellList()
end)




----------------------------------------------------------
-- ✅ Remove mapping (numeric + name-safe)
----------------------------------------------------------
removeButton:SetScript("OnClick", function()
    if not SoundEventsDB or not SoundEventsDB.spellSounds then return end

    local raw = spellInput:GetText() or ""
    if raw == "" then
        print("SoundEvents: please enter a spell name to remove.")
        return
    end

    -- Normalize: try to get numeric ID and lowercase name
    local _, _, _, _, _, _, baseId = GetSpellInfo(raw)
    local keyName = raw:lower()
    local removed = false

    -- Remove numeric key if found
    if baseId and SoundEventsDB.spellSounds[baseId] then
        SoundEventsDB.spellSounds[baseId] = nil
        removed = true
        print("SoundEvents: removed mapping for", GetSpellInfo(baseId) or ("#" .. baseId))
    end

    -- Remove string key if found
    if SoundEventsDB.spellSounds[keyName] then
        SoundEventsDB.spellSounds[keyName] = nil
        removed = true
        print("SoundEvents: removed mapping for", keyName)
    end

    if not removed then
        print("SoundEvents: no mapping found for", raw)
    end

    spellInput:SetText("")
    UIDropDownMenu_SetText(spellDD, "")
    UpdateSpellList()
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


