local args = {...}

local function Write_Screen(string)
    term.clear()
    term.setCursorPos(1,1)
    term.write(string)
    term.setCursorPos(1,2)
end

if args[1] == "setOrigin" then
    settings.set("x", 0)
    settings.set("y", 0)
    settings.set("z", 0)

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
else
    Write_Screen("Invalid usage!")
end