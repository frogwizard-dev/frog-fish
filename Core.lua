local ADDON, ns = ...

-- FrogFish: one key to fish. With a fishing pole on, your Interact key casts Fishing; when the
-- bobber's out, the same key clicks it (the game's own interact, on the bobber as its soft
-- target). Each press is one action of yours: the addon only decides which, before you press.
-- Fishing.lua does the work; this file holds the settings and the game options it changes.

ns.defaults = {
    enabled = true,
    autoLoot = true,  -- loot catches straight into your bags while the pole's on
    loud = true,      -- game sounds up, music and ambience down, while the line's in the water
    lure = true,      -- say when the pole has no lure on
    range = 60,       -- how far away (yards) the bobber can be clicked, while the pole's on (the most)
    recast = true,    -- a bobber the game won't pick out: the key casts again (off: click it with the mouse)
    warnFar = true,   -- say on screen when the bobber lands out of the Interact key's reach
    warnSound = false, -- ... with a sound
    -- Game options as they were before FrogLib's CVar changed them for fishing (or FrogInteract
    -- for the interact key), so they come back even after a crash: { [cvar] = original }.
    cvars = {},
}

ns.Print = FrogLib.Util.Printer("FrogFish", "4fb0d8")

-- The game options it changes are FrogLib's CVar's to keep and put back: "FrogFish:pole" (layer 20)
-- while the pole's on, "FrogFish:cast" (30) while the line's out, both over FrogInteract's (10).
ns.POLE, ns.CAST = "FrogFish:pole", "FrogFish:cast"

function ns.Refresh()
    ns.Fishing:Update(true)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName == ADDON then
        FrogFishDB = FrogFishDB or {}
        -- 0.2: the reach goes to the most the game takes, for anyone still on the old default.
        if not FrogFishDB.v2 then
            if FrogFishDB.range == 30 then FrogFishDB.range = nil end
            FrogFishDB.v2 = true
        end
        FrogLib.Util.CopyDefaults(ns.defaults, FrogFishDB)
        ns.db = FrogFishDB
        -- 0.1's own record of what it changed ({ [group] = { [cvar] = original } }): put back.
        if type(ns.db.saved) == "table" then
            for _, group in pairs(ns.db.saved) do
                for name, value in pairs(group) do pcall(SetCVar, name, value) end
            end
            ns.db.saved = nil
        end
        -- Anything left changed by the last session (a crash, a logout with the line out) goes
        -- back first.
        FrogLib.CVar.Register("FrogFish", ns.db.cvars)
    elseif event == "PLAYER_LOGIN" then
        ns.Fishing:Init()
    end
end)

SLASH_FROGFISH1 = "/fish"
SLASH_FROGFISH2 = "/frogfish"
SlashCmdList.FROGFISH = function(text)
    local command = strtrim(text or ""):lower()
    if command == "on" or command == "off" then
        ns.db.enabled = command == "on"
        ns.Refresh()
        ns.Print(ns.db.enabled and "one-key fishing on." or "one-key fishing off.")
    elseif command == "status" then
        ns.Fishing:Status()
    else
        ns.ToggleConfig()
    end
end

function FrogFish_OnCompartmentClick() ns.ToggleConfig() end
