local version = 2.0

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

-- nousigi cfgs

local CFG = {
	namak = "https://raw.githubusercontent.com/fashionkilla505/CEO/refs/heads/main/cfgFolder/levelFarmCFG.txt",
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
local Timechamber = {
	placeId = 18219125606,
}

local lobbyPlaceId = 16146832113
local timeChamberPlaceId = 18219125606
local vanguardsGameId = 5578556129
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
	IcedTea = icedTea,
}

local escanorFarm = {
	Level11 = false,
	Escanor = false,
	rerolls = false,
}

local brolyFarm = {}

-- key equals it own name tables
local brolyFarmStage = {}
local escanorFarmStage = {}
for key, value in pairs(escanorFarm) do
	escanorFarmStage[key] = key
end
for key, value in pairs(brolyFarm) do
	brolyFarmStage[key] = key
end

local brolyFarmUsers = {} -- require external table for getting know username for grinding broly

local currentFarm
local currentFarmStage

--webhook
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
				["content"] = "Node: " .. node .. "\n" .. message,
			}),
		})
	end)

	return success and response
end

local function completedWebhook(message, isError, embed)
	local url = completedWebhookURL

	local success, response = pcall(function()
		return request({
			Url = url,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
			},
			Body = HttpService:JSONEncode({
				["content"] = "Node: " .. node .. "\n" .. message,
			}),
		})
	end)

	return success and response
end

-- loader funcs

local function loadNousigi(cfgURL)
	print("Loading Nousigi")
	if not scriptKey or scriptKey == "" then
		print("No script key found, loading without key.")
		loadstring(game:HttpGet(cfgURL))()
		loadstring(game:HttpGet("https://nousigi.com/loader.lua"))()
	elseif scriptKey then
		getgenv().Key = scriptKey
		loadstring(game:HttpGet(cfgURL))()
		loadstring(game:HttpGet("https://nousigi.com/loader.lua"))()
	end
	print("Should nousigi be loaded")
end

-- lobby funcs

function Lobby.hasEscanor()
	local OwnedUnitsHandler =
		require(game:GetService("StarterPlayer").Modules.Interface.Loader.Gameplay.Units.OwnedUnitsHandler)
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
				if Player:GetAttribute("Gold") < (timesBought * 15000 + 25000) then
					sendWebhook(`> *{Player.Name}* doesn't have enough gold to expand unit capacity!`)
				else
					sendWebhook(`> *{Player.Name}* is expanding unit capacity`)
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
	local args = { "Purchase", { "TraitRerolls", 200 } }

	if shopName == "SummerShop" then
		if Player:GetAttribute("IcedTea") >= 300000 then
			local summerShop =
				ReplicatedStorage:WaitForChild("Networking"):WaitForChild("Summer"):WaitForChild("ShopEvent")
			summerShop:FireServer(unpack(args))
		else
			print("Not enough iced tea for buying Rerolls")
		end
	end
	return true
end

function Lobby.claimNewPlayerRewards()
    local newPlayerRewardsRemote = game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("NewPlayerRewardsEvent")
    for i = 1, 7 do
        local args = {
            "Claim",
            i
        }
        newPlayerRewardsRemote:FireServer(unpack(args))
        wait(1) -- Pequena pausa para garantir que o servidor processe cada reivindicação
    end
end

-- In-game functions (works only on Tomer Defense Game Base)

