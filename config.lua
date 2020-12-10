local args = {...}

if args[1] == "setOrigin" then
    settings.set("x", 0)
    settings.set("y", 0)
    settings.set("z", 0)
    term.clear()
    term.setCursorPos(1,1)
    term.write("Set Origin!!\n")
elseif args[1] == "setWidth" then
    local w = tonumber(args[2])
    if not w then
        term.clear()
        term.setCursorPos(1,1)
        term.write("Invalid width!\n")
    else
        w = math.floor(w)
        settings.set("w", w)
        term.clear()
        term.setCursorPos(1,1)
        term.write("Set width to " .. w.."\n")
    end
elseif args[1] == "setHeight" then
    local h = tonumber(args[2])
    if not h then
        term.clear()
        term.setCursorPos(1,1)
        term.write("Invalid height!\n")
    else
        h = math.floor(h)
        settings.set("h", w)
        term.clear()
        term.setCursorPos(1,1)
        term.write("Set height to " .. h.."\n")
    end
else
    term.clear()
    term.setCursorPos(1,1)
    term.write("Invalid usage!\n")
end