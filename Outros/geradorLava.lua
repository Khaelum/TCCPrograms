local MagmaCrucibleCount = 10
local ItemPerCrucible = 4

-- magma crucible
local EnergyNeeded = 40000
local EnergyUsage = 120

local CTicksPerLB = EnergyNeeded/EnergyUsage
local LBCreatedPerTick = 1/CTicksPerLB



-- Dynamo
local EnergyCreated = 120000
local EnergyAugmentation = 15
local EnergyCreation = 120

local finalEnergy = EnergyCreated * (1 + EnergyAugmentation/100)

local DTicksPerLB = finalEnergy/EnergyCreation
local LBUsagePerTick = 1/DTicksPerLB

local CruToDynRatio = LBCreatedPerTick/LBUsagePerTick

local MagmaticDynamoCount = CruToDynRatio*MagmaCrucibleCount

local FinalEnergyCreated = MagmaticDynamoCount * finalEnergy
local FinalEnergyUsed = MagmaCrucibleCount * EnergyNeeded

local EnergyCreatedTick = EnergyCreation*MagmaticDynamoCount
local EnergyUsedTick = EnergyUsage * MagmaCrucibleCount
--- Magma Orb
local ItemsPerTick = ItemPerCrucible*MagmaCrucibleCount/CTicksPerLB

print("USED",FinalEnergyUsed)
print("CREATED",FinalEnergyCreated)
print("ENERGY USAGE PER TICK", EnergyUsedTick)
print("ENERGY CREATED PER TICK", EnergyCreatedTick)
print("LB USED PER TICK PER DYNAMO", LBUsagePerTick)
print("LB CREATED PER TICK PER MACHINE", LBCreatedPerTick)
print("RATIO IS ", LBCreatedPerTick/LBUsagePerTick)
print("NET ENERGY ", FinalEnergyCreated - FinalEnergyUsed)
print("NET ENERGY PER TICK", EnergyCreatedTick - EnergyUsedTick)
print("ITEMS PER TICK REQUIRED ", ItemsPerTick)