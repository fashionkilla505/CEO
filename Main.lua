
local version = 1.0

--config

local defaultScriptConfig = {
    LoadScript = true,
    Key = "obAniEzfJjenrWAHBnZcEgMQXmXnlamD",
    Node = "defaultNode",
    webhookUrl = "",
	levelMax = 11,
	icedTeaMax = 300000,
}

local brolyFarm = {}

scriptConfig = getgenv().kaitunConfig
if scriptConfig == nil then
	scriptConfig = defaultScriptConfig
else
	for k, v in pairs(defaultScriptConfig) do
		if scriptConfig[k] == nil then
			scriptConfig[k] = v
		end
	end
end

for i, v in pairs(scriptConfig) do
	print(i.. " value: ", v)
end

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

-- tables

local Game = {}
local Lobby = {
	placeId = 16146832113,
}
local lobbyPlaceId = 16146832113
local gameId = 5578556129

local scriptKey = scriptConfig.Key
local loadKaitun = scriptConfig.LoadScript
local node = scriptConfig.Node
local level = scriptConfig.levelMax
local icedTea = scriptConfig.icedTeaMax

local attributesMax = { 
	Level = level,
	IcedTea = icedTea
}


local data = {
	username = Player.Name,
	stage = game.PlaceId,
	SummerVanguardPity = Player:GetAttribute("SummerVanguardPity")

}


local function loadNousigi(cfgURL)

if scriptKey then
	getgenv().Key = scriptKey
	loadstring(game:HttpGet(cfgURL))()
	loadstring(game:HttpGet("https://nousigi.com/loader.lua"))()
elseif not scriptKey or scriptKey == "" then
	print("No script key found, loading without key.")
	loadstring(game:HttpGet(cfgURL))()
	loadstring(game:HttpGet("https://nousigi.com/loader.lua"))()
	end
end

local function webhookMessage (msg)

end

function Lobby.hasEscanor()
	local OwnedUnitsHandler = require(game:GetService("StarterPlayer").Modules.Interface.Loader.Gameplay.Units.OwnedUnitsHandler)
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

-- In-game functions (works only on Tomer Defense Game Base)

local Game = {
	getStage = function(): string
		local gameHandler = require(ReplicatedStorage.Modules.Gameplay.GameHandler)
		return gameHandler.GameData.Stage
	end,

	hasEscanor = function(): boolean
		local UnitWindows = require(game:GetService("StarterPlayer").Modules.Interface.Loader.Windows.UnitWindowHandler)
		local units = UnitWindows._Cache

		for attempt = 1, 20 do
			if units ~= nil then
				for _, unit in pairs(units) do
					if (unit.ID == 270) or (unit.Identifier == 270) then
						return true
					end
				end
			end
		end

		return false
	end,
}


-- main kaitun code

if game.GameId == gameId then

	print("Loading Kaitun For Anime Vanguards")
	print("Player Level: " ..Player:GetAttribute("Level"))
	print("Iced tea: " ..Player:GetAttribute("IcedTea"))

	local place 
	if game.PlaceId == lobbyPlaceId then
		print("In Lobby")
	place = Lobby
	else
		print("In Game")
		place = Game
	end

	if loadKaitun == true then

		print("Loading Kaitun")

		if place == Game then
		local attributeListener = Player.AttributeChanged:Connect(function(attribute)
			for key, maxAttributeValue in pairs(attributesMax) do
				if attribute == key then
					if Player:GetAttribute(key) >= maxAttributeValue then
						Player:Kick("Reached ".. key .." limit of " .. maxAttributeValue ..", returning to lobby.")
					end
				end

			end
		end)
	end	
		if Player:GetAttribute("Level") < 11 then
			loadNousigi(urlCFG.namak)
			print("Loaded Namak CFG")
		elseif not place.hasEscanor() and Player:GetAttribute("Level") >= levelMax then
			loadNousigi(urlCFG.preEscanor)
			print("Loaded Pre Escanor CFG")
		elseif place.hasEscanor() and Player:GetAttribute("IcedTea") < icedTeaMax then
			loadNousigi(urlCFG.postEscanor)
			print("Loaded Post Escanor CFG")
		elseif place.hasEscanor() and Player:GetAttribute("IcedTea") >= icedTeaMax then
			if place == Game then
				Player:Kick("Got 300k iced tea, summon or buy rerolls.")
			end

			--function for buying 300rrs
			print("Have Escanor and 300k iced tea, not loading any cfg.")
		end
	end 
end



print("idk if its working")
