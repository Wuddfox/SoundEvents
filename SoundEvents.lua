--============================================================
-- SoundEvents - Core (Classic Era)
--============================================================

local ADDON_NAME = ...

--------------------------------------------------------------
-- SavedVariables (global so WoW can persist)
--------------------------------------------------------------
SoundEventsDB = SoundEventsDB or {}

--------------------------------------------------------------
-- Paths (tiered)
--------------------------------------------------------------
local BASE_SOUND_PATH = "Interface\\AddOns\\SoundEvents\\Sounds\\"
local function GetSoundPath()
    local tier = (SoundEventsDB and SoundEventsDB.volumeTier) or "high"
    return BASE_SOUND_PATH .. tier .. "\\"
end

--------------------------------------------------------------
-- Defaults
--------------------------------------------------------------
local defaults = {
    replaceMode = false,
    layerWithOriginal = true,
    debug = false,
    volumeTier = "high",
    enableMount = true,
    enableJump  = true,
    masterEnable = true,

    -- Base events
    jumpSound  = "boing.wav",
    mountSound = "lookatmyhorse.wav",

    -- spellID → filename
    spellSounds = {
        -- Warrior
        [25289] = "warrior_battleshout.wav",
        [18499] = "warrior_berserker.wav",
        [2458]  = "warrior_theyforgot.wav",
        [71]    = "warrior_bitch.wav",
        [20572] = "warrior_bonjour.wav",
		[11578]  = "warrior_leroyjenkins.wav",
        [2687]  = "warrior_scream.wav",
        [100]   = "warrior_leroyjenkins.wav",
        [20569] = "warrior_cleave.wav",
        [11556] = "warrior_demoral.wav",
        [20662] = "warrior_execute.wav",
        [20617] = "warrior_intercepted.wav",
        [5246]  = "warrior_fear.wav",
        [1680]  = "warrior_spin.wav",
		[2565]  = "warrior_you_shal_not_pass.ogg",
		[355]   = "warrior_your_mother.ogg",
		[12328] = "warrior_deathwish.ogg",

        -- Mage (include all Frost Nova ranks to be future-proof)
        [1953]  = "mage_surprise_mofo.wav",   -- Blink
        [12051] = "mage_mana.wav",            -- Evocation
        -- Polymorph (variant)
		[28271] = "mage_sheep.wav", --1
		[28272] = "mage_sheep.wav", --2
		[12826] = "mage_sheep.wav", --3
		[11366] = "mage_pyroblast.wav",
        [10199] = "mage_fire_blast.wav",
        [13021] = "mage_blast_wave.wav",
        [10187] = "mage_blizzard.wav",
        [10216] = "mage_flamestrike.wav",
        [2948]  = "mage_scorch.wav",
		[12042] = "mage_9000.ogg",
		[2139]  = "mage_expelliarmus.ogg",
		[12536] = "mage_another_one.ogg",
		
		-- portals
		[11417] = "mage_mr_worldwide.ogg", --org
		[11420] = "mage_mr_worldwide.ogg", --tb
		[11418] = "mage_mr_worldwide.ogg", --uc
       
	    -- Frost Nova fix because it's buggy (all ranks)
        [122]   = "mage_freeze_mofo.wav",     -- Rank 1
        [865]   = "mage_freeze_mofo.wav",     -- Rank 2
        [6131]  = "mage_freeze_mofo.wav",     -- Rank 3
        [10230] = "mage_freeze_mofo.wav",     -- Rank 4
		
    },

    -- Flat file list used by dropdowns; keep tier folders on disk
    availableSounds = {
        -- Misc
        "bam.ogg","boing.wav","off.wav","mariojump.wav", "lookatmyhorse.wav", "laugh.ogg",

        -- Warrior
        "warrior_battleshout.wav","warrior_berserker.wav","warrior_bitch.wav",
        "warrior_cleave.wav","warrior_cutmeoff.wav","warrior_demoral.wav",
        "warrior_execute.wav","warrior_fear.wav","warrior_gangnam.wav",
        "warrior_intercepted.wav","warrior_leroyjenkins.wav",
        "warrior_scream.wav","warrior_spin.wav",
        "warrior_theyforgot.wav","warrior_bonjour.wav", "warrior_you_shal_not_pass.ogg",
		"warrior_your_mother.ogg","warrior_deathwish.ogg",

        -- Mage
        "mage_freeze_mofo.wav","mage_mana.wav","mage_sheep.wav",
        "mage_surprise_mofo.wav","mage_pyroblast.wav","mage_fire_blast.wav",
        "mage_blast_wave.wav","mage_blizzard.wav","mage_flamestrike.wav",
        "mage_scorch.wav", "mage_9000.ogg", "mage_mr_worldwide.ogg", "mage_expelliarmus.ogg",
		"mage_another_one.ogg", "mage_syfm.mp3", 
    },
}

