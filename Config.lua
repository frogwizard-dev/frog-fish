local _, ns = ...

-- The settings controls are FrogLib's (UI.lua); every change calls ns.Refresh().
local UI = FrogLib.UI.Kit({ refresh = function() ns.Refresh() end })

local function Build(page)
    local db = ns.db
    local place = UI.Placer()
    place(UI.Checkbox(page, "One-key fishing with your Interact key", db, "enabled"), 28)
    place(UI.Help(page, "With a fishing pole on, out of combat, your Interact key casts Fishing. When the "
        .. "bobber's out, press it again when it bites: it clicks the bobber. With an NPC or a chest in "
        .. "front of you, it interacts with that instead, as usual.", 400), 48, 4)
    place(UI.Checkbox(page, "Loot catches straight into your bags (while the pole's on)", db, "autoLoot"), 26)
    place(UI.Checkbox(page, "Louder splash: game sounds up, music and ambience down while the line's out",
        db, "loud"), 26)
    place(UI.Checkbox(page, "Recast when the game can't pick out the bobber", db, "recast"), 26)
    place(UI.Help(page, "Sometimes a bobber lands where the Interact key can't reach it. A second after a "
        .. "cast, if it hasn't been picked out, the key throws a fresh line instead. Off: rest the mouse on "
        .. "the bobber and press the key.", 400), 44, 24)
    place(UI.Checkbox(page, "Warn when the bobber lands out of reach", db, "warnFar"), 26)
    place(UI.Checkbox(page, "...with a sound", db, "warnSound"), 26, 20)
    place(UI.Checkbox(page, "Say when the pole has no lure on", db, "lure"), 26)
    place(UI.Stepper(page, "Bobber reach (yards)", 10, 60, 1, db, "range"), 30)
    place(UI.Help(page, "How far away the game picks out the bobber for you. It may stop short of what's "
        .. "asked: a bobber further out still works if you rest the mouse on it and press the key. Your own "
        .. "settings come back when the pole comes off.", 400), 44, 4)
    place(UI.Help(page, "/fish status says what the key does right now, and why.", 400), 20, 4)
end

function ns.ToggleConfig()
    if not ns.window then
        ns.window = UI.Window("FrogFishConfig", "FrogFish", 460, 460, { { "main", "FrogFish", Build } })
        return
    end
    ns.window:SetShown(not ns.window:IsShown())
end

-- Its entry in the game's Options > AddOns list (FrogLib's Options).
FrogLib.Options.Add("FrogFish", ns, {
    open = function()
        if not (ns.window and ns.window:IsShown()) then ns.ToggleConfig() end
    end,
    commands = {
        { "/fish", "open or close the settings" },
        { "/fish on", "one-key fishing on (/fish off to turn it off)" },
        { "/fish status", "what your Interact key does right now, and why" },
    },
})
