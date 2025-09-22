
local version = 1.0
local repoLink = 

-- script config

local defaultScriptConfig = {
    LoadScript = true,
    Key = "",
    Node = "emptyNode",
    webhookUrl = "",
	completedWebhookURL = "",
	levelMax = 11,
	icedTeaMax = 300000,
}

scriptConfig = getgenv().CEOKaitunConfig

if scriptConfig == nil then
	scriptConfig = defaultScriptConfig
else
	for k, v in pairs(defaultScriptConfig) do
		if scriptConfig[k] == nil or scriptConfig[k] == "" then
			scriptConfig[k] = v
		end
	end
end

for i, v in pairs(scriptConfig) do
	print(i.. " value: ", v)
end

-- nousigi cfgs

local CFG = {
	namak = "https://raw.githubusercontent.com/fashionkilla505/CEO/refs/heads/main/cfgFolder/NamakCFG.txt",
	preEscanor = "https://raw.githubusercontent.com/fashionkilla505/CEO/refs/heads/main/cfgFolder/PreEscanorCFG.txt",
	postEscanor = "https://raw.githubusercontent.com/fashionkilla505/CEO/refs/heads/main/cfgFolder/PostEscanorCFG.txt",
}	

--- Services
print("line 40")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
print("line 45")


-- tables


local Game = {}
local Lobby = {
	placeId = 16146832113,
}

local lobbyPlaceId = 16146832113
local timeChamberPlaceId = 18219125606
local gameId = 557855612
local currentPlace

local scriptKey = scriptConfig.Key
local loadKaitun = scriptConfig.LoadScript
local node = scriptConfig.Node
local webhookUrl = scriptConfig.webhookUrl
local completedWebhookURL = scriptConfig.completedWebhookURL
local level = scriptConfig.levelMax
local icedTea = scriptConfig.icedTeaMax


local attributesMax = { 
	Level = level,
	IcedTea = icedTea
}

local escanorFarm = {
	Level11 = false
	Escanor = false
	rerolls = false
}


local brolyFarm = {}

-- key equals it own name tables
local brolyFarmStage = {}
local escanorFarmStage = {}
for key,value in pairs(escanorFarm)
	escanorFarmStage[key] = key
end
for key,value in pairs(brolyFarm)
	brolyFarmStage[key] = key
end




local brolyFarmUsers = {} -- require external table for getting know username for grinding broly

local currentFarm
local currentFarmStage



-- loader funcs

local function loadNousigi(cfgURL)
	if not scriptKey or scriptKey == "" then
		print("No script key found, loading without key.")
		loadstring(game:HttpGet(cfgURL))()
		loadstring(game:HttpGet("https://nousigi.com/loader.lua"))()
	elseif scriptKey then
		getgenv().Key = scriptKey
		loadstring(game:HttpGet(cfgURL))()
		loadstring(game:HttpGet("https://nousigi.com/loader.lua"))()	
	end
end

-- lobby funcs

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

-- copiei tambem
function Lobby.CheckIfExpandUnits()
		task.spawn(function()
			while true do
				local UnitWindowsHandler =
					require(game:GetService("StarterPlayer").Modules.Interface.Loader.Windows.UnitWindowHandler)
				local UnitExpansionEvent =
					game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("UnitExpansionEvent")
				local maxUnits = 100
				local timesBought
				local received = false
				local connection

				UnitExpansionEvent:FireServer("Retrieve")

				connection = UnitExpansionEvent.OnClientEvent:Connect(function(action, data)
					if action == "SetData" then
						maxUnits += 25 * data
						timesBought = data
						connection:Disconnect()
						received = true
					end
				end)

				repeat
					task.wait()
				until received

				local TableUtils = require(game:GetService("ReplicatedStorage").Modules.Utilities.TableUtils)
				local currentUnits = TableUtils.GetDictionaryLength(UnitWindowsHandler._Cache)

				if maxUnits - currentUnits <= 10 then
					if getAttribute("Gold") < (timesBought * 15000 + 25000) then
						WebhookManager.warn(`> *{Player.Name}* doesn't have enough gold to expand unit capacity!`)
					else
						WebhookManager.message(`> *{Player.Name}* is expanding unit capacity`)
						UnitExpansionEvent:FireServer("Purchase")
					end
				end
				task.wait(10)
			end
		end)
end

function Lobby.checkRRShop(shopName)
	local remainingRR

	local StockHandler = require(game:GetService("StarterPlayer").Modules.Gameplay.StockHandler)
	local remainingRR = StockHandler.GetStockData(shopName)["TraitRerolls"]

	return remainingRR
end	

