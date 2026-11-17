# FrogFish

## 0.2.2

- With the line out, only your bobber counts as what's in front of you: an NPC or a mailbox at a dock no longer gets the key instead.
- What's in front of you and loot windows closing are only listened to with a pole on.
- Shared code (FrogLib 1.12.0): see its notes for the rest of what's fixed.

## 0.2.1

- That long, all-round reach is only on while your line's in the water. Before, a vendor behind you or across the river could be picked out instead, and the key would talk to them rather than cast.

## 0.2.0

- The Interact key's reach for the bobber is now as far as it goes (60 yards, up from 30), so more casts can be clicked with the key. If you'd set your own reach, it's kept.
- **Out of reach warning**: when your bobber lands where the Interact key can't get it, a message on screen says so, and what the key will do instead (cast again, or click it with the mouse). A sound can go with it. Both in the settings.
- The icon over the bobber now shows more reliably: the game counted the bobber as a less important object and could leave its icon off.

## 0.1.0

- First version: one-key fishing. With a fishing pole on, out of combat, your **Interact** key casts Fishing; when the bobber bites, press it again and it clicks the bobber. With an NPC or a chest in front of you it still interacts with that, and in combat it's your ordinary Interact key.
- While the pole's on: catches loot straight into your bags, and the bobber can be clicked from as far as a cast lands (both can be changed). While the line's out, game sounds go up and music and ambience down, so the splash stands out. Your own settings come back when the pole comes off, even after a crash.
- The bobber can be clicked wherever it lands in front of you, even well off to one side (the game's usual cone for the Interact key is narrow).
- A bobber that lands where the game won't pick it out for the Interact key: a second after the cast, the key throws a fresh line instead. (Or, with that off in the settings, rest the mouse on the bobber and press the key.)
- Works alongside FrogInteract: its fishing settings sit on top of FrogInteract's while the pole's on, and FrogInteract's come back when it comes off.
- Says when your pole has no lure on. `/fish status` says what the key does right now, and why, and how far the game lets it reach.
