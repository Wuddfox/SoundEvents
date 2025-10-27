--============================================================
-- SoundEvents - Core (Classic Era)
--============================================================

local ADDON_NAME = ...

--------------------------------------------------------------
-- SavedVariables
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
    enableClearcasting = true,

    jumpSound  = "boing.wav",
    mountSound = "lookatmyhorse.wav",
    clearcastingSound = "clearcasting.wav",
	
    spellSounds = {
	
		--misc
		[7744]  = "wotf.ogg", --will of the forsaken
        -- Warrior
        [25289] = "warrior_battleshout.wav",
        [18499] = "warrior_berserker.wav",
        [2458]  = "warrior_theyforgot.wav",
        [71]    = "warrior_bitch.wav",
        [20572] = "warrior_bonjour.wav",
        [11578] = "warrior_leroyjenkins.wav",
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

        -- Mage
        [1953]  = "surprise_mofo.wav",
        [12051] = "mage_mana.wav",
        [11366] = "mage_pyroblast.wav",
        [10199] = "mage_fire_blast.wav",
        [13021] = "mage_blast_wave.wav",
        [10187] = "mage_blizzard.wav",   -- note: this is one rank; resolver will match by name for others
        [10216] = "mage_flamestrike.wav",
        [10207] = "mage_scorch.wav",
        [12042] = "mage_9000.ogg",
        [2139]  = "mage_expelliarmus.ogg",
        [12536] = "mage_another_one.ogg",
        [28271] = "mage_sheep.wav",
        [28272] = "mage_sheep.wav",
        [12826] = "mage_sheep.wav",
        [10230] = "mage_freeze_mofo.wav",
        [11417] = "mage_mr_worldwide.ogg",
        [11420] = "mage_mr_worldwide.ogg",
        [11418] = "mage_mr_worldwide.ogg",
		
		-- Rogue
		[13750] = "rogue_adrenaline.ogg",
		[13877] = "rogue_flurry.ogg",
		[25300] = "rogue_backstab.ogg",
		[1857]  = "rogue_vanish.ogg",
		[11305] = "rogue_sprint2.ogg",
		[11198] = "rogue_feint.ogg",
		[5277]  = "rogue_evasion.ogg",
		[1725]  = "rogue_distract.ogg",
		[1842]  = "rogue_disarmtrap.ogg",
		[11269] = "rogue_ambush.ogg",
		[1833]  = "surprise_mofo",
		
		
    },

    availableSounds = {
        "wotf.ogg","bam.ogg","boing.wav","off.wav","mariojump.wav","lookatmyhorse.wav","laugh.ogg","surprise_mofo.wav",
        "warrior_battleshout.wav","warrior_berserker.wav","warrior_bitch.wav",
        "warrior_cleave.wav","warrior_demoral.wav","warrior_execute.wav",
        "warrior_fear.wav","warrior_intercepted.wav","warrior_leroyjenkins.wav",
        "warrior_spin.wav","warrior_theyforgot.wav","warrior_bonjour.wav",
        "warrior_you_shal_not_pass.ogg","warrior_your_mother.ogg","warrior_deathwish.ogg",
        "mage_freeze_mofo.wav","mage_mana.wav","mage_sheep.wav","mage_pyroblast.wav","mage_fire_blast.wav",
        "mage_blast_wave.wav","mage_blizzard.wav","mage_flamestrike.wav",
        "mage_scorch.wav","mage_9000.ogg","mage_mr_worldwide.ogg","mage_expelliarmus.ogg",
        "mage_another_one.ogg","rogue_adrenaline.ogg","rogue_flurry.ogg","rogue_backstab.ogg","rogue_vanish.ogg",
		"rogue_backstab2.ogg","rogue_sprint2.ogg","rogue_sprint1.ogg","rogue_feint.ogg","rogue_evasion.ogg",
		"rogue_evasion2.ogg","rogue_distract.ogg","rogue_disarmtrap.ogg","rogue_ambush.ogg",
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
-- Copy defaults (deep fill)
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
    PlaySoundFile(GetSoundPath() .. filename, "Master")
    dprint("Played:", filename)
end

local function PlayStrategy(filename)
    if not filename or filename == "" or SoundEventsDB.masterEnable == false then return end
    if SoundEventsDB.replaceMode then StopAllSounds() end
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
local wasMounted = IsMounted()

--------------------------------------------------------------
-- ResolveSoundForSpell
-- Determines which sound file should play for a given spellID.
-- Handles rank variants, localization differences, and missing base IDs.
--------------------------------------------------------------
local function ResolveSoundForSpell(spellID)
    -- ✅ Grab database reference safely
    local db = _G.SoundEventsDB
    if not db or not db.spellSounds then return nil end

    ----------------------------------------------------------
    -- 🎯 Gather spell info (localized name + base ID)
    ----------------------------------------------------------
    local name = GetSpellInfo(spellID)
    local nameKey = name and name:lower() or nil

    -- Get the base spell family ID, or fallback for orphan spells (e.g. Feint)
    local baseId = select(7, GetSpellInfo(spellID))
    if not baseId or baseId == spellID then
        baseId = spellID  -- fallback for spells with no shared family
    end

    ----------------------------------------------------------
    -- 🧩 Resolution priority (4-tier lookup)
    ----------------------------------------------------------

    -- 1️⃣ Try baseId first (covers all ranks of a spell family)
    if baseId and db.spellSounds[baseId] then
        return db.spellSounds[baseId], "baseId", baseId
    end

    -- 2️⃣ Try exact spellID (rank-specific match)
    if db.spellSounds[spellID] then
        return db.spellSounds[spellID], "spellID", spellID
    end

    -- 3️⃣ Try lowercase name key (language-agnostic fallback)
    if nameKey and db.spellSounds[nameKey] then
        -- Cache this numeric rank for faster future lookups
        db.spellSounds[spellID] = db.spellSounds[nameKey]
        return db.spellSounds[nameKey], "name", nameKey
    end

    -- 4️⃣ Last resort: scan default table for matching names
    -- (used if a mapping exists in defaults but not yet saved in DB)
    if nameKey then
        for id, snd in pairs(defaults.spellSounds) do
            if type(id) == "number" then
                local nm = GetSpellInfo(id)
                if nm and nm:lower() == nameKey then
                    -- Cache both the name alias and rank ID for persistence
                    db.spellSounds[nameKey] = snd
                    db.spellSounds[spellID] = snd
                    return snd, "defaults-scan", id
                end
            end
        end
    end

    ----------------------------------------------------------
    -- ❌ No match found (for debug readability)
    ----------------------------------------------------------
    return nil, "none", nil
end

--------------------------------------------------------------
-- Event handler
--------------------------------------------------------------
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
        local baseId = select(7, GetSpellInfo(spellID))
        if baseId == spellID then baseId = nil end
        local keyName = spellName and spellName:lower() or nil

        dprint("Lookup Debug → spellName:", spellName or "nil",
               "spellID:", spellID or "nil",
               "baseId:", baseId or "nil",
               "keyName:", keyName or "nil")

        local file, how, key = ResolveSoundForSpell(spellID)

        if file and file ~= "" then
            dprint("Match:", how, key or "nil", "→", file)
            PlayStrategy(file)
        else
            dprint("No mapping found for:", spellName, spellID, "base", baseId)
        end
    end
end)

