local PeripheralName = "BigReactors-Reactor"
local Reactor
local SettingFile = "Reactor"
local availablePeripherals = peripheral.getNames()
local insert = table.insert

--[[
    Finalizar otimizacao de injecao
    Programar desligamento/ligamento quando niveis energeticos baixo ou alto
    Programar interface
]]


for i,p in ipairs(availablePeripherals) do
    if peripheral.getType(p) == PeripheralName then
        Reactor = peripheral.wrap(p)
    end
end

local function sign(number)
    if number > 0 then return number/number
    elseif number < 0 then return number/-number
    else return 0 end
end

if not Reactor then print("No reactors found.") end

local States = {
    Inactive = 0,
    Active = 1,
    Optimizing = 2,
    Reinitializing = 3,
    Initializing = 4
}

local Window = {
    width, height = term.getSize()
}

local Settings = {
    maxEnergyPercentage = 0.8,
    minEnergyPercentage = 0.2,
    TicksPerCycle = 5,
    TicksPerDraw = 20
}

--variables
local energyCapacity = 0
local minimumEnergy = 0
local maximumEnergy = 0
local maximumFuel = 0
local rodLevels = 0
local rodCount = 0
local state = States.Initializing
local wasAssembled = false


local function Load_Settings()
    -- Load settings
end

local function Initialize() 
    energyCapacity = Reactor.getEnergyCapacity()
    rodCount = Reactor.getNumberOfControlRods()
    minimumEnergy = energyCapacity * Settings.minEnergyPercentage
    maximumEnergy = energyCapacity * Settings.maxEnergyPercentage
    maximumFuel = Reactor.getFuelAmountMax()
    wasAssembled = Reactor.mbIsAssembled()
    rodLevels = Reactor.getControlRodLevel(0)
    state = States.Inactive
end

local function Draw() 
    term.clear()
    term.setCursorPos(1,1)
    print("State " .. state)
    print("Maximum energy levels " .. maximumEnergy)
    print("Minimum energy levels " .. minimumEnergy)
    print("Rod leves at " .. rodLevels)
end -- Display to the user what is happening


--[[
    Optimization works as follows
    First we make sure conditions are ideal
    The we will iterate starting from 100 going to 0 all Insertion levels and measure RF/Mb for each level
    And then choose the highest ratio as our Insertion level.
]]
local function Optimize() -- First optimize
    local initialTime = os.clock()
    local fuel = Reactor.getFuelAmount()
    if fuel <= maximumFuel * 0.05 then
        print("Fuel is too low to run properly.")
        state = States.Inactive
    elseif fuel <= maximumFuel*0.95 then
        print("Fuel is not at high capacity, this will probaly turn out to be innacurate.")
    end
    if not Reactor.getActive() then
        Reactor.setActive(true)
    end
    local file = fs.open("ratios.txt", "w")
    local bestRatio = 0
    local bestLevel = 0
    
    local negativeCount = 0

    Reactor.setAllControlRodLevels(99)
    sleep(30)
    for i=99, 0, -1 do
        Reactor.setAllControlRodLevels(i)
        sleep(4)
        local currentRatio = 0
        local sumF = 0
        local sumR = 0
        local tick = 0

        while tick < 750 do
            sleep(0.05)
            sumF = sumF + Reactor.getFuelConsumedLastTick()
            sumR = sumR + Reactor.getEnergyProducedLastTick()
            tick = tick + 1
            currentRatio = sumR/sumF
        end
        if currentRatio > bestRatio  and currentRatio ~= math.inf then
            bestRatio = currentRatio
            bestLevel = i
            negativeCount = 0
        end
        
        if currentRatio - bestRatio < 0 then negativeCount = negativeCount + 1 end
        file.write(i.."= " .. currentRatio .. " RF/Mb\n")
        file.flush()
        if negativeCount >= 30 then
            break
        end
    end
    Reactor.setAllControlRodLevels(bestLevel)
    print("Took", os.clock()-initialTime/20 ,"ticks.")
    state = States.Inactive
end -- Find the insertion level at which the constraints are respected.

local function Optimize2()
    local initialTime = os.clock()
    local fuel = Reactor.getFuelAmount()
    if fuel <= maximumFuel * 0.05 then
        print("Fuel is too low to run properly.")
        state = States.Inactive
    elseif fuel <= maximumFuel*0.95 then
        print("Fuel is not at high capacity, this will probaly turn out to be innacurate.")
    end
    if not Reactor.getActive() then
        Reactor.setActive(true)
    end
    local file = fs.open("ratios.txt", "w")

    local bestRatio = 0
    local secondBestRatio = 0
    local bestLevel = 99
    local negativeCount = 0
    
    local Steps = 4
    local direction = -1

    Reactor.setAllControlRodLevels(99)
    sleep(30)

    while Steps >= 0 do
        local limit
        if direction < 0 and (bestLevel+direction*(5 + Steps*5)) < 0 then limit = 0 elseif (bestLevel+direction*(5 + Steps*5)) > 100 then limit = 100 else limit = (bestLevel+direction*(5+ Steps*5)) end
        if Steps == 4 then limit = 0 end
        for i=bestLevel, limit, direction*(1+ Steps*2) do
            if i < 0 then 
                i = 0
            end
            if i > 100 then
                i = 100
            end

            local currentRatio = 0
            local sumF = 0
            local sumR = 0
            local tick = 0
            local ticks = 0

            Reactor.setAllControlRodLevels(i)

            sleep(Steps*4 + 1)
            while ticks < 1250 do
                ticks = ticks + 1
                sleep(0.05)
                sumF = sumF + Reactor.getFuelConsumedLastTick()
                sumR = sumR + Reactor.getEnergyProducedLastTick()
                currentRatio = sumR/sumF
            end

            if currentRatio > bestRatio  and currentRatio ~= math.inf then
                secondBestRatio = bestRatio
                bestRatio = currentRatio
                bestLevel = i
                negativeCount = 0
            end
            
            if currentRatio - bestRatio < 0 then negativeCount = negativeCount + 1 end

            file.write(i.."= " .. currentRatio .. " RF/Mb\n")
            file.flush()
            if negativeCount >= 30 then
                break
            end
        end
        direction = sign(bestRatio-secondBestRatio)
        Steps = Steps - 1
    end


    print("bestLevel " .. bestLevel)
    print("Took", os.clock()-initialTime/20 ,"ticks.")
    Reactor.setAllControlRodLevels(bestLevel)
    state = States.Inactive
end

local function Cycle()

end

local function Decide() -- If the reactor should keep running or not.
    local active = Reactor.getActive()
    if Reactor.mbIsAssembled() and not wasAssembled then 
        state = States.Reinitializing
    elseif active then
        if Reactor.getEnergyStored() >= maximumEnergy then
            state = States.Inactive
            Reactor.setActive(false)
        end
    elseif not active then
        if Reactor.getEnergyStored() <= minimumEnergy then
            state = States.Active
            Reactor.setActive(true)
        end
    end
end

local function Main()
    while true do
        sleep(0.05)
        wasAssembled = Reactor.mbIsAssembled()
        if state == States.Initializing then
            Load_Settings()
            Initialize()
        elseif state == States.Reinitializing then
            Initialize()
        elseif state == States.Inactive then
            Decide()
        elseif state == States.Active then
            Decide()
        elseif state == States.Optimizing then
            Optimize2()
        end
        Draw()
    end
end

Main()