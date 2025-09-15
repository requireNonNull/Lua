-- 🦄 Farmy Exploit Info
local VERSION = "v6.7 alien17"
local NAME = "🦄 Farmy"

-- Version Check
local LATEST_VERSION = "v6.7 alien17" -- change this when new version comes
local versionMessage = ""
if VERSION ~= LATEST_VERSION then
    versionMessage = "⚠️ Outdated: " .. VERSION .. " | Latest: " .. LATEST_VERSION
else
    versionMessage = "✅ Up to date: " .. VERSION
end

-- Game Data
return {
    Name = "HorseLife",
    Status = "<+> Exploit Working <+>",
    LastCheckedDate = "2025-09-15",
    ExploitName = NAME,
    ExploitVersion = VERSION,
    VersionInfo = versionMessage -- add this so UI can show it under title
}
