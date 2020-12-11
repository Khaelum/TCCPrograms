local term = term
local settings = settings

local settingsFileName = "farmer"

local slot_count = 16
local bOn = true
local debug = false

-- Falta so guardar num bau os carrots :)
settings.load(settingsFileName)

local States = {
    Idle = 0,
    Refuel = 1,
    Working = 2,
}

local Directions = {
    Front = 1,
    Right = 2,
    Back = 3,
    Left = 4
    
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
local sItemFarmed = settings.get("farmed") or "minecraft:carrot"
-- position
local iX = settings.get("x") or 0 -- Defaults to origin
local iZ = settings.get("z") or 0 -- Defaults to origin
-- working area
local iWidth = settings.get("w") or 9 -- Defaults to 10
local iHeight = settings.get("h") or 9 -- Defaults to 10
-- Inventory
local minimum_in_hand = iWidth*iHeight

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
    settings.save()
end

local function save_position()
    settings.set("x", iX)
    settings.set("z", iZ)
    settings.set("currentOrientation", iCurrentOrientation)
    settings.set("wantedOrientation", iWantedOrientation)
    settings.save(settingsFileName)
end

local function save_x()
    settings.set("x", iX)
    settings.save(settingsFileName)
end

local function save_z()
    settings.set("z", iZ)
    settings.save(settingsFileName)
end

local function save_state()
    settings.set("state", iState)
    settings.save(settingsFileName)
end

local function save_current_direction()
    settings.set("currentDirection", iCurrentDirection)
    settings.save(settingsFileName)
end

local function save_current_orientation()
    settings.set("currentOrientation", iCurrentOrientation)
    settings.save(settingsFileName)
end

local function save_wanted_orientation()
    settings.set("wantedOrientation", iWantedOrientation)
    settings.save(settingsFileName)
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
    settings.get("x")
end

local function change_z(offset)
    iZ = iZ + offset
    save_z()
end

local function change_state(state)
    iState = state
    save_state()
end

local function change_current_direction(dir)
    iCurrentDirection = dir
    save_current_direction()
end

local function change_current_orientation(offset)
    iCurrentOrientation = iCurrentOrientation + offset
    if iCurrentOrientation <= 0 then iCurrentOrientation = 4 end
    if iCurrentOrientation >= 5 then iCurrentOrientation = 1 end
    save_current_orientation()
end

local function syncronize_state()
    iFuelAmount = turtle.getFuelLevel()
end

local function check_fuel()
    syncronize_state()
    if iFuelAmount <= 0 then
        for i = 1, slot_count do
            turtle.select(i)
            if turtle.refuel() then 
                change_state(States.Working)
            end
        end
        change_state(States.Refuel)
        return false
    else
        change_state(States.Working)
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

--Inventory

local function select_item(string)
    for i=1, slot_count do
        local detail = turtle.getItemDetail(i)
        if detail and detail.name == string then
            return turtle.select(i)
        end
    end
end

local function work_and_move()
    local b, inspect = turtle.inspectDown()
    if b and inspect.state and inspect.state.age and inspect.state.age == 7 then
        turtle.digDown()
    end
    b, inspect = turtle.inspectDown()
    if not b then
        select_item(sItemFarmed)
        turtle.placeDown()
    end
    if iFuelAmount <= 0 then
        if not check_fuel() then return end
    end
    if turtle.forward() then
        iFuelAmount = iFuelAmount - 1
        if iCurrentOrientation == Directions.Front then
            change_x(1)
        elseif iCurrentOrientation == Directions.Back then
            change_x(-1)
        elseif iCurrentOrientation == Directions.Left then
            change_z(1)
        elseif iCurrentOrientation == Directions.Right then
            change_z(-1)
        end
    end
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
        return
    end
    if Left < Right then
        for i = 1, Left do
            turtle.turnLeft()
            change_current_orientation(-1)
        end
    else
        for i = 1, Right do
            turtle.turnRight()
            change_current_orientation(1)
        end
    end
end

local function proper_orientation()
    -- Quando não em canto, forward
    -- Quando em canto, se bCurrentDirection = 1, se z é impar Left se z é par Back
    local bZ = not (iZ % 2 == 0) -- If Z is a mean number
    if iCurrentDirection == Destiny.Forward then
        if at_origin() == -1 then
            change_state(States.Idle)
            change_current_direction(iCurrentDirection * -1)
        else
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
        end
    elseif iCurrentDirection == Destiny.Backward then
        if at_origin() == 1 then
            change_state(States.Idle)
            change_current_direction(iCurrentDirection * -1)
        else
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

local function inventory_full()
    local available_slots = 16
    for i = 1, slot_count do
        local item = turtle.getItemDetail(i)
        if item then
            if item.name == sItemFarmed then
                if item.count >= 64 then
                    available_slots = available_slots - 1
                end
            else
                available_slots = available_slots - 1
            end
        end
    end
    if available_slots > 0 then return false else return true end
end

local function store_items()
    if at_origin() == Targets.Origin then
        local count = 0
        for i = 1, slot_count do
            turtle.select(i)
            local item = turtle.getItemDetail(i)
            if item and item.name and item.name == sItemFarmed then
                count = count + item.count
                if count > minimum_in_hand then
                    local amt = count - minimum_in_hand
                    if amt > item.count then amt = item.count end
                    if turtle.dropUp(amt) then count = count - amt end
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
            print("Fuel level " .. iFuelAmount)
            print("CURRENT ORIENTATION " .. iCurrentOrientation)
            print("WANTED ORIENTATION " .. iWantedOrientation)
            print("DESTINY IS " .. iCurrentDirection)
            print("AT CORNER " .. at_corner())
            print("BZ is " .. tostring(not (iZ % 2 == 0)))
            print("POSITION X " .. iX .. " Z " .. iZ)
            sleep(0.5)
        end
        if iState == States.Working then
            proper_orientation()
            change_orientation()
            work_and_move()
        elseif iState == States.Refuel then
            sleep(5) -- Waits 1 Second per refuel attempt
            check_fuel()
        elseif iState == States.Idle then
            sleep(300) -- Waits 5 min when IDLE
            store_items()
            if not inventory_full() then
                change_state(States.Working)
            end
        end
    end
end


main()