function Lobby.BuyRR(shopName)
	-- copiei mesmo fodase
	local args = {"Purchase",{"TraitRerolls",200}}

	if eventShop == "SummerShop" then
		if Player:GetAttribute("IcedTea") >= 300000 then
			local summerShop = ReplicatedStorage:WaitForChild("Networking"):WaitForChild("Summer"):WaitForChild("ShopEvent")
			summerShop:FireServer(unpack(args))
		else
			print("Not enough iced tea for buying Rerolls")
		end
	end
	return true
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


-- other game funcs

local function validateInfo(typeFarm)
	if typeFarm == escanorFarm then
		if Player:GetAttribute("Level") >= 11 then
			escanorFarm[Level11] = true
		end
		if currentPlace.hasEscanor == true then
			escanorFarm[Escanor] = true
		end
		if currentPlace == Lobby then
			if currentPlace.checkRRShop("SummerShop") == 0 then
				escanorFarm[rerolls] = true
			end
		else
			print("current in game, cant check rerolls shop")
		end
	end
	-- check type farm for broly
end

local function writeFile()
	-- template func just for messing around
end

local function sendWebhook(message, isError, embed)
	local url = webhookUrl


	local success, response = pcall(function()
		return request({
			Url = url,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
			},
			Body = HttpService:JSONEncode({
				["content"] = message .. " Node: ".. node,
			}),
		})
	end)

	return success and response
end

local function completedWebhook(message,isError,embed)
	local url = completedWebhookURL


	local success, response = pcall(function()
		return request({
			Url = url,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
			},
			Body = HttpService:JSONEncode({
				["content"] = message .. " Node: ".. node,
			}),
		})
	end)

	return success and response
end

local function finishAccount(typeFarm)
	local changeAccTxt = `{Player.Name}.txt`

	if typeFarm == escanorFarm then
		completedWebhook(Player.Name, " has Completed Escanor Farm")
		writefile(changeAccTxt, "Completed Escanor")
		-- update spreadsheet or any other source of getting data
		Player:Kick("COMPLETED ESCANOR FARM")
	elseif typeFarm == brolyFarm then
		completedWebhook(Player.Name, " has Completed Broly Farm")
		writefile(changeAccTxt, "Completed Broly")
		-- update spreadsheet or any other source of getting data
		Player:Kick("COMPLETED BROLY FARM")
	end
end

-- main kaitun code

if game.GameId == gameId then

	print("Loading Kaitun For Anime Vanguards")

	local Place 

	if game.PlaceId == lobbyPlaceId then
		print("In Lobby")
	Place = Lobby
	elseif game.PlaceId == timeChamberPlaceId then
		print("In timeChamber, kicking player.")
		sendWebhook("> *" .. Player.Name .. "* entered Timechamber, kicking him.", true)
		Player:Kick("Timechamber not allowed")
	else
		print("In Game")
		Place = Game
	end

	currentPlace = Place

	if loadKaitun == true then

		print("Loading Kaitun")

		if not currentFarm then
			if brolyFarmUsers[player.Username] then
				currentFarm = brolyFarm
			else
				currentFarm	= escanorFarm
			end
		end	

		if currentFarm == escanorFarm then

			validateInfo(escanorFarm)

			-- load cfg according to farm Stage
			if not escanorFarm[Level11] then
				currentFarmStage = escanorFarmStage[Level11]
				loadNousigi(CFG[namak])
			elseif not escanorFarm[Escanor] then
				currentFarmStage = escanorFarmStage[Escanor]
				-- check max Unit slots
				Place.CheckIfExpandUnits()
				loadNousigi(CFG[preEscanor])
			elseif not escanorFarm[rerolls] then
				currentFarmStage = escanorFarmStage[rerolls]
				if Place == Game then
					loadNousigi(CFG[postEscanor])
				else if Place == Lobby then
					task.wait(Place.BuyRR("SummerShop"))
					if Place.checkRRShop("SummerShop") == 0 then
						escanorFarm[rerolls] = true
						finishAccount(currentFarm)
					end
					loadNousigi(CFG[postEscanor])
				end
			else
				finishAccount(currentFarm)
			end

			if Place == Game then
				sendWebhook("> *" .. Player.Name .. "* is farming: " .. currentFarmStage .. " IN GAME", false)
			-- check for level/icedtea quantity max
			elseif Place == Lobby then
				sendWebhook("> *" .. Player.Name .. "* is farming: " .. currentFarmStage .. " IN LOBBY", false)
			end

			if Place == Game then
				local attributeListener = Player.AttributeChanged:Connect(function(attribute)

				if currentFarm[Escanor] == true then
					attributesMax.IcedTea = 300000
				end

				for key, maxAttributeValue in pairs(attributesMax) do
					if attribute == key then
						if Player:GetAttribute(key) >= maxAttributeValue then
							Player:Kick("Reached ".. key .." limit of " .. maxAttributeValue ..", returning to lobby.")
						end
					end

				end
			end)
		end
		--- broly farm

	end
end

print("idk if its working")