--------------------------------------------------------------
-- Initialization (deferred)
--------------------------------------------------------------
local function SoundEvents_Initialize()
    SoundEventsDB = copyDefaults(defaults, SoundEventsDB or {})
	_G.SoundEventsDefaults = defaults                    -- if the options UI reads defaults
SoundEventsDB.availableSounds = defaults.availableSounds

    -- Add lowercase aliases for Classic ranks (from current DB)
    local added = 0
    for id, snd in pairs(SoundEventsDB.spellSounds) do
        if type(id) == "number" then
            local name = GetSpellInfo(id)
            if name then
                local key = name:lower()
                if not SoundEventsDB.spellSounds[key] then
                    SoundEventsDB.spellSounds[key] = snd
                    added = added + 1
                end
            end
        end
    end
    if added > 0 then
        print(string.format("|cff33ff99SoundEvents:|r Added %d name-based aliases for Classic ranks.", added))
    end

    -- Also seed aliases from defaults (covers fresh installs)
    local seeded = 0
    for id, snd in pairs(defaults.spellSounds) do
        if type(id) == "number" then
            local nm = GetSpellInfo(id)
            if nm then
                local k = nm:lower()
                if not SoundEventsDB.spellSounds[k] then
                    SoundEventsDB.spellSounds[k] = snd
                    seeded = seeded + 1
                end
            end
        end
    end
    if seeded > 0 and SoundEventsDB.debug then
        dprint("Seeded", seeded, "name aliases from defaults.")
    end

    -- ✅ Register events after aliases exist
    f:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    if f.RegisterUnitEvent then
        f:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    else
        f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    end

    dprint("SoundEvents initialized successfully.")
