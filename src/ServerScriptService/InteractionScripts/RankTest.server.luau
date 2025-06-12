--!strict
-- Rank Test Script


---------- Service ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")


---------- Imports ----------

local LeaderstatsModule = require(ServerStorage.LeaderstatsModule)


---------- Instances ----------

local RankTestFolder: Folder = workspace._Workspace.RankTest
local RankTestInteraction: Folder = RankTestFolder.Interaction
local RankTestInteractivePart: Part = RankTestInteraction.InteractivePart
local RankTestProximityPrompt: ProximityPrompt = RankTestInteractivePart.ProximityPrompt
local PoofAudioPlayer: AudioPlayer = RankTestInteractivePart.PoofAudioPlayer
local PulsingAudioPlayer: AudioPlayer = RankTestInteractivePart.PulsingAudioPlayer

local RankEvents = ServerStorage.RankEvents
local RankBindableFunction = RankEvents.RankBindableFunction

local CameraEvents = ReplicatedStorage.CameraEvents
local CameraRemote = CameraEvents.CameraRemote

local MenuEvents = ReplicatedStorage.MenuEvents
local MenuRemote = MenuEvents.MenuRemote

local ParticleEvents = ReplicatedStorage.ParticleEvents
local ParticleRemote = ParticleEvents.ParticleRemote


---------- Variables ----------

local interactThrottle = false

local rng = Random.new()


---------- Local functions ----------

local function displayRank(player: Player)
	-- Get rank
	local rank = "no data"
	task.defer(function()
		rank = RankBindableFunction:Invoke("TestAndGetPlayerRank", player)
	end)

	---------- Wait for rank ----------

	local transitionTime = 2
	local startTime = time()
	local initialColor = RankTestInteractivePart.Color

	-- Start change
	CameraRemote:FireClient(player, "SetFieldOfView", 120, transitionTime + 1)
	for _, object in RankTestInteraction:GetChildren() do
		if object:IsA("BasePart") then
			object.Color = Color3.new(0.8, 0, 0)
		end
	end

	-- Set leaderstats
	LeaderstatsModule.setData(player, "Rank", "???")

	-- Wait
	while rank == "no data" or time() - startTime < transitionTime do
		RunService.Heartbeat:Wait()
	end

	-- End change
	CameraRemote:FireClient(player, "SetFieldOfView", 70, 0.3)
	for _, object in RankTestInteraction:GetChildren() do
		if object:IsA("BasePart") then
			object.Color = initialColor
		end
	end


	-- Update menu
	MenuRemote:FireClient(player, "UpdateRank", rank)

	-- Set leaderstats
	LeaderstatsModule.setData(player, "Rank", rank)

	-- Play audio
	PoofAudioPlayer:Play()

	-- Display rank particles
	ParticleRemote:FireAllClients("ShowTextParticles", rank, 32, RankTestInteractivePart)
	ParticleRemote:FireAllClients("ShowTextParticles", rank, 1, RankTestInteraction.ParticleParts)
end


---------- Event functions ----------

local function onProximityPromptTriggered(player: Player)
	if interactThrottle then
		return
	end
	interactThrottle = true

	-- Disable interaction
	RankTestProximityPrompt.Enabled = false

	-- Display rank
	displayRank(player)

	-- Wait
	task.wait(3)

	-- Enable interaction
	RankTestProximityPrompt.Enabled = true

	interactThrottle = false
end


---------- Calling / connecting functions ----------

RankTestProximityPrompt.Triggered:Connect(onProximityPromptTriggered)
PulsingAudioPlayer:Play()
