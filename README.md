# AntiHack

Standalone server-authoritative Roblox/Luau anti-cheat package for BravoBuilds. This repository is independent of BravoHack.

## Install

1. Install Rojo.
2. Run `rojo serve default.project.json` from the repository root.
3. Connect Roblox Studio to Rojo and sync.
4. Keep the server scripts in `ServerScriptService` and the client heartbeat in `StarterPlayerScripts`.

## Security model

The client is untrusted. Client heartbeats are only a weak liveness signal; they never decide bans, damage, risk, exemptions, or moderation permissions. Validate gameplay remotes on the server and calculate combat damage on the server.

## Important

Automatic permanent bans are disabled by default. Tune thresholds for your game before enabling punishment. No client/server anti-cheat can guarantee detection of every executor; prefer server-authoritative game design.