--------------------------------------------------------------
-- Debug printer
--------------------------------------------------------------
local function dprint(...)
    if SoundEventsDB and SoundEventsDB.debug then
        print("|cff00ff00[SoundEvents]|r", ...)
    end
end

--------------------------------------------------------------
-- Copy defaults (deep fill without clobbering user values)
--------------------------------------------------------------
local function copyDefaults(src, dest)
    if type(dest) ~= "table" then dest = {} end
    for k, v in pairs(src) do
        if type(v) == "table" then
            dest[k] = copyDefaults(v, dest[k])
        elseif dest[k] == nil then
            dest[k] = v
        end
    end
    return dest
end

--------------------------------------------------------------
-- Play helpers
--------------------------------------------------------------
local function PlaySESound(filename)
    if not filename or filename == "" then return end
    local path = GetSoundPath() .. filename
    PlaySoundFile(path, "Master")
    dprint("Played:", path)
end

local function PlayStrategy(filename)
    if not filename or filename == "" then return end
    if SoundEventsDB.masterEnable == false then
        dprint("Master OFF — skipped:", filename)
        return
    end

    if SoundEventsDB.replaceMode then
        -- Simple "replace": stop everything, then play ours
        StopAllSounds()
        PlaySESound(filename)
        return
    end

    -- Layer with Blizzard SFX or soft mute toggle if user disabled layering
    if SoundEventsDB.layerWithOriginal then
        PlaySESound(filename)
    else
        local old = GetCVar("Sound_EnableSFX")
        SetCVar("Sound_EnableSFX", 0)
        C_Timer.After(0.05, function()
            PlaySESound(filename)
            C_Timer.After(0.25, function()
                SetCVar("Sound_EnableSFX", old or 1)
            end)
        end)
    end
end

--------------------------------------------------------------
-- Jump detection
--------------------------------------------------------------
local lastJump = 0
hooksecurefunc("JumpOrAscendStart", function()
    if SoundEventsDB.enableJump == false then return end
    local now = GetTime()
    if now - lastJump > 0.25 then
        lastJump = now
        PlayStrategy(SoundEventsDB.jumpSound)
    end
end)

--------------------------------------------------------------
-- Event frame (mount + spellcast)
--------------------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
-- Player-scoped spell success
if f.RegisterUnitEvent then
    f:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
else
    -- Fallback (older clients) – still register global
    f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

local wasMounted = IsMounted()

f:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        local mounted = IsMounted()
        if mounted and not wasMounted then
            if SoundEventsDB.enableMount ~= false then
                PlayStrategy(SoundEventsDB.mountSound)
            end
        end
        wasMounted = mounted

    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit ~= "player" then return end

      local spellName = GetSpellInfo(spellID)
dprint("SUCCEEDED:", unit, spellID, spellName)

-- direct lookup
local file = SoundEventsDB.spellSounds and SoundEventsDB.spellSounds[spellID]

-- Frost Nova group fallback (if direct miss)
if not file then
    -- If this spellID is any Frost Nova rank, try the others
    local FN = {122, 865, 6131, 10230}
    local isFN = false
    for _, id in ipairs(FN) do if id == spellID then isFN = true break end end
    if isFN then
        for _, id in ipairs(FN) do
            if SoundEventsDB.spellSounds[id] and SoundEventsDB.spellSounds[id] ~= "" then
                file = SoundEventsDB.spellSounds[id]
                break
            end
        end
    end