local Game = {
	getStage = function()
		local gameHandler = require(ReplicatedStorage.Modules.Gameplay.GameHandler)
		return gameHandler.GameData.Stage
	end,

	hasEscanor = function()
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

function teleportToLobby(currentPlace)
	if currentPlace == Game then
		local teleportEvent = game:GetService("ReplicatedStorage").Networking.TeleportEvent
		teleportEvent:FireServer("Lobby")
		sendWebhook(`> *{Player.Name}* is returning to lobby.`)
	elseif currentPlace == Timechamber then
		sendWebhook(`> *{Player.Name}* is returning to lobby from time chamber.`)
		local playerGui = game:GetService("Players").LocalPlayer
			:WaitForChild("PlayerGui")
			:WaitForChild("Main")
			:WaitForChild("Create")
			:WaitForChild("Button")
		getconnections(playerGui.Activated)[1]:Fire()
	end
end

local function validateInfo(typeFarm)
	if typeFarm == escanorFarm then
		if Player:GetAttribute("Level") >= level then
			escanorFarm["Level11"] = true
		end
		if currentPlace.hasEscanor() then
			escanorFarm["Escanor"] = true
		end
		if currentPlace == Lobby then
			if currentPlace.checkRRShop("SummerShop") == 0 then
				escanorFarm["rerolls"] = true
			end
		else
			print("current in game, cant check rerolls shop")
		end
	end
	-- check type farm for broly
	for i, v in pairs(typeFarm) do
		print(i, " ", v)
	end
	return print("ValidateInfo Checked")
end

local function writeFile()
	-- template func just for messing around
end

local function finishAccount(typeFarm)
	local changeAccTxt = `{Player.Name}.txt`
	currentFarmStage = "DONE"

	if typeFarm == escanorFarm then
		completedWebhook("User: " .. Player.Name .. "\nCompleted Escanor Farm")
		writefile(changeAccTxt, "Completed Escanor")
		-- update spreadsheet or any other source of getting data
		Player:Kick("COMPLETED ESCANOR FARM")
	elseif typeFarm == brolyFarm then
		completedWebhook("User: " .. Player.Name .. "\nCompleted Broly Farm")
		writefile(changeAccTxt, "Completed Broly")
		-- update spreadsheet or any other source of getting data
		Player:Kick("COMPLETED BROLY FARM")
	end
end

-- main anime vanguards kaitun code
print("current game id: ", game.GameId)
if game.GameId == vanguardsGameId then
	print("Loading Kaitun For Anime Vanguards")

	local Place

	if game.PlaceId == lobbyPlaceId then
		Place = Lobby
		print("In Lobby")
	elseif game.PlaceId == timeChamberPlaceId then
		Place = Timechamber
		print("In timeChamber, Going Lobby.")
		sendWebhook("> *" .. Player.Name .. "* entered Timechamber, going back to Lobby.", true)
		teleportToLobby(Place)
	else
		Place = Game
		print("In Game")
		Place = Game
	end

	currentPlace = Place


	if currentPlace ~= Timechamber then
		if loadKaitun == true then
			if currentPlace == Lobby then
				currentPlace.claimNewPlayerRewards()
			end
			print("Loading Kaitun")
			if not currentFarm then
				if not brolyFarmUsers[Player.Name] then
					currentFarm = escanorFarm
					currentFarm.Name = "Escanor"
				else
					currentFarm = brolyFarm
					currentFarm.Name = "Broly"
				end
			end

			-- escanor farm
			if currentFarm == escanorFarm then
				validateInfo(escanorFarm)

				-- load cfg according to farm Stage
				if not escanorFarm["Level11"] then
					currentFarmStage = escanorFarmStage["Level11"]
					loadNousigi(CFG["namak"])
				elseif not escanorFarm["Escanor"] then
					currentFarmStage = escanorFarmStage["Escanor"]

					-- check max Unit slots
					if Place == Lobby then
						Place.CheckIfExpandUnits()
					end

					loadNousigi(CFG["preEscanor"])
				elseif not escanorFarm["rerolls"] then
					currentFarmStage = escanorFarmStage["rerolls"]

					if Place == Game then
						loadNousigi(CFG["postEscanor"])
					elseif Place == Lobby then
						Place.BuyRR("SummerShop")
						task.wait(10)

						if Place.checkRRShop("SummerShop") == 0 then
							escanorFarm["rerolls"] = true
							finishAccount(currentFarm)
						end

						loadNousigi(CFG["postEscanor"])
					end
				else
					print("Account Done")
					finishAccount(currentFarm)
				end
				if currentFarmStage ~= "DONE" then
					if Place == Game then
						sendWebhook(
							"> *"
								.. Player.Name
								.. "* is farming: "
								.. currentFarm.Name
								.. " at stage: "
								.. currentFarmStage
								.. " IN GAME",
							false
						)
					-- check for level/icedtea quantity max
					elseif Place == Lobby then
						sendWebhook(
							"> *"
								.. Player.Name
								.. "* is farming: "
								.. currentFarm.Name
								.. " at stage: "
								.. currentFarmStage
								.. " IN LOBBY",
							false
						)
					end
				else
					sendWebhook("last webhook message this channel. " .. Player.Name .. " has done all kaitun steps")
				end

				if Place == Game then
					local attributeListener = Player.AttributeChanged:Connect(function(attribute)
						if currentFarmStage == "rerolls" then
							attributesMax.IcedTea = 300000
						end

						for key, maxAttributeValue in pairs(attributesMax) do
							if attribute == key then
								if Player:GetAttribute(attribute) >= maxAttributeValue then
									sendWebhook(
										`> *{Player.Name}* has reached max {attribute} ({maxAttributeValue}) and is teleporting to lobby.`,
										true
									)
									task.wait(10)
									teleportToLobby(Place)
									-- i need to change this if, its doesnt feels right
								end
							end
						end
					end)
				end
				--- broly farm
			end
		end
	end
end

print("its working!")
