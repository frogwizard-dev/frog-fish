local _, ns = ...
local UI = ns.UI

local function Build(p)
    local db = ns.db
    local place = UI.Placer()
    place(UI.Checkbox(p, "One-key fishing with your Interact key",
        function() return db.enabled end, function(v) db.enabled = v end), 28)
    place(UI.Help(p, "With a fishing pole on, out of combat, your Interact key casts Fishing. When the "
        .. "bobber's out, press it again when it bites: it clicks the bobber. With an NPC or a chest in "
        .. "front of you, it interacts with that instead, as usual.", 400), 48, 4)
    place(UI.Checkbox(p, "Loot catches straight into your bags (while the pole's on)",
        function() return db.autoLoot end, function(v) db.autoLoot = v end), 26)
    place(UI.Checkbox(p, "Louder splash: game sounds up, music and ambience down while the line's out",
        function() return db.loud end, function(v) db.loud = v end), 26)
    place(UI.Checkbox(p, "Recast when the game can't pick out the bobber",
        function() return db.recast end, function(v) db.recast = v end), 26)
    place(UI.Help(p, "Sometimes a bobber lands where the Interact key can't reach it. A second after a "
        .. "cast, if it hasn't been picked out, the key throws a fresh line instead. Off: rest the mouse on "
        .. "the bobber and press the key.", 400), 44, 24)
    place(UI.Checkbox(p, "Say when the pole has no lure on",
        function() return db.lure end, function(v) db.lure = v end), 26)
    place(UI.Stepper(p, "Bobber reach (yards)", 10, 40, 1, function() return db.range end,
        function(v) db.range = v end), 30)
    place(UI.Help(p, "How far away the game picks out the bobber for you. It may stop short of what's "
        .. "asked: a bobber further out still works if you rest the mouse on it and press the key. Your own "
        .. "settings come back when the pole comes off.", 400), 44, 4)
    place(UI.Help(p, "/fish status says what the key does right now, and why.", 400), 20, 4)
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