end

if file and file ~= "" then
    dprint("Spell:", spellID, spellName or "?", "→", file)
    PlayStrategy(file)
else
    dprint("No mapping found for:", spellName, spellID)
end
end
end)

--------------------------------------------------------------
-- Init / SavedVariables (deferred until PLAYER_LOGIN)
--------------------------------------------------------------
local function SoundEvents_Initialize()
    -- Merge defaults first
    SoundEventsDB = copyDefaults(defaults, SoundEventsDB or {})
    -- Ensure available sound list is populated early
    SoundEventsDB.availableSounds = defaults.availableSounds

 ----------------------------------------------------------
    -- 🛠️ Migrate old filenames to new ones (non-destructive)
    ----------------------------------------------------------
    local renames = {
        ["warrior_lookatmyhorse.wav"] = "lookatmyhorse.wav",
        -- add more renames here if you change other filenames later
    }

    -- 1) Base event sounds (mount/jump)
    if renames[SoundEventsDB.mountSound] then
        dprint("Renamed mountSound:", SoundEventsDB.mountSound, "→", renames[SoundEventsDB.mountSound])
        SoundEventsDB.mountSound = renames[SoundEventsDB.mountSound]
    end
    if renames[SoundEventsDB.jumpSound] then
        dprint("Renamed jumpSound:", SoundEventsDB.jumpSound, "→", renames[SoundEventsDB.jumpSound])
        SoundEventsDB.jumpSound = renames[SoundEventsDB.jumpSound]
    end

    -- 2) Spell mapping values (replace old filenames with new)
    for spell, file in pairs(SoundEventsDB.spellSounds or {}) do
        local newFile = renames[file]
        if newFile then
            SoundEventsDB.spellSounds[spell] = newFile
            dprint("Updated mapping file:", tostring(spell), "→", newFile)
        end
    end

    -- 3) Safety: if a base sound points to a file not in availableSounds, reset to defaults
    local available = {}
    for _, fname in ipairs(SoundEventsDB.availableSounds or {}) do
        available[fname] = true
    end
    if not available[SoundEventsDB.mountSound] then
        dprint("mountSound not available, resetting to default:", defaults.mountSound)
        SoundEventsDB.mountSound = defaults.mountSound
    end
    if not available[SoundEventsDB.jumpSound] then
        dprint("jumpSound not available, resetting to default:", defaults.jumpSound)
        SoundEventsDB.jumpSound = defaults.jumpSound
    end
----------------------------------------------------------
-- 2️⃣ Convert name-based keys → spellID-based
--    (Never remap numeric keys; keep defaults intact)
----------------------------------------------------------
local upgraded, newMap = 0, {}

for k, v in pairs(SoundEventsDB.spellSounds or {}) do
    if type(k) == "number" then
        -- Always keep numeric spellIDs exactly as they are
        newMap[k] = v

    elseif type(k) == "string" then
        local id = select(7, GetSpellInfo(k))
        if id then
            -- Found a valid spellID (works for any locale)
            newMap[id] = v
            upgraded = upgraded + 1
        else
            -- Could not resolve localized string yet; keep for later fallback
            newMap[k] = v
            dprint("Unresolved spell name (locale pending):", k)
        end
    end
end

SoundEventsDB.spellSounds = newMap
if upgraded > 0 then
    dprint("Upgraded", upgraded, "name-based mappings to IDs.")
