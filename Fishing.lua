local _, ns = ...

-- How one key fishes. With a fishing pole on, out of combat, the keys bound to Interact are taken
-- over (an override binding, the same kind the game's own vehicle and pet bars use) to click a
-- secure button that casts Fishing. They're handed back to Interact:
--   * while the line's out (the bobber is then the soft interact target, so Interact clicks it);
--   * while anything else is in front of you to interact with (an NPC, a chest), so the key
--     still does that;
--   * in combat, and whenever the pole comes off.
-- The game's own soft targeting finds the bobber; while the pole's on, it's set to work for every
-- input (not just gamepads) and to reach as far as a cast lands.

local issecret = FrogLib.issecret

local Fishing = {}
ns.Fishing = Fishing

local FISHING = 7620 -- Fishing, rank 1 (the ranks share its name)
local FISHING_RANKS = { [7620] = true, [7731] = true, [7732] = true, [18248] = true }
local POLE = (Enum.ItemWeaponSubclass and Enum.ItemWeaponSubclass.Fishingpole) or 20
local WEAPON = (Enum.ItemClass and Enum.ItemClass.Weapon) or 2
local ANY = (Enum.SoftTargetEnableFlags and Enum.SoftTargetEnableFlags.Any) or 3
local LURE_EVERY = 300 -- seconds between "no lure" reminders

local owner = CreateFrame("Frame") -- owns the override bindings
local button, armed, channeling, castAt, lureSaid, keylessSaid
local SETTLE = 1.5 -- seconds for the bobber to land and be picked out (or not) after a cast

local function HasPole()
    local id = GetInventoryItemID("player", INVSLOT_MAINHAND or 16)
    if not id then return false end
    local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(id)
    return classID == WEAPON and subclassID == POLE
end

local function FishingName() return C_Spell.GetSpellName(FISHING) or "Fishing" end

-- Known by its first rank, or (should Forever number it differently) by its name in your spellbook.
local function KnowsFishing()
    local known = IsPlayerSpell or IsSpellKnown
    if known and known(FISHING) then return true end
    return C_Spell.GetSpellInfo(FishingName()) ~= nil
end

-- Something in front of you to interact with already (the bobber, an NPC, a chest). The bobber
-- is an object, not a unit, so "softinteract" doesn't see it: what the game last said it picked
-- out (PLAYER_SOFT_INTERACT_CHANGED's new target) does. Hidden by the game counts as something.
local softGUID

local function SoftTarget()
    if issecret(softGUID) then return true end
    if type(softGUID) == "string" and softGUID ~= "" then return true end
    local ok, exists = pcall(UnitExists, "softinteract")
    if not ok then return false end
    if issecret(exists) then return true end
    return exists and true or false
end

local function InteractKeys()
    local keys = {}
    for _, key in ipairs({ GetBindingKey("INTERACTTARGET") }) do
        if key and key ~= "" then keys[#keys + 1] = key end
    end
    return keys
end

-- The secure button the taken-over keys click: it casts Fishing (its highest rank, by name).
local function Button()
    if button then return button end
    button = CreateFrame("Button", "FrogFishCastButton", UIParent, "SecureActionButtonTemplate")
    button:RegisterForClicks("AnyUp", "AnyDown")
    button:SetAttribute("type", "spell")
    button:SetAttribute("spell", FishingName())
    button:Hide()
    return button
end

------------------------------------------------------------------------------
-- The pole: game options for fishing while it's on
------------------------------------------------------------------------------

function Fishing:PoleOptions(on)
    if InCombatLockdown() then return end
    if on then
        local values = {
            softTargetInteract = ANY,         -- Interact works on soft targets with any input
            SoftTargetIconGameObject = 1,     -- an icon over the bobber once it's targeted
            SoftTargetIconInteract = 1,       -- (the interact icon itself)
            SoftTargetLowPriorityIcons = 1,   -- the bobber can count as low priority, icon and all
            SoftTargetInteractRange = ns.db.range,
            -- The widest cone in front of you (0 narrow, 1 wide, 2 all round): a cast often lands
            -- well off to one side, out of the usual cone even when it's close.
            SoftTargetInteractArc = 2,
            -- The reach as a hard limit, rather than held to each object's own interaction
            -- distance (left out where the client hasn't got this option).
            SoftTargetInteractRangeIsHard = 1,
        }
        if ns.db.autoLoot then values.autoLootDefault = 1 end
        FrogLib.CVar.Want(ns.POLE, 20, values)
    else
        FrogLib.CVar.Want(ns.POLE, 20, nil)
    end
end

-- While the line's in the water: game sounds up, music and ambience down, so the splash stands out.
function Fishing:Loud(on)
    if on and ns.db.loud then
        FrogLib.CVar.Want(ns.CAST, 30, { Sound_EnableAllSound = 1, Sound_EnableSFX = 1, Sound_SFXVolume = 1,
            Sound_MusicVolume = 0, Sound_AmbienceVolume = 0 })
    else
        FrogLib.CVar.Want(ns.CAST, 30, nil)
    end
end

------------------------------------------------------------------------------
-- Arming: the Interact keys cast, or interact
------------------------------------------------------------------------------

-- mode: "cast" (the keys click the Fishing button), "mouseover" (the keys interact with what's
-- under the mouse) or nil (the keys are Interact again).
local function Arm(mode)
    if InCombatLockdown() then return end
    ClearOverrideBindings(owner)
    armed = nil
    if not mode then return end
    local keys = InteractKeys()
    if #keys == 0 then
        if not keylessSaid then
            keylessSaid = true
            ns.Print("bind the Interact key (Options > Keybindings > Targeting: Interact with Target) to fish with it.")
        end
        return
    end
    if mode == "cast" then Button() end
    for _, key in ipairs(keys) do
        if mode == "cast" then
            SetOverrideBindingClick(owner, true, key, "FrogFishCastButton", "LeftButton")
        else
            SetOverrideBinding(owner, true, key, "INTERACTMOUSEOVER")
        end
    end
    armed = mode
end

-- Works out what the keys should do now, and what game options to have (again, with `settings`:
-- they've just changed).
function Fishing:Update(settings)
    if not ns.db or InCombatLockdown() then return end
    local pole = ns.db.enabled and HasPole() and KnowsFishing()
    if settings and pole and self.pole then self:PoleOptions(true) end
    if pole ~= self.pole then
        self.pole = pole
        self:PoleOptions(pole)
        if pole then self:CheckLure() end
    end
    -- With the line out and the bobber where the game won't pick it out (soft targeting has rules
    -- of its own), the key casts again (a fresh line) or, with recasting off, clicks what's under
    -- the mouse. Not while it's still landing: the key does nothing then.
    local want
    if pole and not SoftTarget() then
        if not channeling then
            want = "cast"
        elseif GetTime() - (castAt or 0) >= SETTLE then
            want = ns.db.recast and "cast" or "mouseover"
        end
    end
    if want ~= armed then Arm(want) end
end

-- The bobber landed beyond the Interact key's reach (or out of the game's view of what's in
-- front of you): said on screen, once per cast, with what the key will do instead.
function Fishing:WarnFar()
    if not (ns.db.warnFar and channeling and self.pole) or SoftTarget() then return end
    local text = ns.db.recast and "Bobber out of reach: press Interact to cast again"
        or "Bobber out of reach: point at it with the mouse and press Interact"
    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage(text, 1, 0.82, 0.3, 1)
    else
        ns.Print(text)
    end
    if ns.db.warnSound then
        pcall(PlaySound, SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master")
    end
end

function Fishing:CheckLure()
    if not ns.db.lure then return end
    local hasLure = GetWeaponEnchantInfo()
    if hasLure then return end
    if lureSaid and GetTime() - lureSaid < LURE_EVERY then return end
    lureSaid = GetTime()
    ns.Print("no lure on your pole.")
end

------------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------------

local function IsFishing(spellID)
    if issecret(spellID) or not spellID then return false end
    return FISHING_RANKS[spellID] or C_Spell.GetSpellName(spellID) == FishingName()
end

function Fishing:Init()
    local f = CreateFrame("Frame")
    for _, event in ipairs({ "PLAYER_EQUIPMENT_CHANGED", "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD",
        "PLAYER_SOFT_INTERACT_CHANGED", "LOOT_CLOSED", "UPDATE_BINDINGS", "SPELLS_CHANGED" }) do
        pcall(f.RegisterEvent, f, event)
    end
    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
    f:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
    f:SetScript("OnEvent", function(_, event, arg1, arg2, arg3)
        local spellID = arg3
        if event == "PLAYER_SOFT_INTERACT_CHANGED" then
            softGUID = arg2 -- the new target (empty or nil: nothing)
        elseif event == "PLAYER_REGEN_DISABLED" then
            -- The last moment the keys can be handed back before combat locks them.
            ClearOverrideBindings(owner)
            armed = nil
            return
        elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
            if not IsFishing(spellID) then return end
            channeling = true
            castAt = GetTime()
            self:Loud(true)
            self:CheckLure()
            -- Once the bobber's had time to land: picked out (the key clicks it), or not (the key
            -- recasts, or clicks what's under the mouse).
            C_Timer.After(SETTLE + 0.05, function()
                self:Update()
                self:WarnFar()
            end)
        elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
            if not IsFishing(spellID) then return end
            channeling = false
            self:Loud(false)
        end
        self:Update()
        -- The bobber vanishing, a loot window closing: soft targets settle a moment later.
        C_Timer.After(0.3, function() self:Update() end)
    end)
    self:Update()
end

local DOES = {
    cast = "the key casts (with the line out: the bobber's not picked out, so it casts again)",
    mouseover = "line out, bobber not picked out: the key clicks what's under the mouse",
}

function Fishing:Status()
    local keys = InteractKeys()
    ns.Print(string.format("%s; pole %s; fishing %s; Interact on %s; %s; something to interact with: %s.",
        ns.db.enabled and "on" or "off", HasPole() and "on" or "off", KnowsFishing() and "known" or "not known",
        #keys > 0 and table.concat(keys, ", ") or "no key",
        DOES[armed] or (channeling and "line out: the key clicks the bobber" or "the key interacts"),
        SoftTarget() and "yes" or "no"))
    -- What the game took for its soft targeting (it may hold the reach below what was asked).
    ns.Print(string.format("reach asked %d, the game has %s; cone %s; reach as a hard limit: %s.", ns.db.range,
        tostring(GetCVar("SoftTargetInteractRange")), tostring(GetCVar("SoftTargetInteractArc")),
        tostring(GetCVar("SoftTargetInteractRangeIsHard"))))
end
