-- ASKR HUB LOADER
local success, content = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/Netshh/askr-hub/main/source.lua?v=" .. tostring(math.random(1, 100000)))
end)

if not success then
    warn("ASKR HUB: Failed to fetch script - " .. tostring(content))
    return
end

local func, err = loadstring(content)
if not func then
    warn("ASKR HUB: Syntax error in obfuscated script - " .. tostring(err))
    -- If it fails, try the alternative URL format
    local success2, content2 = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/Netshh/askr-hub/refs/heads/main/source.lua")
    end)
    if success2 then
        func, err = loadstring(content2)
        if func then
            func()
            return
        end
    end
    return
end

local s, e = pcall(func)
if not s then
    warn("ASKR HUB: Runtime error - " .. tostring(e))
end
