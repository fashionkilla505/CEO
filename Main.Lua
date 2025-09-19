print("Local Main Executed!")

--not const vars

local scriptKey = "obAniEzfJjenrWAHBnZcEgMQXmXnlamD"
local loadKaitun = false

--- Services

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local unitsArray = loadstring(game:HttpGet("https://pastebin.com/raw/1Uap8mDB"))()
local unitsEvolvedArray = loadstring(game:HttpGet("https://pastebin.com/raw/s1V6KvJn"))()
local OwnedUnitsHandler = require(game:GetService("StarterPlayer").Modules.Interface.Loader.Gameplay.Units.OwnedUnitsHandler)

local urlCFG = {
	namak = "https://paste.dotwired.org/Namak.txt",
	driedLake = "https://paste.dotwired.org/Dried%20Lake.txt",
	goku = "",
}	

local data = {
	username = Player.Name,
	stage = game.PlaceId,
	SummerVanguardPity = Player:GetAttribute("SummerVanguardPity")

}

local units = OwnedUnitsHandler:GetOwnedUnits()

local function loadNousigi(cfgURL,custom,cfg,cfgvalue)

if custom then
game:HttpGet(cfgURL)
getgenv().Config[cfg] = cfgvalue
print(getgenv().Config[cfg])
else
game:HttpGet(cfgURL)
end


end

local function hasEscanor()
		local units = OwnedUnitsHandler:GetOwnedUnits()
		for attempt = 1, 20 do
			if units ~= nil then
				for _, unit in pairs(units) do
					if (unit.ID == 270) or (unit.Identifier == 270) then
						-- Has escanor
						return true
					else
					end
				end
			end
		end
	return false
end



if loadKaitun then
	if Player:GetAttribute("Level") < 11 then
	loadNousigi(urlCFG.namak)
	end
	if not hasEscanor() and Player:GetAttribute("Level") >= 11 then
		loadNousigi(urlCFG.driedLake,true,getgenv().Config["Summoner"]["Auto Summon Summer"],true)

	end
end

loadNousigi(urlCFG.driedLake,true,{"Summoner","Auto Summon Summer"},true)

print("Player Level: " ..Player:GetAttribute("Level"))
print("Iced tea: " ..Player:GetAttribute("IcedTea"))