end


    ----------------------------------------------------------
    -- 3️⃣ Auto-correct known outdated mappings (optional)
    ----------------------------------------------------------
    local corrections = {
        ["Execute"] = "warrior_execute.wav",
        ["Defensive Stance"] = "warrior_bitch.wav",
        ["Blink"] = "mage_surprise_mofo.wav",
        ["Polymorph"] = "mage_sheep.wav",
        ["Evocation"] = "mage_mana.wav",
    }
    for spell, correctFile in pairs(corrections) do
        local old = SoundEventsDB.spellSounds[spell]
        if old and old ~= correctFile then
            SoundEventsDB.spellSounds[spell] = correctFile
            dprint("Corrected mapping:", spell, "→", correctFile)
        end
    end

    ----------------------------------------------------------
    -- 4️⃣ Deduplicate by normalized spell name
    --    Prefer numeric keys; if both numeric, prefer the HIGHEST ID
    ----------------------------------------------------------
    local seenByName, finalMap = {}, {}
    for k, v in pairs(SoundEventsDB.spellSounds or {}) do
        local name, keyIsNumber = nil, (type(k) == "number")

        if keyIsNumber then
            name = GetSpellInfo(k)
            -- If spell name isn't cached yet, preserve as-is (no dedup)
            if not name then
                finalMap[k] = v
            else
                local lower = name:lower()
                local already = seenByName[lower]
                if not already then
                    seenByName[lower] = { key = k, isNumber = true }
                    finalMap[k] = v
                else
                    if already.isNumber then
                        -- Both numeric: keep highest ID (usually highest rank)
                        if k > already.key then
                            finalMap[already.key] = nil
                            finalMap[k] = v
                            seenByName[lower] = { key = k, isNumber = true }
                            if SoundEventsDB.debug then
                                print("|cff99ff99SoundEvents:|r Chose higher ID for " .. name .. " (" .. k .. ")")
                            end
                        end
                    else
                        -- Replace existing string entry with numeric
                        finalMap[already.key] = nil
                        finalMap[k] = v
                        seenByName[lower] = { key = k, isNumber = true }
                        if SoundEventsDB.debug then
                            print("|cff99ff99SoundEvents:|r Replaced string with ID mapping for " .. name)
                        end
                    end
                end
            end

        else
            -- String key
            local id = select(7, GetSpellInfo(k))
            name = (id and GetSpellInfo(id)) or k
            local lower = name and name:lower() or k:lower()
            local already = seenByName[lower]
            if not already then
                seenByName[lower] = { key = k, isNumber = false }
                finalMap[k] = v
            else
                if already.isNumber then
                    -- Prefer numeric; drop this string entry
                    if SoundEventsDB.debug then
                        print("|cffff9999SoundEvents:|r Removed duplicate string entry for " .. lower)
                    end
                else
                    -- Two strings: keep the first
                    -- (no-op; entry already exists)
                end
            end
        end
    end
    SoundEventsDB.spellSounds = finalMap

    ----------------------------------------------------------
    -- 5️⃣ Reapply missing defaults (adds back any must-haves)
    ----------------------------------------------------------
    local reapplied = 0
    for id, defaultFile in pairs(defaults.spellSounds) do
        if not SoundEventsDB.spellSounds[id] then
            SoundEventsDB.spellSounds[id] = defaultFile
            reapplied = reapplied + 1
            dprint("Reapplied default mapping:", id, "→", defaultFile)
        end
    end
    if reapplied == 0 then dprint("No defaults needed reapplying.") end

----------------------------------------------------------
-- 🔁 Normalize Frost Nova ranks (force all four IDs to same file)
----------------------------------------------------------
local function ensureFrostNovaRanks()
    local ranks = {122, 865, 6131, 10230}

    -- find a file to use (prefer highest rank present)
    local chosen
    for _, id in ipairs({10230, 6131, 865, 122}) do
        if SoundEventsDB.spellSounds[id] and SoundEventsDB.spellSounds[id] ~= "" then
            chosen = SoundEventsDB.spellSounds[id]
            break
        end
    end

    -- if still no file, try any lingering string keys that resolve to Frost Nova
    if not chosen then
        for k, v in pairs(SoundEventsDB.spellSounds) do
            if type(k) == "string" then
                local id = select(7, GetSpellInfo(k))
                if id and (id == 122 or id == 865 or id == 6131 or id == 10230) then
                    chosen = v
                    break
                end
            end
        end
    end

    -- if still nothing, fall back to default
    if not chosen then
        chosen = "mage_freeze_mofo.wav"
    end

    -- write the same file to ALL ranks
    for _, id in ipairs(ranks) do
        if SoundEventsDB.spellSounds[id] ~= chosen then
            SoundEventsDB.spellSounds[id] = chosen
            if SoundEventsDB.debug then
                print("|cff99ff99SoundEvents:|r Frost Nova rank normalized:", id, "→", chosen)
            end
        end
    end

    -- remove any string keys that resolve to Frost Nova (locale-proof cleanup)
    for k in pairs(SoundEventsDB.spellSounds) do
        if type(k) == "string" then
            local id = select(7, GetSpellInfo(k))
            if id and (id == 122 or id == 865 or id == 6131 or id == 10230) then
                SoundEventsDB.spellSounds[k] = nil
                if SoundEventsDB.debug then
                    print("|cffff9999SoundEvents:|r Removed string key for Frost Nova:", k)
                end
            end
        end
    end
