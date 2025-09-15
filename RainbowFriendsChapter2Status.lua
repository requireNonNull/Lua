local VERSION = "0.0.1"
local NAME = "🌈 Rainy"
local URL = "https://raw.githubusercontent.com/requireNonNull/Lua/refs/heads/main/RainbowFriendsChapter2.lua"

-- Version Check
local LATEST_VERSION = "0.0.2"
local versionMessage = ""
if VERSION ~= LATEST_VERSION then
    versionMessage = "⚠️ Outdated: " .. VERSION .. " | Latest: " .. LATEST_VERSION
else
    versionMessage = "✅ Up to date: " .. VERSION
end

-- Game Data (HorseLife)
return {
    Name = "Rainbow Friends Chapter 2",
    PlaceId = 7991339063,
    Status = "<-> Exploit Broken <->",
    LastCheckedDate = "2025-09-15",
    ExploitName = NAME,
    ExploitVersion = VERSION,
    VersionInfo = versionMessage,
    ExploitUrl = URL
}
