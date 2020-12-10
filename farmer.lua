local term = term
local settings = settings


local iX = settings.get("x")
local iY = settings.get("y")
local iZ = settings.get("z")

local bFirstTime = false

if not iX or iY or iZ then bFirstTime = true end




local function set_up()
    term.clear()
    term.setCursorPos(1,1)
    term.write("Input farming area length\n")
    local input = read()
    input = tonumber(input)
    if input then input = math.ceil(input) else set_up() end
end


set_up()

--[[
    Set-up process takes:
    origin (initial turtle position)
    rect width
    rect height

    stores information so as to restart what it was doing before in case of disruptions

]]