end

ensureFrostNovaRanks()


    ----------------------------------------------------------
    -- ✅ Load summary
    ----------------------------------------------------------
    dprint("Loaded. replaceMode=", tostring(SoundEventsDB.replaceMode),
           "layerWithOriginal=", tostring(SoundEventsDB.layerWithOriginal),
           "tier=", tostring(SoundEventsDB.volumeTier))
end

-- Defer initialization until spell data is fully cached
local init = CreateFrame("Frame")
init:RegisterEvent("ADDON_LOADED")
init:SetScript("OnEvent", function(_, _, name)
    if name ~= ADDON_NAME then return end
    local loginFrame = CreateFrame("Frame")
    loginFrame:RegisterEvent("PLAYER_LOGIN")
    loginFrame:SetScript("OnEvent", function()
        SoundEvents_Initialize()
    end)
end)

--------------------------------------------------------------
-- Run later, when spell data is guaranteed cached
--------------------------------------------------------------
local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function()
    SoundEvents_Initialize()
end)

--------------------------------------------------------------
-- 😆 /laugh sound
--------------------------------------------------------------
hooksecurefunc("DoEmote", function(emote)
    if type(emote) == "string" and emote:lower() == "laugh" then
        PlayStrategy("laugh.ogg")  -- path resolves via your tier system
        dprint("Played sound for /laugh emote")
    end
end)

--------------------------------------------------------------
-- Slash commands
--------------------------------------------------------------
SLASH_SOUNDEVENTS1 = "/se"
SlashCmdList.SOUNDEVENTS = function(msg)
    msg = (msg or ""):lower():gsub("^%s+",""):gsub("%s+$","")

    if msg == "debug" then
        SoundEventsDB.debug = not SoundEventsDB.debug
        print("SoundEvents debug:", SoundEventsDB.debug and "ON" or "OFF")

    elseif msg == "replace" then
        SoundEventsDB.replaceMode = not SoundEventsDB.replaceMode
        print("SoundEvents replace mode:",
              SoundEventsDB.replaceMode and "ON (stop all then play ours)" or
              "OFF (layering/soft-mute)")

    elseif msg == "layer" then
        SoundEventsDB.layerWithOriginal = not SoundEventsDB.layerWithOriginal
        print("Sound layering:",
              SoundEventsDB.layerWithOriginal and "ON" or "OFF (soft-mute fallback)")

    elseif msg == "on" then
        SoundEventsDB.masterEnable = true
        print("|cff00ff00SoundEvents: All sounds enabled.|r")

    elseif msg == "off" then
        SoundEventsDB.masterEnable = false
        print("|cffff0000SoundEvents: All sounds disabled.|r")

    elseif msg == "" or msg == "options" or msg == "config" then
        -- Open options panel (Retail/Classic support)
        if Settings and Settings.OpenToCategory then
            local cat = _G.SoundEventsCategory
            if cat then
                local ok = pcall(function() Settings.OpenToCategory(cat:GetID()) end)
                if not ok then Settings.OpenToCategory(cat) end
            else
                Settings.OpenToCategory(ADDON_NAME)
            end
        else
            print("SoundEvents: Options panel could not be opened.")
        end

    else
        print("Unknown command. Use: /se on|off|debug|replace|layer|options")
    end
end
