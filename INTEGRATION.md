# Integration contract

Integrate validation at the server boundary; this package cannot safely guess a game's weapon, inventory, economy, vehicle or teleport systems.

## Remote pattern

Call `_G.AntiHack:ValidateRemote(player, "BuyItem", {itemId, amount}, {RateLimit=4, ArgumentTypes={"string","number"}})` before changing state. Validate ownership, price, stock and balance on the server too.

## Combat pattern

Call `_G.AntiHack:ValidateCombat(player, tool, targetModel, serverCalculatedDamage)`. Reject the request when it returns false. Calculate and apply damage entirely on the server.

## Legitimate movement

Before a server-authorized teleport, launch pad, knockback or special ability, call `_G.AntiHack:AuthorizeTeleport(player, "reason", duration)`.

Never expose webhook secrets, DataStore credentials, internal tokens or arbitrary Instances to clients.