end

--------------------------------------------------------------
-- Deferred init when data cached
--------------------------------------------------------------
local init = CreateFrame("Frame")
init:RegisterEvent("ADDON_LOADED")
init:SetScript("OnEvent", function(_, _, name)
    if name ~= ADDON_NAME then return end
    local login = CreateFrame("Frame")
    login:RegisterEvent("PLAYER_LOGIN")
    login:SetScript("OnEvent", SoundEvents_Initialize)
end)

--------------------------------------------------------------
-- /laugh
--------------------------------------------------------------
hooksecurefunc("DoEmote", function(emote)
    if type(emote) == "string" and emote:lower() == "laugh" then
        PlayStrategy("laugh.ogg")
        dprint("Played sound for /laugh emote")
    end
end)

--------------------------------------------------------------
-- Clearcasting detection
--------------------------------------------------------------
local CLEARCASTING_IDS = {
    [12536] = true, [16870] = true, [16246] = true, [14751] = true,
}
local lastCCExpire, lastCCSpell

local function GetClearcastingInfo()
    for i = 1, 40 do
        local _, _, _, _, _, expire, _, _, _, id = UnitBuff("player", i)
        if not id then break end
        if CLEARCASTING_IDS[id] then return id, expire end
    end
end

local function CheckClearcasting()
    local id, expire = GetClearcastingInfo()
    if id then
        if id ~= lastCCSpell or expire ~= lastCCExpire then
            lastCCSpell, lastCCExpire = id, expire
            if SoundEventsDB.enableClearcasting ~= false then
                PlayStrategy(SoundEventsDB.clearcastingSound or "mage_another_one.ogg")
                dprint("🎵 Clearcasting triggered (" .. id .. ")")
            end
        end
    else
        lastCCSpell, lastCCExpire = nil, nil
    end
end

local cc = CreateFrame("Frame")
cc:RegisterEvent("UNIT_AURA")
cc:SetScript("OnEvent", function(_, _, unit)
    if unit == "player" then CheckClearcasting() end
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
        print("Replace mode:", SoundEventsDB.replaceMode and "ON" or "OFF")
    elseif msg == "layer" then
        SoundEventsDB.layerWithOriginal = not SoundEventsDB.layerWithOriginal
        print("Layer mode:", SoundEventsDB.layerWithOriginal and "ON" or "OFF")
    elseif msg == "on" then
        SoundEventsDB.masterEnable = true
        print("|cff00ff00SoundEvents enabled.|r")
    elseif msg == "off" then
        SoundEventsDB.masterEnable = false
        print("|cffff0000SoundEvents disabled.|r")
		elseif msg == "" or msg == "options" or msg == "config" then
    -- 🧭 Open the Interface Options panel (Classic 1.15+ safe)
    if Settings and Settings.OpenToCategory then
        if _G.SoundEventsCategory then
            local ok = pcall(function() Settings.OpenToCategory(_G.SoundEventsCategory:GetID()) end)
            if not ok then Settings.OpenToCategory(_G.SoundEventsCategory) end
        else
            Settings.OpenToCategory(ADDON_NAME)
        end
    else
        print("SoundEvents: Options panel could not be opened.")
    end
    else
        print("Usage: /se on|off|debug|replace|layer")
    end
end
