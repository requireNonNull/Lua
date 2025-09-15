local VERSION = "v6.7 alien17"
local NAME = "🦄 Farmy"

-- Version Check
local LATEST_VERSION = "v6.7 alien17"
local versionMessage = ""
if VERSION ~= LATEST_VERSION then
    versionMessage = "⚠️ Outdated: " .. VERSION .. " | Latest: " .. LATEST_VERSION
else
    versionMessage = "✅ Up to date: " .. VERSION
end

-- Game Data (HorseLife)
return {
    Name = "HorseLife",
    PlaceId = 15696848933,
    Status = "<+> Exploit Working <+>",
    LastCheckedDate = "2025-09-15",
    ExploitName = NAME,
    ExploitVersion = VERSION,
    VersionInfo = versionMessage
}
