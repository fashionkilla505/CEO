print("Kaitun Pre Loaded")

local version = 1.0

--config

local defaultScriptConfig = {
    LoadScript = true,
    Key = "obAniEzfJjenrWAHBnZcEgMQXmXnlamD",
    Node = "defaultNode"
}

local scriptConfig


if scriptConfig == nil then
	scriptConfig = defaultScriptConfig
else
	for k, v in pairs(defaultScriptConfig) do
		if scriptConfig[k] == nil then
			scriptConfig[k] = v
		end
	end
end

local scriptKey = scriptConfig.Key
local loadKaitun = scriptConfig.LoadScript
local node = scriptConfig.Node

local urlCFG = {
	namak = "https://raw.githubusercontent.com/fashionkilla505/CEO/refs/heads/main/cfgFolder/NamakCFG.txt",
	preEscanor = "https://raw.githubusercontent.com/fashionkilla505/CEO/refs/heads/main/cfgFolder/PreEscanorCFG.txt",
	postEscanor = "https://raw.githubusercontent.com/fashionkilla505/CEO/refs/heads/main/cfgFolder/PostEscanorCFG.txt",
}	

--- Services

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local unitsArray = loadstring(game:HttpGet("https://pastebin.com/raw/1Uap8mDB"))()
local unitsEvolvedArray = loadstring(game:HttpGet("https://pastebin.com/raw/s1V6KvJn"))()
local OwnedUnitsHandler = require(game:GetService("StarterPlayer").Modules.Interface.Loader.Gameplay.Units.OwnedUnitsHandler)



local data = {
	username = Player.Name,
	stage = game.PlaceId,
	SummerVanguardPity = Player:GetAttribute("SummerVanguardPity")

}

local units = OwnedUnitsHandler:GetOwnedUnits()

local function loadNousigi(cfgURL)

getgenv().Key = scriptKey
getgenv().Config = game:HttpGet(cfgURL)
loadstring(game:HttpGet("https://nousigi.com/loader.lua"))()
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
		
	end
end

print("idk if its working")

print("Player Level: " ..Player:GetAttribute("Level"))
print("Iced tea: " ..Player:GetAttribute("IcedTea"))
