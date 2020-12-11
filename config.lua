local args = {...}

local function Write_Screen(string)
    term.clear()
    term.setCursorPos(1,1)
    term.write(string)
    term.setCursorPos(1,2)
end

if args[1] == "setOrigin" then
    settings.set("x", 0)
    settings.set("z", 0)
    Write_Screen("Set current position as origin!\n")
elseif args[1] == "setWidth" then
    local w = tonumber(args[2])
    if not w then
        Write_Screen("Invalid width!\n")
    else
        w = math.floor(w)
        settings.set("w", w)
       Write_Screen("Set width to " .. w.."\n")
    end
elseif args[1] == "setHeight" then
    local h = tonumber(args[2])
    if not h then
        Write_Screen("Invalid height!\n")
    else
        h = math.floor(h)
        settings.set("h", h)
        Write_Screen("Set height to " .. h.."\n")
    end
elseif args[1] == "reset" then
    settings.set("x", 0)
    settings.set("z", 0)
    settings.set("w", 9)
    settings.set("h", 9)
    settings.set("state", 0)
    settings.set("currentOrientation", 1)
    settings.set("currentDirection", 1)
    settings.set("wantedOrientation", 1)
    Write_Screen("Reset!!")
else
    if args[1] and not args[2] then
        local v = settings.get(args[1])
        if v then 
            Write_Screen("value for " .. args[1] .. " is " .. v)
        end
    elseif args[2] then
        local n = tonumber(args[2])
        local bT = args[2]:lower():match("true") == "true"
        local bF = args[2]:lower():match("false") == "false"
        settings.set(args[1], args[1])
        if n then settings.set(args[1], n) end
        if bT then settings.set(args[1], true) end
        if bF then settings.set(args[1], false) end
        if not (n or bT or bF) then settings.set(args[1], args[1]) end
        Write_Screen("Set " .. args[1] .. " to " .. tostring(settings.get(args[1])))
    end
end

settings.save("farmer")