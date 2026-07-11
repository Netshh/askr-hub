-- ASKR HUB LOADER
-- Users execute this one loader. It routes supported games to custom scripts,
-- and every unsupported game to the universal hub.

local REPO_BASE = "https://raw.githubusercontent.com/Netshh/askr-hub/main"
local CACHE_BUST = "?v=" .. tostring(math.random(1, 100000))

-- PlaceId -> custom script metadata.
-- Use string keys so large Roblox place ids are not affected by number handling.
local CUSTOM_GAMES = {
    ["93978595733734"] = {
        Name = "Violence District",
        Path = "games/violence_district.lua",
    },
    ["127794225497302"] = {
        Name = "Abyss",
        Path = "games/abyss.lua",
    },
    ["79268393072444"] = {
        Name = "Sell Lemons",
        Path = "games/sell_lemons.lua",
    },
}

local UNIVERSAL_SCRIPT = {
    Name = "ASKR HUB | Universal",
    Path = "askrhub-universal.lua",
}

local function fetch(url)
    local success, content = pcall(function()
        return game:HttpGet(url .. CACHE_BUST)
    end)

    if success and content and #content > 100 then
        return content
    end

    local fallbackSuccess, fallbackContent = pcall(function()
        return game:HttpGet(url)
    end)

    if fallbackSuccess and fallbackContent and #fallbackContent > 100 then
        return fallbackContent
    end

    return nil
end

local function execute(code, name)
    local func, compileError = loadstring(code)
    if not func then
        warn("ASKR HUB: Syntax error in " .. name .. " - " .. tostring(compileError))
        return false
    end

    local runSuccess, runtimeError = pcall(func)
    if not runSuccess then
        warn("ASKR HUB: Runtime error in " .. name .. " - " .. tostring(runtimeError))
        return false
    end

    return true
end

local placeId = tostring(game.PlaceId)
local targetScript = CUSTOM_GAMES[placeId] or UNIVERSAL_SCRIPT
local targetUrl = REPO_BASE .. "/" .. targetScript.Path

if CUSTOM_GAMES[placeId] then
    print("[ASKR HUB] Supported custom game detected: " .. targetScript.Name)
else
    print("[ASKR HUB] No custom script for PlaceId " .. placeId .. ". Loading universal hub.")
end

print("[ASKR HUB] Loading: " .. targetScript.Name)

local source = fetch(targetUrl)
if not source then
    warn("ASKR HUB: Failed to download " .. targetScript.Name .. " from " .. targetUrl)
    return
end

execute(source, targetScript.Name)
