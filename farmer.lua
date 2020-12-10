local term = term
local settings = settings

local slot_count = 16
local bOn = true
local debug = true

local States = {
    Idle = 0,
    Refuel = 1,
    Working = 2,
}

local Directions = {
    Front = 1,
    Right = 2,
    Left = 3,
    Back = 4
}

local Corner = {
    Right = 1,
    Left = 2
}

local Destiny = {
    Forward = 1,
    Backward = -1
}

local Targets = {
    Origin = 1,
    End = -1
}

if not turtle then return end

--Turtle state
local iState = settings.get("state") or 0 --Defaults to IDLE
local iCurrentDirection = settings.get("currentDirection") or 1 -- Defaults to forward
local iCurrentOrientation = settings.get("currentOrientation") or 1 --Defaults to front
local iWantedOrientation = settings.get("wantedOrientation") or 1 -- Defautls to front
local iFuelAmount = turtle.getFuelLevel()
-- position
local iX = settings.get("x") or 0 -- Defaults to origin
local iZ = settings.get("z") or 0 -- Defaults to origin
-- working area
local iWidth = settings.get("w") or 10 -- Defaults to 10
local iHeight = settings.get("h") or 10 -- Defaults to 10
--logging
local fLog

local function log(string)
    if not fLog then
        if not fs.exists("/Logs/") then fs.makeDir("/Logs/") end
        fLog = fs.open("/Logs/" .. os.date():gsub(" ", ""..".txt"), "a")
        if not fLog then return end
    end
    fLog.write(string.."\n")
    fLog:flush()
end
--End Logging

--Saving
local function save_all()
    settings.set("x", iX)
    settings.set("z", iZ)
    settings.set("w", iWidth)
    settings.set("h", iHeight)
    settings.set("state", iState)
    settings.set("currentOrientation", iCurrentOrientation)
    settings.set("currentDirection", iCurrentDirection)
    settings.set("wantedOrientation", iWantedOrientation)
end

local function save_position()
    settings.set("x", iX)
    settings.set("z", iZ)
    settings.set("currentOrientation", iCurrentOrientation)
    settings.set("wantedOrientation", iWantedOrientation)
end

local function save_x()
    settings.set("x", iX)
end

local function save_z()
    settings.set("z", iZ)
end

local function save_state()
    settings.set("state", iState)
end

local function save_current_direction()
    settings.set("currentDirection", iCurrentDirection)
end

local function save_current_orientation()
    settings.set("currentOrientation", iCurrentOrientation)
end

local function save_wanted_orientation()
    settings.set("wantedOrientation", iWantedOrientation)
end
--End Save


--State changers
local function change_wanted_orientation(ori)
    iWantedOrientation = ori
    save_wanted_orientation()
end

local function change_x(offset)
    iX = iX + offset
    save_x()
end

local function change_z(offset)
    iZ = iZ + offset
    save_z()
end

local function change_state(state)
    iState = state
    log("Changed STATE to " .. state)
    save_state()
end

local function change_current_direction(dir)
    iCurrentDirection = dir
    log("Changed DESTINY to " .. dir)
    save_current_direction()
end

local function change_current_orientation(offset)
    iCurrentOrientation = offset
    save_current_orientation()
end

local function finalize()
    fLog:close()
    fLog = nil
    save_all()
end

local function syncronize_state()
    iFuelAmount = turtle.getFuelLevel()
end

local function check_fuel()
    syncronize_state()
    if iFuelAmount <= 0 then
        for i = 1, slot_count + 1 do
            if turtle.refuel(i) then 
                change_state(States.Working)
            end
        end
        change_state(States.Refuel)
        return false
    end
end

--Movement

local function at_corner()
    if iX == 0 then return Corner.Left end
    if iX == iWidth then return Corner.Right end
    return 0
end

local function at_origin()
    if iX == 0 and iZ == 0 then return Targets.Origin end
    if iX == iWidth and iZ == iHeight then return Targets.End end
    return 0
end

local function work_and_move()
    local inspect = turtle.inspectDown()
    if inspect and inspect.state and inspect.state.age and inspect.state.age == 7 then
        turtle.digDown()
    end
    if iFuelAmount <= 0 then
        if not check_fuel() then return end
    end
    if iCurrentOrientation == Directions.Front then
        change_x(1)
    elseif iCurrentOrientation == Directions.Back then
        change_x(-1)
    elseif iCurrentOrientation == Directions.Left then
        change_z(1)
    elseif iCurrentOrientation == Directions.Right then
        change_z(-1)
    end
    turtle.forward()
end

local function change_orientation()
    local Left
    local Right
    if iWantedOrientation < iCurrentOrientation then
        Left = iCurrentOrientation - iWantedOrientation
        Right = 4 - Left
    else
        Right = iWantedOrientation - iCurrentOrientation
        Left = 4 - Right
    end
    if not Left or not Right then
        log("Unexpected situation!")
        return
    end
    if Left < Right then
        for i = 1, Left do
            turtle.turnLeft()
            change_current_orientation(-1)
        end
    else
        for i = 1, Right do
            turtle.turnLeft()
            change_current_orientation(1)
        end
    end
end

local function proper_orientation()
    -- Quando não em canto, forward
    -- Quando em canto, se bCurrentDirection = 1, se z é impar Left se z é par Back
    if at_origin() == -1 then
        change_state(States.Idle)
        iCurrentDirection = iCurrentDirection * -1
    else
        local bZ = (iZ % 2 == 0) -- If Z is a mean number
        if iCurrentDirection == Destiny.Forward then
            if at_corner() == Corner.Left then
                if bZ then
                    change_wanted_orientation(Directions.Left)
                else
                    change_wanted_orientation(Directions.Front)
                end
            elseif at_corner() == Corner.Right then
                if bZ then
                    change_wanted_orientation(Directions.Back)
                else
                    change_wanted_orientation(Directions.Left)
                end
            end
        elseif iCurrentDirection == Destiny.Backward then
            if at_corner() == Corner.Left then
                if bZ then
                    change_wanted_orientation(Directions.Front)
                else
                    change_wanted_orientation(Directions.Right)
                end
            elseif at_corner() == Corner.Right then
                if bZ then
                    change_wanted_orientation(Directions.Right)
                else
                    change_wanted_orientation(Directions.Back)
                end
            end
        end
    end
end

local function main()
    while(bOn) do
        if debug then
            term.clear()
            term.setCursorPos(1,1)
            print("STATE IS " .. iState)
            print("POSITION X " .. iX .. " Z " .. iZ)
            print("Fuel level " .. iFuelAmount)
            print("CURRENT ORIENTATION " .. iCurrentOrientation)
            print("WANTED ORIENTATION " .. iWantedOrientation)
        end
        if iState == States.Working then
            proper_orientation()
            change_orientation()
            work_and_move()
        elseif iState == States.Refuel then
            sleep(1) -- Waits 1 Second per refuel attempt
            check_fuel()
        elseif iState == States.Idle then
            sleep(5) -- Waits 20 seconds when IDLE
            change_state(States.Working)
        end
    end
end


main()
--[[
    Set-up process takes:
    origin (initial turtle position)
    rect width
    rect height

    stores information so as to restart what it was doing before in case of disruptions

]]